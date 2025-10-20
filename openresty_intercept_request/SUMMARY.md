# Project Summary: OpenResty Request Interceptor with Kafka

## 🎯 What This Project Does

This project demonstrates a **fault-tolerant reverse proxy** that:
1. Proxies requests from clients to a backend API
2. Intercepts failed requests when the backend is unavailable
3. Queues failed requests to Kafka for later processing
4. Provides a consumer example to retry or process these requests

## 📁 Project Structure

```
openresty_intercept_request/
├── api/                              # Express Backend
│   ├── Dockerfile
│   ├── package.json
│   └── index.js                      # Simple REST API with sample endpoints
│
├── openresty/                        # OpenResty (Nginx + Lua)
│   ├── Dockerfile                    # Includes lua-resty-kafka
│   ├── nginx.conf                    # Main Nginx configuration
│   └── lua/
│       ├── intercept_request.lua     # Pre-processes requests
│       └── handle_error.lua          # Intercepts failures → Kafka
│
├── consumer-example/                 # Kafka Consumer (Optional)
│   ├── package.json
│   ├── consumer.js                   # Processes & retries failed requests
│   └── README.md
│
├── docker-compose.yml                # Complete stack definition
├── Makefile                          # Convenient commands
├── test.sh                           # Test script
│
└── Documentation/
    ├── README.md                     # Main documentation
    ├── QUICKSTART.md                 # Quick start guide
    └── ARCHITECTURE.md               # Detailed architecture
```

## 🚀 Quick Start

### Start Everything
```bash
docker-compose up --build -d
```

### Test Normal Operation
```bash
curl http://localhost:8080/api/health
```

### Simulate Backend Failure
```bash
# Stop backend
docker-compose stop api

# Make request - it will be intercepted
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John","email":"john@example.com"}'
```

### View Messages in Kafka
```bash
docker-compose exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic failed-requests \
  --from-beginning
```

### Restart Backend
```bash
docker-compose start api
```

## 🔧 Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Reverse Proxy** | OpenResty (Nginx + Lua) | Request routing & interception |
| **Backend** | Node.js + Express | Sample API service |
| **Message Queue** | Apache Kafka 7.5 | Store failed requests |
| **Coordination** | Zookeeper | Kafka cluster management |
| **Consumer** | Node.js + KafkaJS | Process failed requests (example) |
| **Lua Library** | lua-resty-kafka | Kafka producer in Lua |

## 📊 Request Flow

### ✅ Successful Request
```
Client → OpenResty:8080 → Backend:3000 → Response → Client
```

### ❌ Failed Request
```
Client → OpenResty:8080 → Backend:3000 (ERROR!)
                              ↓
                      handle_error.lua
                              ↓
                      Capture request data
                              ↓
                      Produce to Kafka
                              ↓
                      Return 503 to Client
```

## 🎛️ Ports

| Service | Internal Port | External Port | Description |
|---------|--------------|---------------|-------------|
| OpenResty | 8080 | 8080 | Main entry point |
| Express API | 3000 | 3000 | Backend service |
| Kafka | 9092 | 29092 | Message broker |
| Zookeeper | 2181 | 2181 | Coordination |

## 📋 Key Features

### ✨ Request Interception
- Automatically detects backend failures (502, 503, 504)
- Captures complete request data (method, URI, headers, body)
- No request data is lost

### 📦 Kafka Integration
- Async message production
- Configurable retry logic
- Topic: `failed-requests`
- JSON message format

### 🔄 Consumer Example
- Automatic retry logic
- Configurable retry behavior
- Detailed logging
- Extensible for custom processing

### 🛠️ Developer Friendly
- Docker Compose for easy setup
- Makefile with common commands
- Comprehensive documentation
- Test scripts included

## 📖 Available Commands (Makefile)

