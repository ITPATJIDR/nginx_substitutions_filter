# Kafka Consumer Example

This is an example Node.js consumer that processes failed requests from Kafka.

## Features

- Consumes messages from the `failed-requests` topic
- Automatically retries failed requests to the backend
- Logs all request details
- Graceful shutdown handling
- Configurable retry behavior

## Installation

```bash
cd consumer-example
npm install
```

## Usage

### Basic usage (with retry enabled)

```bash
npm start
```

### Configuration via environment variables

```bash
# Kafka broker address
export KAFKA_BROKER=localhost:29092

# Backend URL for retries
export BACKEND_URL=http://localhost:3000

# Consumer group ID
export CONSUMER_GROUP=failed-request-processor

# Enable/disable retry (default: true)
export RETRY_ENABLED=true

npm start
```

### Run without retry (just log)

```bash
RETRY_ENABLED=false npm start
```

## Docker Usage

You can also add this consumer to the docker-compose.yml:

```yaml
consumer:
  build:
    context: ./consumer-example
  environment:
    KAFKA_BROKER: kafka:9092
    BACKEND_URL: http://api:3000
    RETRY_ENABLED: "true"
  depends_on:
    - kafka
    - api
```

Then create a Dockerfile in consumer-example/:

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --production
COPY . .
CMD ["npm", "start"]
```

## What it does

1. **Connects to Kafka** - Subscribes to the `failed-requests` topic
2. **Reads messages** - Processes each failed request
3. **Logs details** - Displays request information
4. **Retries requests** - Attempts to send the request to the backend again
5. **Reports results** - Shows success or failure of retry

## Example Output

```
🚀 Starting Kafka Consumer...
📡 Kafka Broker: localhost:29092
🎯 Consumer Group: failed-request-processor
🔄 Retry Enabled: true
🌐 Backend URL: http://localhost:3000
✅ Connected to Kafka
✅ Subscribed to topic: failed-requests

⏳ Waiting for messages...

================================================================================
📨 Received failed request:
================================================================================
Timestamp: 2024-01-15T10:30:45.678Z
Method: POST
URI: /api/users
Remote Address: 172.18.0.1
Error Reason: Backend unavailable (502/503/504)
Headers: {
  "content-type": "application/json",
  "host": "localhost:8080"
}
Body: {"name":"John Doe","email":"john@example.com"}
================================================================================
🔄 Retrying request: POST http://localhost:3000/api/users
✅ Retry successful: POST /api/users - Status: 201
✨ Request successfully processed after retry
```

## Extending the Consumer

You can extend this consumer to:

1. **Store in database**: Save failed requests to MongoDB/PostgreSQL
2. **Send notifications**: Alert via email/Slack when requests fail
3. **Implement backoff**: Add exponential backoff for retries
4. **Dead letter queue**: Move permanently failed requests to another topic
5. **Metrics**: Track success/failure rates with Prometheus
6. **Batching**: Process multiple requests in batches

## Testing

1. Start the main stack:
   ```bash
   cd ..
   docker-compose up -d
   ```

2. Stop the API to generate failed requests:
   ```bash
   docker-compose stop api
   ```

3. Make some requests:
   ```bash
   curl -X POST http://localhost:8080/api/users \
     -H "Content-Type: application/json" \
     -d '{"name":"Test User","email":"test@example.com"}'
   ```

4. Start the consumer:
   ```bash
   cd consumer-example
   npm start
   ```

5. Restart the API:
   ```bash
   cd ..
   docker-compose start api
   ```

6. Watch the consumer retry the failed requests successfully!

