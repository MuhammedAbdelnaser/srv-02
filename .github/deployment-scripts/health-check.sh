#!/bin/bash

# health-check.sh - Script to verify service health after deployment

SERVICE_NAME="srv-02"
SERVICE_URL="http://localhost:8002"
MAX_ATTEMPTS=30
WAIT_TIME=2

echo "🔍 Checking service health..."

# Check if systemd service is active
check_service_status() {
    if systemctl is-active --quiet $SERVICE_NAME; then
        echo "✅ Systemd service '$SERVICE_NAME' is active"
        return 0
    else
        echo "❌ Systemd service '$SERVICE_NAME' is not active"
        return 1
    fi
}

# Check if service responds to HTTP requests
check_http_response() {
    local attempt=1
    
    while [ $attempt -le $MAX_ATTEMPTS ]; do
        echo "🌐 Attempt $attempt/$MAX_ATTEMPTS: Testing HTTP endpoint..."
        
        if curl -f -s --max-time 10 $SERVICE_URL > /dev/null; then
            echo "✅ HTTP endpoint is responding"
            # Get actual response to verify content
            response=$(curl -s --max-time 10 $SERVICE_URL)
            echo "📝 Sample response: $response"
            return 0
        else
            echo "⏳ Waiting $WAIT_TIME seconds before retry..."
            sleep $WAIT_TIME
            ((attempt++))
        fi
    done
    
    echo "❌ HTTP endpoint failed to respond after $MAX_ATTEMPTS attempts"
    return 1
}

# Check service logs for errors
check_service_logs() {
    echo "📋 Recent service logs:"
    journalctl -u $SERVICE_NAME --no-pager -n 10
}

# Main health check
main() {
    echo "🚀 Starting health check for $SERVICE_NAME..."
    
    if check_service_status; then
        if check_http_response; then
            echo "🎉 Health check passed! Service is healthy."
            exit 0
        else
            echo "⚠️  Service is running but not responding to HTTP requests"
            check_service_logs
            exit 1
        fi
    else
        echo "💥 Service is not running"
        check_service_logs
        exit 1
    fi
}

main "$@"