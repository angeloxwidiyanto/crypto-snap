package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"image/color"
	"io/ioutil"
	"net/http"

	"gonum.org/v1/plot"
	"gonum.org/v1/plot/plotter"
	"gonum.org/v1/plot/vg"
)

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
	url := fmt.Sprintf("https://api.coingecko.com/api/v3/coins/%s/market_chart?vs_currency=usd&days=1", symbol)
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
	return prices, nil
}
