# Architecture Documentation

## System Overview

This system demonstrates a fault-tolerant reverse proxy architecture using OpenResty (Nginx + Lua) that intercepts failed backend requests and queues them in Kafka for later processing.

## Architecture Diagram

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ HTTP Request
       │
       ▼
┌──────────────────────────────────────────┐
│           OpenResty (Port 8080)          │
│  ┌────────────────────────────────────┐  │
│  │  1. intercept_request.lua          │  │
│  │     - Pre-process request          │  │
│  │     - Log incoming traffic         │  │
│  └────────────────────────────────────┘  │
│                   │                       │
│                   ▼                       │
│  ┌────────────────────────────────────┐  │
│  │  2. Proxy Pass to Backend          │  │
│  │     - proxy_pass http://api:3000   │  │
│  │     - Timeout: 5s                  │  │
│  └────────────────────────────────────┘  │
│                   │                       │
│        ┌──────────┴──────────┐            │
│        │                     │            │
│        ▼                     ▼            │
│   ┌─────────┐          ┌─────────┐       │
│   │ Success │          │  Error  │       │
│   │ (2xx)   │          │(502-504)│       │
│   └────┬────┘          └────┬────┘       │
│        │                    │            │
│        │             ┌──────▼─────────┐  │
│        │             │ 3. @backend_   │  │
│        │             │    error       │  │
│        │             │                │  │
│        │             │ handle_error.  │  │
│        │             │     lua        │  │
│        │             └──────┬─────────┘  │
└────────┼────────────────────┼────────────┘
         │                    │
         │                    │ Produce Message
         │                    ▼
         │          ┌─────────────────────┐
         │          │   Kafka (Port 9092) │
         │          │  Topic: failed-     │
         │          │  requests           │
         │          └─────────┬───────────┘
         │                    │
         ▼                    ▼
┌────────────────┐   ┌────────────────────┐
│ Client gets    │   │  Kafka Consumer    │
│ Response       │   │  (Optional)        │
└────────────────┘   │                    │
                     │  - Process failed  │
                     │    requests        │
                     │  - Retry logic     │
                     │  - Analytics       │
                     └────────────────────┘
```

## Component Details

### 1. OpenResty (Nginx + Lua)

**Technology**: OpenResty 1.21+ with lua-resty-kafka

**Responsibilities**:
- Reverse proxy to backend services
- Request interception on failure
- Kafka message production
- Error handling

**Configuration Files**:
- `nginx.conf`: Main Nginx configuration
- `lua/intercept_request.lua`: Pre-processes requests
- `lua/handle_error.lua`: Handles failures and produces to Kafka

**Key Features**:
- 5-second connection timeout
- Automatic retry (3 attempts, 30s fail timeout)
- Error page handling (502, 503, 504)
- Shared memory for Kafka queue (10MB)

### 2. Express Backend (API)

**Technology**: Node.js 18 + Express 4

**Responsibilities**:
- Business logic processing
- RESTful API endpoints
- Data operations

**Endpoints**:
- `GET /api/health` - Health check
- `GET /api/users` - List users
- `POST /api/users` - Create user
- `GET /api/data` - Get sample data

### 3. Kafka + Zookeeper

**Technology**: Confluent Platform 7.5.0

**Kafka Configuration**:
- Internal port: 9092 (Docker network)
- External port: 29092 (Host access)
- Auto-create topics: Enabled
- Replication factor: 1

**Zookeeper Configuration**:
- Port: 2181
- Tick time: 2000ms

**Topics**:
- `failed-requests`: Stores intercepted requests

### 4. Kafka Consumer (Example)

**Technology**: Node.js + KafkaJS

**Responsibilities**:
- Consume failed requests from Kafka
- Implement retry logic
- Log and monitor failures
- (Optional) Store in database

## Data Flow

### Normal Request Flow

```
1. Client → OpenResty (8080)
2. OpenResty → Backend (3000)
3. Backend processes request
4. Backend → OpenResty (Success 2xx)
5. OpenResty → Client (Response)
```

### Failed Request Flow

```
1. Client → OpenResty (8080)
2. OpenResty → Backend (3000) [TIMEOUT/ERROR]
3. OpenResty detects error (502/503/504)
4. Nginx triggers @backend_error location
5. handle_error.lua executes:
   a. Captures request details
      - Method, URI, Headers, Body
      - Timestamp, Client IP
      - Error reason
   b. Creates JSON message
   c. Produces to Kafka topic
