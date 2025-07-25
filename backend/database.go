package main

import (
	"fmt"
	"log"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// Database wraps the database connection
type Database struct {
	db     *gorm.DB
	config *Config
}

// NewDatabase creates a new database connection
func NewDatabase(config *Config) (*Database, error) {
	// Create DSN (Data Source Name)
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		config.Database.User,
		config.Database.Password,
		config.Database.Host,
		config.Database.Port,
		config.Database.Name)

	if config.IsDebug {
		log.Printf("Database connection details: Host=%s, Port=%s, User=%s, Database=%s",
			config.Database.Host, config.Database.Port, config.Database.User, config.Database.Name)
	}

	// Configure GORM logger based on debug mode
	gormConfig := &gorm.Config{}
	if config.IsDebug {
		gormConfig.Logger = logger.Default.LogMode(logger.Info)
	}

	db, err := gorm.Open(mysql.Open(dsn), gormConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	log.Println("Database connected successfully")
	return &Database{db: db, config: config}, nil
}

// GetIframesByUserUUID retrieves iframe configurations for a specific user
func (d *Database) GetIframesByUserUUID(userUUID string) ([]IframeItem, error) {
	if d.config.IsDebug {
		log.Printf("Retrieving iframes for user UUID: %s", userUUID)
	}

	var relations []UserURLRelation

	// Optimized query: use preload with conditions
	err := d.db.Preload("URL", "status = ?", "active").
		Where("user_uuid = ? AND status = ?", userUUID, "active").
		Order("COALESCE(custom_title, (SELECT title FROM urls WHERE id = url_id)) ASC").
		Find(&relations).Error

	if err != nil {
		log.Printf("Error querying iframes for user %s: %v", userUUID, err)
		return nil, fmt.Errorf("failed to query iframes for user %s: %w", userUUID, err)
	}

	if d.config.IsDebug {
		log.Printf("Found %d iframe relations for user %s", len(relations), userUUID)
	}

	// Convert using method - more functional approach
	iframes := make([]IframeItem, 0, len(relations))
	for i := range relations {
		iframes = append(iframes, relations[i].ToIframeItem())
	}

	return iframes, nil
}
