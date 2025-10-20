-- intercept_request.lua
-- This script runs before proxying to check backend availability

local http = require "resty.http"

-- Get backend URL from environment or use default
local backend_url = os.getenv("BACKEND_URL") or "http://api:3000"
local kafka_broker = os.getenv("KAFKA_BROKER") or "kafka:9092"

-- Store in nginx variables for use in other phases
ngx.var.backend_url = backend_url
ngx.var.kafka_broker = kafka_broker

-- Log the incoming request
ngx.log(ngx.INFO, "Incoming request: ", ngx.var.request_method, " ", ngx.var.request_uri)

-- Check if backend is reachable (optional pre-check)
-- The main error handling happens in the error_page directive

