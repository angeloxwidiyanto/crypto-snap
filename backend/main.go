package main

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

func main() {
	router := gin.Default()
	router.GET("/api/chart/:symbol", ChartHandler)
	router.GET("/api/prices/:symbol", PricesHandler)
	router.Run(":8080")
}

func ChartHandler(c *gin.Context) {
	symbol := c.Param("symbol")
	img, err := FetchAndRenderChart(symbol)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.Header("Content-Type", "image/png")
	c.Writer.Write(img)
}

func PricesHandler(c *gin.Context) {
	symbol := c.Param("symbol")
	prices, err := fetchPrices(symbol)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"prices": prices})
}
