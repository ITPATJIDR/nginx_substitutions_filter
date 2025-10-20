-- Error Handler for backend failures
-- This handles requests that couldn't be forwarded to the backend
local cjson = require "cjson.safe"
local producer = require "resty.kafka.producer"

-- Get environment variables
local kafka_brokers = os.getenv("KAFKA_BROKERS") or "kafka:9092"
local kafka_topic = os.getenv("KAFKA_TOPIC") or "failed-requests"

-- Parse broker list
local broker_list = {}
for broker in string.gmatch(kafka_brokers, "[^,]+") do
    local host, port = broker:match("([^:]+):?(%d*)")
    port = port ~= "" and tonumber(port) or 9092
    table.insert(broker_list, {host = host, port = port})
end

-- Collect request details
local request_body = nil
ngx.req.read_body()
local body_data = ngx.req.get_body_data()

if body_data then
    request_body = body_data
else
    -- If body was spooled to temp file
    local body_file = ngx.req.get_body_file()
    if body_file then
        local file = io.open(body_file, "r")
        if file then
            request_body = file:read("*all")
            file:close()
        end
    end
end

-- Prepare error data for Kafka
local error_data = {
    timestamp = ngx.time(),
    iso_timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    error_type = "backend_unavailable",
    client_ip = ngx.var.remote_addr,
    request_method = ngx.var.request_method,
    request_uri = ngx.var.request_uri,
    request_path = ngx.var.uri,
    query_string = ngx.var.query_string,
    request_body = request_body,
    user_agent = ngx.var.http_user_agent,
    referer = ngx.var.http_referer,
    upstream_addr = ngx.var.upstream_addr,
    server_name = ngx.var.server_name,
    server_port = ngx.var.server_port,
    request_headers = ngx.req.get_headers(),
    log_type = "backend_error"
}

-- Encode to JSON
local json_str, encode_err = cjson.encode(error_data)
if not json_str then
    ngx.log(ngx.ERR, "Failed to encode error data to JSON: ", encode_err)
    -- Return error response to client
    ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
    ngx.header.content_type = "application/json"
    ngx.say(cjson.encode({
        error = "Backend service unavailable",
        message = "The backend service is currently unavailable. This error has been logged.",
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }))
    return ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
end

-- Log to nginx error log for debugging
ngx.log(ngx.WARN, "Backend error intercepted: ", json_str)

-- Send to Kafka
local bp = producer:new(broker_list, {
    producer_type = "async",
    request_timeout = 2000,
    max_retry = 3
})

local ok, err = bp:send(kafka_topic, nil, json_str)

if not ok then
    ngx.log(ngx.ERR, "Failed to send error to Kafka: ", err)
end

-- Return error response to client
ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
ngx.header.content_type = "application/json"
ngx.say(cjson.encode({
    error = "Backend service unavailable",
    message = "The backend service is currently unavailable. Please try again later.",
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    request_id = ngx.var.request_id or "unknown"
}))

return ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)

