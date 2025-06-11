package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"
)

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

// Default crypto coins to use
var defaultCoins = []string{"bitcoin", "ethereum", "ripple", "solana", "cardano"}

// Main function to start the server
func main() {
	// Register API routes
	http.HandleFunc("/api/chart/", handleChart)
	http.HandleFunc("/api/prices/", handlePrices)
	http.HandleFunc("/api/coins", handleCoins)
	http.HandleFunc("/api/stats/", handleStats)
	
	// Add CORS middleware
	http.ListenAndServe(":8080", corsMiddleware(http.DefaultServeMux))
}

// CORS middleware handler
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Origin, Content-Type")
		
		// Handle preflight requests
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}
		
		next.ServeHTTP(w, r)
	})
}

// Chart API handler
func handleChart(w http.ResponseWriter, r *http.Request) {
	symbol := strings.TrimPrefix(r.URL.Path, "/api/chart/")
	if symbol == "" {
		http.Error(w, "Missing symbol", http.StatusBadRequest)
		return
	}
	
	img, err := FetchAndRenderChart(symbol)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	
	w.Header().Set("Content-Type", "image/png")
	w.Write(img)
}

// Prices API handler
func handlePrices(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/prices/")
	parts := strings.Split(path, "/")
	
	if len(parts) == 0 || parts[0] == "" {
		http.Error(w, "Missing symbol", http.StatusBadRequest)
		return
	}
	
	symbol := parts[0]
	var prices []float64
	var err error
	
	if len(parts) > 1 && parts[1] != "" {
		// Has timeframe specified
		timeframe := parts[1]
		days := convertTimeframeToDays(timeframe)
		prices, err = fetchPricesWithTimeframe(symbol, days)
	} else {
		prices, err = fetchPrices(symbol)
	}
	
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"prices": prices,
	})
}

// Convert timeframe string to days string
func convertTimeframeToDays(timeframe string) string {
	switch timeframe {
	case "1h":
		return "1"
	case "1d":
		return "1"
	case "7d":
		return "7"
	case "30d":
		return "30"
	case "90d":
		return "90"
	case "1y":
		return "365"
	default:
		return "1" // Default to 1 day
	}
}

// Coins API handler
func handleCoins(w http.ResponseWriter, r *http.Request) {
	coinsList := make([]map[string]string, 0, len(defaultCoins))
	
	for _, coinID := range defaultCoins {
		coinInfo := map[string]string{
			"id":     coinID,
			"name":   getCoinName(coinID),
			"symbol": getCoinSymbol(coinID),
		}
		coinsList = append(coinsList, coinInfo)
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"coins": coinsList,
	})
}

// Stats API handler
func handleStats(w http.ResponseWriter, r *http.Request) {
	symbol := strings.TrimPrefix(r.URL.Path, "/api/stats/")
	if symbol == "" {
		http.Error(w, "Missing symbol", http.StatusBadRequest)
		return
	}
	
	stats, err := fetchCoinStats(symbol)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"stats": stats,
	})
}

// Helper function to get coin name
func getCoinName(id string) string {
	names := map[string]string{
		"bitcoin":   "Bitcoin",
		"ethereum":  "Ethereum",
		"ripple":    "XRP",
		"cardano":   "Cardano",
		"solana":    "Solana",
		"dogecoin":  "Dogecoin",
		"polkadot":  "Polkadot",
	}
	
	if name, ok := names[id]; ok {
		return name
	}
	return id
}

// Helper function to get coin symbol
func getCoinSymbol(id string) string {
	symbols := map[string]string{
		"bitcoin":   "BTC",
		"ethereum":  "ETH",
		"ripple":    "XRP",
		"cardano":   "ADA",
		"solana":    "SOL",
		"dogecoin":  "DOGE",
		"polkadot":  "DOT",
	}
	
	if symbol, ok := symbols[id]; ok {
		return symbol
	}
	return id
}

func FetchAndRenderChart(symbol string) ([]byte, error) {
	// Implement FetchAndRenderChart function
	return []byte{}, nil
}

func fetchPrices(symbol string) ([]float64, error) {
	// Implement fetchPrices function
	return []float64{}, nil
}

func fetchPricesWithTimeframe(symbol string, timeframe string) ([]float64, error) {
	// Implement fetchPricesWithTimeframe function
	return []float64{}, nil
}

func fetchCoinStats(symbol string) (interface{}, error) {
	// Implement fetchCoinStats function
	return nil, nil
}
