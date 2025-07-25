# Backend build stage
FROM golang:1.21-alpine AS backend-builder

# Install git (required for Go modules)
RUN apk add --no-cache git

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy backend source code
COPY . ./

# Build the application for Linux AMD64
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o main .

# Final stage
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

# Create non-root user
RUN addgroup -g 1000 appgroup && \
    adduser -D -u 1000 -G appgroup appuser

# Set working directory
WORKDIR /root/

# Copy binary from backend-builder stage
COPY --from=backend-builder /app/main .

# Change ownership to non-root user
RUN chown appuser:appgroup main

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Run the application
CMD ["./main"] 