package main

import (
	"os"
	"time"
)

// Config holds all application configuration
type Config struct {
	Database DatabaseConfig
	Server   ServerConfig
	LogLevel string
	IsDebug  bool
}

// DatabaseConfig holds database configuration
type DatabaseConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	Name     string
}

// ServerConfig holds server configuration
type ServerConfig struct {
	Port string
}

// LoadConfig loads configuration from environment variables
func LoadConfig() *Config {
	cfg := &Config{
		Database: DatabaseConfig{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnv("DB_PORT", "3306"),
			User:     getEnv("DB_USER", "root"),
			Password: getEnv("DB_PASSWORD", ""),
			Name:     getEnv("DB_NAME", "iframe_dashboard"),
		},
		Server: ServerConfig{
			Port: getEnv("PORT", "8080"),
		},
		LogLevel: getEnv("LOG_LEVEL", "INFO"),
	}
	cfg.IsDebug = cfg.LogLevel == "DEBUG"
	return cfg
}

// getEnv gets environment variable with fallback
func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

// URL represents a unique URL entry
type URL struct {
	CreatedAt time.Time `json:"-" gorm:"column:created_at"`
	UpdatedAt time.Time `json:"-" gorm:"column:updated_at"`
	URL       string    `json:"url" gorm:"column:url"`
	Title     string    `json:"title" gorm:"column:title"`
	Status    string    `json:"-" gorm:"column:status;default:active"`
	ID        uint64    `json:"id" gorm:"primaryKey;column:id;autoIncrement"`
}

// TableName specifies the table name for GORM
func (URL) TableName() string {
	return "urls"
}

// UserURLRelation represents the relationship between a user and a URL
type UserURLRelation struct {
	URL         URL       `json:"url" gorm:"foreignKey:URLID"`
	CreatedAt   time.Time `json:"-" gorm:"column:created_at"`
	UpdatedAt   time.Time `json:"-" gorm:"column:updated_at"`
	CustomTitle *string   `json:"custom_title" gorm:"column:custom_title"`
	UserUUID    string    `json:"user_uuid" gorm:"column:user_uuid;index"`
	Status      string    `json:"-" gorm:"column:status;default:active"`
	ID          uint64    `json:"id" gorm:"primaryKey;column:id;autoIncrement"`
	URLID       uint64    `json:"url_id" gorm:"column:url_id"`
}

// TableName specifies the table name for GORM
func (UserURLRelation) TableName() string {
	return "user_url_relations"
}

// GetTitle returns the display title, using custom title if available
func (r UserURLRelation) GetTitle() string {
	if r.CustomTitle != nil && *r.CustomTitle != "" {
		return *r.CustomTitle
	}
	return r.URL.Title
}

// ToIframeItem converts UserURLRelation to IframeItem
func (r UserURLRelation) ToIframeItem() IframeItem {
	return IframeItem{
		Title: r.GetTitle(),
		URL:   r.URL.URL,
	}
}

// IframeItem represents the combined data for API responses
type IframeItem struct {
	Title string `json:"title"`
	URL   string `json:"url"`
}

// ApiResponse represents the API response format
type ApiResponse struct {
	Message string       `json:"message,omitempty"`
	Data    []IframeItem `json:"data"`
	Success bool         `json:"success"`
}

// NewSuccessResponse creates a successful API response
func NewSuccessResponse(data []IframeItem) ApiResponse {
	return ApiResponse{
		Success: true,
		Data:    data,
		Message: "Success",
	}
}

// NewErrorResponse creates an error API response
func NewErrorResponse(message string) ApiResponse {
	return ApiResponse{
		Success: false,
		Data:    []IframeItem{},
		Message: message,
	}
}