6. OpenResty → Client (503 Service Unavailable)
7. Message stored in Kafka
8. Consumer reads and processes (retry/log/store)
```

## Message Format

### Kafka Message Structure

```json
{
  "timestamp": 1697812345.678,
  "method": "POST",
  "uri": "/api/users",
  "path": "/api/users",
  "query_string": "filter=active&limit=10",
  "headers": {
    "content-type": "application/json",
    "authorization": "Bearer token",
    "host": "localhost:8080",
    "user-agent": "curl/7.64.1"
  },
  "body": "{\"name\":\"John Doe\",\"email\":\"john@example.com\"}",
  "remote_addr": "172.18.0.1",
  "backend_url": "http://api:3000",
  "error_reason": "Backend unavailable (502/503/504)"
}
```

## Fault Tolerance & Reliability

### Backend Failure Handling

1. **Connection Timeout**: 5 seconds
2. **Max Failures**: 3 attempts
3. **Fail Timeout**: 30 seconds
4. **Error Codes Handled**: 502, 503, 504

### Kafka Reliability

1. **Producer Configuration**:
   - Type: Async
   - Batch size: 1
   - Max retry: 3
   - Request timeout: 5000ms

2. **Consumer Configuration**:
   - Group ID: Configurable
   - From beginning: Yes
   - Auto commit: Yes

### Error Recovery Strategies

1. **Immediate Retry** (OpenResty): 3 attempts within 30s
2. **Queue to Kafka**: Store for later processing
3. **Consumer Retry**: Configurable delay and attempts
4. **Dead Letter Queue**: For permanently failed requests

## Scalability Considerations

### Horizontal Scaling

1. **OpenResty Instances**: 
   - Multiple instances behind load balancer
   - Stateless design
   - Session can use shared storage (Redis)

2. **Backend API Instances**:
   - Scale using Docker replicas
   - Nginx upstream load balancing
   - Health checks enabled

3. **Kafka Cluster**:
   - Add more brokers
   - Increase partition count
   - Increase replication factor

### Configuration for Scale

```yaml
# docker-compose.yml example
api:
  deploy:
    replicas: 3
    
openresty:
  deploy:
    replicas: 2
```

## Security Considerations

### Current Implementation

- Internal Docker network communication
- No external Kafka access (except 29092 for testing)
- Backend not directly exposed

### Recommended Enhancements

1. **Authentication & Authorization**:
   - Add JWT/OAuth validation in Lua
   - API key management
   - Rate limiting

2. **Encryption**:
   - TLS/SSL for client → OpenResty
   - mTLS for internal services
   - Kafka SSL/SASL

3. **Data Protection**:
   - Mask sensitive data before Kafka
   - Encrypt messages in transit
   - Access control for Kafka topics

## Monitoring & Observability

### Metrics to Track

1. **OpenResty Metrics**:
   - Request rate
   - Error rate
   - Response time
   - Upstream health

2. **Kafka Metrics**:
   - Message rate
   - Consumer lag
   - Topic size
   - Partition health

3. **Backend Metrics**:
   - Response time
   - Error rate
   - CPU/Memory usage

### Logging

1. **OpenResty**: 
   - Access logs → stdout
   - Error logs → stderr
   - Lua logs → error_log

2. **Kafka**: 
   - Broker logs
   - Topic metrics

3. **Consumer**: 
   - Processing logs
   - Retry attempts
   - Success/failure rates

### Recommended Tools

- **Prometheus**: Metrics collection
- **Grafana**: Visualization
- **ELK Stack**: Log aggregation
- **Jaeger**: Distributed tracing

## Performance Optimization

### OpenResty Tuning

```nginx
worker_processes auto;
worker_connections 1024;

# Connection pooling
upstream backend {
    server api:3000;
    keepalive 32;
    keepalive_timeout 60s;
}

# Caching
lua_shared_dict cache 100m;

# Buffer sizes
client_body_buffer_size 128k;
proxy_buffer_size 4k;
proxy_buffers 8 4k;
```

### Kafka Tuning

```yaml
# Producer settings
batch_num: 200
batch_size: 16384
linger_ms: 10

# Consumer settings
fetch_min_bytes: 1
fetch_max_wait_ms: 500
max_partition_fetch_bytes: 1048576
```

## Disaster Recovery

### Backup Strategy

1. **Kafka Data**: 
   - Regular topic snapshots
   - Replication to secondary cluster

2. **Configuration**: 
   - Version control (Git)
   - Infrastructure as Code

### Recovery Procedures

1. **Backend Failure**: 
   - Automatic via Kafka queue
   - Manual replay from Kafka

2. **Kafka Failure**: 
   - Restore from backup
   - Replay from persistent storage

3. **Complete System Failure**: 
   - Docker Compose recreate
   - Restore Kafka data
   - Resume processing

## Cost Optimization

### Resource Allocation

```yaml
services:
  openresty:
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

### Kafka Retention

```yaml
KAFKA_LOG_RETENTION_HOURS: 24  # Keep for 1 day
KAFKA_LOG_RETENTION_BYTES: 1073741824  # 1GB per partition
```

## Future Enhancements

1. **Advanced Routing**: 
   - Route based on error type
   - Priority queues

2. **Circuit Breaker**: 
   - Automatic backend disable
   - Gradual recovery

3. **Multi-Backend**: 
   - Fallback backends
   - Geo-routing

4. **Analytics Dashboard**: 
   - Real-time failure tracking
   - Historical analysis

5. **Auto-Scaling**: 
   - Based on queue depth
   - Kubernetes HPA

