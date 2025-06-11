package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"image/color"
	"io/ioutil"
	"net/http"
	"sync"
	"time"

	"gonum.org/v1/plot"
	"gonum.org/v1/plot/plotter"
	"gonum.org/v1/plot/vg"
)

const cacheExpiration = 5 * time.Minute

// Cache is a simple cache implementation
type Cache struct {
	data map[string]interface{}
	mu   sync.RWMutex
}

// NewCache returns a new cache instance
func NewCache() *Cache {
	return &Cache{
		data: make(map[string]interface{}),
	}
}

// Get returns the value for the given key if it exists
func (c *Cache) Get(key string) (interface{}, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	value, found := c.data[key]
	return value, found
}

// Set sets the value for the given key
func (c *Cache) Set(key string, value interface{}, expiration time.Duration) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.data[key] = value
	time.AfterFunc(expiration, func() {
		c.mu.Lock()
		defer c.mu.Unlock()
		delete(c.data, key)
	})
}

var priceCache = NewCache()

// FetchAndRenderChart fetches market data and returns a PNG chart bytes
func FetchAndRenderChart(symbol string) ([]byte, error) {
	prices, err := fetchPrices(symbol)
	if err != nil {
		return nil, err
	}
	if len(prices) == 0 {
		return nil, errors.New("no data")
	}

	p := plot.New()
	p.Title.Text = fmt.Sprintf("%s Price", symbol)
	p.X.Label.Text = "Time"
	p.Y.Label.Text = "USD"

	pts := make(plotter.XYs, len(prices))
	for i, pt := range prices {
		pts[i].X = float64(i)
		pts[i].Y = pt
	}
	line, err := plotter.NewLine(pts)
	if err != nil {
		return nil, err
	}
	line.Color = color.RGBA{R: 0, G: 128, B: 255, A: 255}
	p.Add(line)

	buf := bytes.NewBuffer(nil)
	if err := p.Save(6*vg.Inch, 3*vg.Inch, buf); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

// fetchPrices fetches last 24h data from CoinGecko
func fetchPrices(symbol string) ([]float64, error) {
	// Check cache first
	cacheKey := symbol + "_1d"
	if cachedData, found := priceCache.Get(cacheKey); found {
		return cachedData.([]float64), nil
	}

	// If not in cache, fetch from API
	prices, err := fetchPricesWithTimeframe(symbol, "1")
	if err != nil {
		return nil, err
	}
	
	// Cache the result
	priceCache.Set(cacheKey, prices, cacheExpiration)
	
	return prices, nil
}

// fetchPricesWithTimeframe fetches price data from CoinGecko with specified timeframe
func fetchPricesWithTimeframe(symbol string, days string) ([]float64, error) {
	// Check cache first
	cacheKey := fmt.Sprintf("%s_%sd", symbol, days)
	if cachedData, found := priceCache.Get(cacheKey); found {
		return cachedData.([]float64), nil
	}
	
	url := fmt.Sprintf("https://api.coingecko.com/api/v3/coins/%s/market_chart?vs_currency=usd&days=%s", symbol, days)
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("bad status: %s", resp.Status)
	}
	
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	
	var result struct {
		Prices [][]float64 `json:"prices"`
	}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}
	
	prices := make([]float64, len(result.Prices))
	for i, pair := range result.Prices {
		prices[i] = pair[1]
	}
	
	// Cache the result
	priceCache.Set(cacheKey, prices, cacheExpiration)
	
	return prices, nil
}

// CoinStats represents market statistics for a cryptocurrency
type CoinStats struct {
	MarketCap          float64 `json:"market_cap"`
	Volume24h          float64 `json:"volume_24h"`
	CirculatingSupply  float64 `json:"circulating_supply"`
	TotalSupply        float64 `json:"total_supply"`
	AllTimeHigh        float64 `json:"ath"`
	AllTimeHighDate    string  `json:"ath_date"`
	PriceChangePercent struct {
		Day     float64 `json:"day"`
		Week    float64 `json:"week"`
		Month   float64 `json:"month"`
		Year    float64 `json:"year"`
	} `json:"price_change_percent"`
}

// fetchCoinStats gets market statistics for a coin
func fetchCoinStats(symbol string) (*CoinStats, error) {
	// Check cache first
	cacheKey := symbol + "_stats"
	if cachedData, found := priceCache.Get(cacheKey); found {
		return cachedData.(*CoinStats), nil
	}
	
	url := fmt.Sprintf("https://api.coingecko.com/api/v3/coins/%s?localization=false&tickers=false&market_data=true&community_data=false&developer_data=false", symbol)
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("bad status: %s", resp.Status)
	}
	
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	
	// Parse the response
	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, err
	}
	
	// Extract the required data
	marketData, ok := result["market_data"].(map[string]interface{})
	if !ok {
		return nil, errors.New("missing market data")
	}
	
	stats := &CoinStats{}
	
	// Get market cap
	if marketCap, ok := marketData["market_cap"].(map[string]interface{}); ok {
		if marketCapUsd, ok := marketCap["usd"].(float64); ok {
			stats.MarketCap = marketCapUsd
		}
	}
	
	// Get 24h volume
	if volumeData, ok := marketData["total_volume"].(map[string]interface{}); ok {
		if volumeUsd, ok := volumeData["usd"].(float64); ok {
			stats.Volume24h = volumeUsd
		}
	}
	
	// Get circulating supply
	if circulatingSupply, ok := marketData["circulating_supply"].(float64); ok {
		stats.CirculatingSupply = circulatingSupply
	}
	
	// Get total supply
	if totalSupply, ok := marketData["total_supply"].(float64); ok {
		stats.TotalSupply = totalSupply
	}
	
	// Get ATH
	if ath, ok := marketData["ath"].(map[string]interface{}); ok {
		if athUsd, ok := ath["usd"].(float64); ok {
			stats.AllTimeHigh = athUsd
		}
	}
	
	// Get ATH date
	if athDate, ok := marketData["ath_date"].(map[string]interface{}); ok {
		if athDateUsd, ok := athDate["usd"].(string); ok {
			stats.AllTimeHighDate = athDateUsd
		}
	}
	
	// Get price change percentages
	if priceChange, ok := marketData["price_change_percentage_24h"].(float64); ok {
		stats.PriceChangePercent.Day = priceChange
	}
	
	if priceChange, ok := marketData["price_change_percentage_7d"].(float64); ok {
		stats.PriceChangePercent.Week = priceChange
	}
	
	if priceChange, ok := marketData["price_change_percentage_30d"].(float64); ok {
		stats.PriceChangePercent.Month = priceChange
	}
	
	if priceChange, ok := marketData["price_change_percentage_1y"].(float64); ok {
		stats.PriceChangePercent.Year = priceChange
	}
	
	// Cache the result
	priceCache.Set(cacheKey, stats, cacheExpiration)
	
	return stats, nil
}