```bash
make up              # Start all services
make down            # Stop all services
make test            # Test normal requests
make stop-api        # Stop API (simulate failure)
make start-api       # Start API
make test-fail       # Test failed request
make consume-kafka   # View Kafka messages
make logs            # Show all logs
make clean           # Remove everything
```

## 🔍 Monitoring & Debugging

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f openresty
docker-compose logs -f api
docker-compose logs -f kafka
```

### Check Service Health
```bash
# OpenResty health
curl http://localhost:8080/health

# API health
curl http://localhost:3000/api/health

# Kafka topics
docker-compose exec kafka kafka-topics \
  --bootstrap-server localhost:9092 --list
```

## 🎓 Use Cases

This architecture pattern is useful for:

1. **Request Buffering**: Queue requests during backend maintenance
2. **Fault Tolerance**: Never lose request data even when backend is down
3. **Async Processing**: Offload heavy processing to background workers
4. **Audit Trail**: Keep record of all failed requests
5. **Retry Logic**: Implement sophisticated retry strategies
6. **Analytics**: Analyze failure patterns and system health
7. **Circuit Breaker**: Protect backend from overload

## 🔐 Production Considerations

### Security
- [ ] Add TLS/SSL encryption
- [ ] Implement authentication (JWT/OAuth)
- [ ] Add rate limiting
- [ ] Mask sensitive data before Kafka
- [ ] Set up Kafka ACLs

### Scalability
- [ ] Scale OpenResty horizontally
- [ ] Add multiple backend instances
- [ ] Increase Kafka partitions
- [ ] Implement connection pooling
- [ ] Add caching layer

### Monitoring
- [ ] Set up Prometheus metrics
- [ ] Create Grafana dashboards
- [ ] Implement distributed tracing
- [ ] Set up alerting (PagerDuty, etc.)
- [ ] Log aggregation (ELK stack)

### Reliability
- [ ] Increase Kafka replication factor
- [ ] Add backup Kafka cluster
- [ ] Implement dead letter queue
- [ ] Set up automated backups
- [ ] Create disaster recovery plan

## 📚 Documentation Files

- **README.md**: Comprehensive project documentation
- **QUICKSTART.md**: Get started in 5 minutes
- **ARCHITECTURE.md**: Deep dive into system design
- **SUMMARY.md**: This file - project overview
- **consumer-example/README.md**: Consumer setup guide

## 🧪 Testing Workflow

1. Start services: `make up`
2. Test normal operation: `make test`
3. Simulate failure: `make stop-api`
4. Send test request: `make test-fail`
5. Check Kafka: `make consume-kafka`
6. Restart API: `make start-api`
7. Stop all: `make down`

## 🤝 Contributing

This is a demonstration project showing best practices for:
- OpenResty + Lua development
- Kafka integration patterns
- Fault-tolerant architectures
- Microservices communication

Feel free to extend it with:
- Database integration
- Authentication systems
- Monitoring solutions
- Additional backends
- Custom business logic

## 📞 Support

For issues or questions:
1. Check the documentation files
2. Review logs: `make logs`
3. Verify services are running: `docker-compose ps`
4. Test individually: isolate the failing component

## 🎉 Success Criteria

You'll know everything is working when:
- ✅ OpenResty responds on port 8080
- ✅ API responds through OpenResty
- ✅ Failed requests appear in Kafka
- ✅ Consumer processes messages successfully
- ✅ API recovery restores normal operation

## 🔗 Related Projects in This Repo

This is part of a larger repository exploring Nginx/OpenResty patterns:
- `nginx_Oauth2_0/` - OAuth integration
- `openresty_keycloak/` - Keycloak authentication
- `openresty_keycloak_auth_proxy/` - Auth proxy pattern

## 📝 License

This is a demonstration/educational project. Use freely for learning and development.

---

**Ready to get started?** → See [QUICKSTART.md](QUICKSTART.md)

**Want details?** → See [README.md](README.md)

**Need architecture info?** → See [ARCHITECTURE.md](ARCHITECTURE.md)

