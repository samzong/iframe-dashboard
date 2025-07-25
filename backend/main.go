package main

import (
	"fmt"
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// App holds application dependencies
type App struct {
	config   *Config
	database *Database
}

func main() {
	// Load configuration
	config := LoadConfig()
	log.Printf("Starting with log level: %s", config.LogLevel)

	// Initialize database
	database, err := NewDatabase(config)
	if err != nil {
		log.Fatal("Failed to initialize database:", err)
	}

	// Create app with dependencies
	app := &App{
		config:   config,
		database: database,
	}

	// Set Gin mode based on debug flag
	if config.IsDebug {
		gin.SetMode(gin.DebugMode)
		log.Println("Gin running in Debug mode")
	} else {
		gin.SetMode(gin.ReleaseMode)
		log.Println("Gin running in Release mode")
	}

	// Create and configure router
	router := app.setupRouter()

	// Start server
	log.Printf("Server starting on :%s", config.Server.Port)
	if err := router.Run(":" + config.Server.Port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

// authMiddleware extracts JWT token and sets user UUID in context
func (app *App) authMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, NewErrorResponse("Authorization header is required"))
			c.Abort()
			return
		}

		// Extract and validate Bearer token
		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		if tokenString == authHeader {
			c.JSON(http.StatusUnauthorized, NewErrorResponse("Invalid authorization header format"))
			c.Abort()
			return
		}

		userUUID, err := extractUserUUID(tokenString)
		if err != nil {
			c.JSON(http.StatusUnauthorized, NewErrorResponse("Invalid token format"))
			c.Abort()
			return
		}

		c.Set("user_uuid", userUUID)
		c.Next()
	}
}

// extractUserUUID extracts user UUID from JWT token without verification
func extractUserUUID(tokenString string) (string, error) {
	token, _, err := new(jwt.Parser).ParseUnverified(tokenString, jwt.MapClaims{})
	if err != nil {
		return "", fmt.Errorf("failed to parse JWT token: %w", err)
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return "", jwt.ErrInvalidKey
	}

	sub, exists := claims["sub"]
	if !exists {
		return "", jwt.ErrInvalidKey
	}

	userUUID, ok := sub.(string)
	if !ok {
		return "", jwt.ErrInvalidKey
	}

	return userUUID, nil
}

// getIframes handles GET /api/v1/iframes - returns user-specific iframes
func (app *App) getIframes(c *gin.Context) {
	userUUID, exists := c.Get("user_uuid")
	if !exists {
		c.JSON(http.StatusInternalServerError, NewErrorResponse("User UUID not found in context"))
		return
	}

	if app.config.IsDebug {
		log.Printf("Fetching iframes for user UUID: %s", userUUID)
	}

	// nolint:errcheck // error is properly handled in the next line
	iframes, err := app.database.GetIframesByUserUUID(userUUID.(string))
	if err != nil {
		log.Printf("Error fetching iframes for user %s: %v", userUUID, err)
		c.JSON(http.StatusInternalServerError, NewErrorResponse("Failed to fetch iframes"))
		return
	}

	if app.config.IsDebug {
		log.Printf("Successfully fetched %d iframes for user %s", len(iframes), userUUID)
	}

	c.JSON(http.StatusOK, NewSuccessResponse(iframes))
}

// setupRouter creates and configures the Gin router
func (app *App) setupRouter() *gin.Engine {
	router := gin.Default()

	// Add CORS middleware
	router.Use(app.corsMiddleware())

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "iframe-dashboard-backend",
		})
	})

	// API routes
	api := router.Group("/api/v1")
	api.GET("/iframes", app.authMiddleware(), app.getIframes)

	return router
}

// corsMiddleware adds CORS headers for frontend integration
func (app *App) corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")
		c.Header("Access-Control-Allow-Credentials", "true")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}
