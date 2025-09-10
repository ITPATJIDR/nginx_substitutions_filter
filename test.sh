# Test POST endpoint (will show substitution in action)
curl -X POST http://localhost:8080/api \
    -H "Content-Type: application/json" \
    -d '{"name":"World"}'

# Expected response: {"message":"Hi, World"}

# Test GET endpoint
curl http://localhost:8080/api

# Expected response: {"message":"Hi from Nginx-Express!","timestamp":"..."}