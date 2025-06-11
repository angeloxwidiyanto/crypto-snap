package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"image/color"
	"io/ioutil"
	"net/http"
	"strings"
	"sync"
	"time"

	"gonum.org/v1/plot"
	"gonum.org/v1/plot/plotter"
	"gonum.org/v1/plot/vg"
)

const cacheExpiration = 5 * time.Minute

// Cache to store API responses
type Cache struct {
	sync.RWMutex
	items map[string]CacheItem
}

type CacheItem struct {
	Value      interface{}
	Expiration time.Time
}

// NewCache creates a new cache instance
func NewCache() *Cache {
	return &Cache{
		items: make(map[string]CacheItem),
	}
}

// Set adds an item to the cache
func (c *Cache) Set(key string, value interface{}, expiration time.Duration) {
	c.Lock()
	defer c.Unlock()
	c.items[key] = CacheItem{
		Value:      value,
		Expiration: time.Now().Add(expiration),
	}
}

// Get retrieves an item from the cache
func (c *Cache) Get(key string) (interface{}, bool) {
	c.RLock()
	defer c.RUnlock()
	item, found := c.items[key]
	if !found {
		return nil, false
	}
	
	if time.Now().After(item.Expiration) {
		delete(c.items, key)
		return nil, false
	}
	
	return item.Value, true
}

// Global cache instance
var priceCache = NewCache()

// FetchAndRenderChart fetches market data and returns a PNG chart bytes
func FetchAndRenderChart(symbol string) ([]byte, error) {
	prices, err := fetchPrices(symbol)
	if err != nil {
		return nil, err
	}
	
	// Create a new plot
	p := plot.New()
	
	p.Title.Text = fmt.Sprintf("%s Price (Last 24h)", strings.ToUpper(symbol))
	p.X.Label.Text = "Time"
	p.Y.Label.Text = "Price (USD)"
	
	// Create points for the line
	pts := make(plotter.XYs, len(prices))
	for i, price := range prices {
		pts[i].X = float64(i)
		pts[i].Y = price
	}
	
	// Add a line plotter
	line, err := plotter.NewLine(pts)
	if err != nil {
		return nil, err
	}
	line.Color = color.RGBA{R: 31, G: 174, B: 233, A: 255}
	line.Width = vg.Points(2)
	
	p.Add(line)
	p.Legend.Add("Price", line)
	
	// Save to a buffer
	var buf bytes.Buffer
	wt, err := p.WriterTo(400, 200, "png")
	if err != nil {
		return nil, err
	}
	_, err = wt.WriteTo(&buf)
	if err != nil {
		return nil, err
	}
	
	return buf.Bytes(), nil
}

// fetchPrices fetches last 24h data from CoinGecko
func fetchPrices(symbol string) ([]float64, error) {
	return fetchPricesWithTimeframe(symbol, "1")
}

// fetchPricesWithTimeframe fetches price data from CoinGecko with specified timeframe
func fetchPricesWithTimeframe(symbol string, days string) ([]float64, error) {
	// Check cache first
	cacheKey := fmt.Sprintf("prices_%s_%s", symbol, days)
	if cached, found := priceCache.Get(cacheKey); found {
		return cached.([]float64), nil
	}
	
	// Normalize symbol for CoinGecko API
	symbol = strings.ToLower(symbol)
	
	// Fetch from CoinGecko
	url := fmt.Sprintf(
		"https://api.coingecko.com/api/v3/coins/%s/market_chart?vs_currency=usd&days=%s",
		symbol, days,
	)
	
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API error: %s", resp.Status)
	}
	
	// Parse response
	var data struct {
		Prices [][]float64 `json:"prices"`
	}
	
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	
	err = json.Unmarshal(body, &data)
	if err != nil {
		return nil, err
	}
	
	if len(data.Prices) == 0 {
		return nil, errors.New("no price data available")
	}
	
	// Extract just the prices (second value in each pair)
	prices := make([]float64, len(data.Prices))
	for i, pair := range data.Prices {
		if len(pair) >= 2 {
			prices[i] = pair[1]
		}
	}
	
	// Cache the result
	priceCache.Set(cacheKey, prices, cacheExpiration)
	
	return prices, nil
}

// CoinStats represents market statistics for a cryptocurrency
type CoinStats struct {
	MarketCap         float64 `json:"market_cap"`
	Volume24h         float64 `json:"volume_24h"`
	CirculatingSupply float64 `json:"circulating_supply"`
	TotalSupply       float64 `json:"total_supply"`
	AllTimeHigh       float64 `json:"ath"`
	AllTimeHighDate   string  `json:"ath_date"`
	PriceChangePercent struct {
		Day   float64 `json:"day"`
		Week  float64 `json:"week"`
		Month float64 `json:"month"`
		Year  float64 `json:"year"`
	} `json:"price_change_percent"`
}

// fetchCoinStats gets market statistics for a coin
func fetchCoinStats(symbol string) (*CoinStats, error) {
	// Check cache first
	cacheKey := fmt.Sprintf("stats_%s", symbol)
	if cached, found := priceCache.Get(cacheKey); found {
		return cached.(*CoinStats), nil
	}
	
	// Normalize symbol for CoinGecko API
	symbol = strings.ToLower(symbol)
	
	// Fetch from CoinGecko
	url := fmt.Sprintf(
		"https://api.coingecko.com/api/v3/coins/%s?localization=false&tickers=false&market_data=true&community_data=false&developer_data=false",
		symbol,
	)
	
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API error: %s", resp.Status)
	}
	
	// Parse response
	var data struct {
		MarketData struct {
			MarketCap struct {
				USD float64 `json:"usd"`
			} `json:"market_cap"`
			TotalVolume struct {
				USD float64 `json:"usd"`
			} `json:"total_volume"`
			CirculatingSupply float64 `json:"circulating_supply"`
			TotalSupply      float64 `json:"total_supply"`
			ATH struct {
				USD float64 `json:"usd"`
			} `json:"ath"`
			ATHDate struct {
				USD string `json:"usd"`
			} `json:"ath_date"`
			PriceChangePercentage24h float64 `json:"price_change_percentage_24h"`
			PriceChangePercentage7d  float64 `json:"price_change_percentage_7d"`
			PriceChangePercentage30d float64 `json:"price_change_percentage_30d"`
			PriceChangePercentage1y  float64 `json:"price_change_percentage_1y"`
		} `json:"market_data"`
	}
	
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	
	err = json.Unmarshal(body, &data)
	if err != nil {
		return nil, err
	}
	
	// Map to our stats structure
	stats := &CoinStats{
		MarketCap:         data.MarketData.MarketCap.USD,
		Volume24h:         data.MarketData.TotalVolume.USD,
		CirculatingSupply: data.MarketData.CirculatingSupply,
		TotalSupply:       data.MarketData.TotalSupply,
		AllTimeHigh:       data.MarketData.ATH.USD,
		AllTimeHighDate:   data.MarketData.ATHDate.USD,
	}
	
	stats.PriceChangePercent.Day = data.MarketData.PriceChangePercentage24h
	stats.PriceChangePercent.Week = data.MarketData.PriceChangePercentage7d
	stats.PriceChangePercent.Month = data.MarketData.PriceChangePercentage30d
	stats.PriceChangePercent.Year = data.MarketData.PriceChangePercentage1y
	
	// Cache the result
	priceCache.Set(cacheKey, stats, cacheExpiration)
	
	return stats, nil
}
