package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"
)

// Default crypto coins to use
var defaultCoins = []string{"bitcoin", "ethereum", "ripple", "cardano", "solana"}

func main() {
	// Create a new HTTP server mux
	mux := http.NewServeMux()
	
	// Register handlers with CORS middleware
	mux.HandleFunc("/api/chart/", corsMiddleware(handleChart))
	mux.HandleFunc("/api/prices/", corsMiddleware(handlePrices))
	mux.HandleFunc("/api/coins", corsMiddleware(handleCoins))
	mux.HandleFunc("/api/stats/", corsMiddleware(handleStats))
	
	// Start the server
	fmt.Println("Server starting on :8080")
	http.ListenAndServe(":8080", mux)
}

// CORS middleware handler
func corsMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Set CORS headers
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		
		// Handle preflight requests
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}
		
		// Call the next handler
		next(w, r)
	}
}

// Chart API handler
func handleChart(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	
	// Extract symbol from path
	pathParts := strings.Split(r.URL.Path, "/")
	if len(pathParts) < 4 {
		http.Error(w, "Invalid path", http.StatusBadRequest)
		return
	}
	symbol := pathParts[3]
	
	// Fetch and render chart
	chartBytes, err := FetchAndRenderChart(symbol)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error: %v", err), http.StatusInternalServerError)
		return
	}
	
	// Set content type and return chart image
	w.Header().Set("Content-Type", "image/png")
	w.Write(chartBytes)
}

// Prices API handler
func handlePrices(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	
	// Extract symbol and optional timeframe from path
	pathParts := strings.Split(r.URL.Path, "/")
	if len(pathParts) < 4 {
		http.Error(w, "Invalid path", http.StatusBadRequest)
		return
	}
	
	symbol := pathParts[3]
	
	var prices []float64
	var err error
	
	// Check if timeframe is provided
	if len(pathParts) >= 5 && pathParts[4] != "" {
		timeframe := pathParts[4]
		days := convertTimeframeToDays(timeframe)
		prices, err = fetchPricesWithTimeframe(symbol, days)
	} else {
		prices, err = fetchPrices(symbol)
	}
	
	if err != nil {
		http.Error(w, fmt.Sprintf("Error: %v", err), http.StatusInternalServerError)
		return
	}
	
	// Return prices as JSON
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"symbol": symbol,
		"prices": prices,
	})
}

// Convert timeframe string to days string
func convertTimeframeToDays(timeframe string) string {
	switch timeframe {
	case "1h":
		return "0.04" // ~1 hour in days
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
		return "1" // default to 1 day
	}
}

// Coins API handler
func handleCoins(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	
	coinsList := make([]map[string]string, len(defaultCoins))
	for i, coinId := range defaultCoins {
		coinsList[i] = map[string]string{
			"id": coinId,
			"name": getCoinName(coinId),
			"symbol": getCoinSymbol(coinId),
		}
	}
	
	// Return coins as JSON
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"coins": coinsList,
	})
}

// Stats API handler
func handleStats(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	
	// Extract symbol from path
	pathParts := strings.Split(r.URL.Path, "/")
	if len(pathParts) < 4 {
		http.Error(w, "Invalid path", http.StatusBadRequest)
		return
	}
	symbol := pathParts[3]
	
	// Fetch stats
	stats, err := fetchCoinStats(symbol)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error: %v", err), http.StatusInternalServerError)
		return
	}
	
	// Return stats as JSON
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"symbol": symbol,
		"stats": stats,
	})
}

// Helper function to get coin name
func getCoinName(id string) string {
	names := map[string]string{
		"bitcoin": "Bitcoin",
		"ethereum": "Ethereum",
		"ripple": "XRP",
		"cardano": "Cardano",
		"solana": "Solana",
		"dogecoin": "Dogecoin",
		"polkadot": "Polkadot",
	}
	
	if name, ok := names[id]; ok {
		return name
	}
	return id
}

// Helper function to get coin symbol
func getCoinSymbol(id string) string {
	symbols := map[string]string{
		"bitcoin": "BTC",
		"ethereum": "ETH",
		"ripple": "XRP",
		"cardano": "ADA",
		"solana": "SOL",
		"dogecoin": "DOGE",
		"polkadot": "DOT",
	}
	
	if symbol, ok := symbols[id]; ok {
		return symbol
	}
	return strings.ToUpper(id)
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
