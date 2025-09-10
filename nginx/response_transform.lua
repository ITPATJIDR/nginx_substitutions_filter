-- Lua script for transforming response bodies (name -> username)
local cjson = require "cjson"

-- Transform response body (name -> username)
local body = ngx.arg[1]
local eof = ngx.arg[2]

if not body or eof then
    return
end

local success, data = pcall(cjson.decode, body)
if not success then
    ngx.log(ngx.ERR, "Error parsing JSON: " .. tostring(data))
    return
end

-- Transform name to username
if data.name then
    data.username = data.name
    data.name = nil
end

-- Also transform any nested objects
if data.message and type(data.message) == "string" then
    data.message = string.gsub(data.message, "name", "username")
end

-- Convert back to JSON
local new_body = cjson.encode(data)
ngx.arg[1] = new_body

ngx.log(ngx.INFO, "Response body transformed: name -> username")
