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

-- Define key mappings: ["old_key"] = "new_key" (reverse of request mapping)
local key_map = {
    name = "username",
    email = "email_address",
    phone = "phone_number",
    id = "user_id",
    firstName = "first_name",
    lastName = "last_name",
    dob = "date_of_birth",
    zipCode = "postal_code"
    -- Add more mappings here as needed
}

-- Transform all keys
for old_key, new_key in pairs(key_map) do
    if data[old_key] ~= nil then
        data[new_key] = data[old_key]
        data[old_key] = nil
    end
end

-- Also transform any nested objects (optional)
if data.message and type(data.message) == "string" then
    for old_key, new_key in pairs(key_map) do
        data.message = string.gsub(data.message, old_key, new_key)
    end
end

-- Convert back to JSON
local new_body = cjson.encode(data)
ngx.arg[1] = new_body

ngx.log(ngx.INFO, "Response body transformed with key mappings")
