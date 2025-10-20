-- Kafka Logger for logging requests/responses
local cjson = require "cjson.safe"
local producer = require "resty.kafka.producer"

-- Get environment variables
local kafka_brokers = os.getenv("KAFKA_BROKERS") or "kafka:9092"
local kafka_topic = os.getenv("KAFKA_TOPIC") or "failed-requests"

-- Only log failed requests (4xx, 5xx)
local status = ngx.status
if status < 400 then
    return
end

-- Parse broker list
local broker_list = {}
for broker in string.gmatch(kafka_brokers, "[^,]+") do
    local host, port = broker:match("([^:]+):?(%d*)")
    port = port ~= "" and tonumber(port) or 9092
    table.insert(broker_list, {host = host, port = port})
end

-- Prepare log data
local log_data = {
    timestamp = ngx.time(),
    client_ip = ngx.var.remote_addr,
    request_method = ngx.var.request_method,
    request_uri = ngx.var.request_uri,
    request_path = ngx.var.uri,
    status = status,
    body_bytes_sent = tonumber(ngx.var.body_bytes_sent) or 0,
    request_time = tonumber(ngx.var.request_time) or 0,
    upstream_response_time = ngx.var.upstream_response_time,
    user_agent = ngx.var.http_user_agent,
    referer = ngx.var.http_referer,
    server_name = ngx.var.server_name,
    log_type = "response_log"
}

-- Encode to JSON
local json_str, encode_err = cjson.encode(log_data)
if not json_str then
    ngx.log(ngx.ERR, "Failed to encode log data to JSON: ", encode_err)
    return
end

-- Send to Kafka asynchronously
local bp = producer:new(broker_list, {producer_type = "async"})
local ok, err = bp:send(kafka_topic, nil, json_str)

if not ok then
    ngx.log(ngx.ERR, "Failed to send log to Kafka: ", err)
    return
end

