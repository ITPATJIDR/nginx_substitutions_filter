-- handle_error.lua
-- This script handles backend errors and produces failed requests to Kafka

local cjson = require "cjson"
local producer = require "resty.kafka.producer"

-- Get configuration
local kafka_broker = os.getenv("KAFKA_BROKER") or "kafka:9092"
local backend_url = os.getenv("BACKEND_URL") or "http://api:3000"

-- Parse broker address
local broker_host, broker_port = kafka_broker:match("([^:]+):(%d+)")
if not broker_port then
    broker_host = kafka_broker
    broker_port = "9092"
end

ngx.log(ngx.INFO, "Backend is unavailable, intercepting request")
ngx.log(ngx.INFO, "Kafka broker: ", broker_host, ":", broker_port)

-- Read request body if present
ngx.req.read_body()
local request_body = ngx.req.get_body_data() or ""

-- Get request headers
local headers = ngx.req.get_headers()
local headers_table = {}
for k, v in pairs(headers) do
    if type(v) == "table" then
        headers_table[k] = table.concat(v, ", ")
    else
        headers_table[k] = v
    end
end

-- Construct the failed request data
local failed_request = {
    timestamp = ngx.now(),
    method = ngx.var.request_method,
    uri = ngx.var.request_uri,
    path = ngx.var.uri,
    query_string = ngx.var.query_string or "",
    headers = headers_table,
    body = request_body,
    remote_addr = ngx.var.remote_addr,
    backend_url = backend_url,
    error_reason = "Backend unavailable (502/503/504)"
}

-- Convert to JSON
local message_json = cjson.encode(failed_request)

ngx.log(ngx.INFO, "Attempting to send to Kafka: ", message_json)

-- Create Kafka producer
local p = producer:new({{
    host = broker_host,
    port = tonumber(broker_port)
}}, {
    producer_type = "async",
    batch_num = 1,
    max_retry = 3,
    request_timeout = 5000,
})

-- Send to Kafka topic "failed-requests"
local ok, err = p:send("failed-requests", nil, message_json)

if not ok then
    ngx.log(ngx.ERR, "Failed to send message to Kafka: ", err)
else
    ngx.log(ngx.INFO, "Successfully sent failed request to Kafka")
end

-- Return error response to client
ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
ngx.header.content_type = "application/json"
ngx.say(cjson.encode({
    error = "Backend service unavailable",
    message = "Your request has been queued for processing",
    request_id = ngx.var.request_id or "unknown",
    timestamp = ngx.now()
}))
ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)

