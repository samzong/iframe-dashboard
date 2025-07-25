-- Create database (if needed)
CREATE DATABASE IF NOT EXISTS iframe_configs DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Use the database
USE iframe_configs;

-- Create urls table - stores unique URL information
CREATE TABLE IF NOT EXISTS urls (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    url TEXT NOT NULL,
    title VARCHAR(200) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create user_url_relations table - stores user and URL relationships
CREATE TABLE IF NOT EXISTS user_url_relations (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_uuid VARCHAR(36) NOT NULL,
    url_id BIGINT UNSIGNED NOT NULL,
    custom_title VARCHAR(200) NULL,  -- allows users to customize titles, NULL uses the default title from urls table
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (url_id) REFERENCES urls(id),
    UNIQUE KEY (user_uuid, url_id)  -- ensures a user doesn't have duplicate relations to the same URL
);

-- Create indexes for better performance
CREATE INDEX idx_urls_status ON urls(status);
CREATE INDEX idx_urls_title ON urls(title);
CREATE INDEX idx_user_url_relations_user_uuid ON user_url_relations(user_uuid);
CREATE INDEX idx_user_url_relations_status ON user_url_relations(status);
