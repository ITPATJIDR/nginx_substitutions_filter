-- Lua script for transforming request bodies (username -> name)
local cjson = require "cjson"

-- Transform request body (username -> name)
local body = ngx.req.get_body_data()
if not body then
    return
end

local success, data = pcall(cjson.decode, body)
if not success then
    ngx.log(ngx.ERR, "Error parsing JSON: " .. tostring(data))
    return
end

-- Transform username to name
if data.username then
    data.name = data.username
    data.username = nil
end

-- Convert back to JSON and set as new body
local new_body = cjson.encode(data)
ngx.req.set_body_data(new_body)

ngx.log(ngx.INFO, "Request body transformed: username -> name")