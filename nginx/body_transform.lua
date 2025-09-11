-- Lua script for transforming request bodies (username -> name)
local cjson = require "cjson"

-- Transform request body (username -> name)
local body = ngx.req.get_body_data()
local headers = ngx.req.get_headers()
if not body then
    return
end

local success, data = pcall(cjson.decode, body)
if not success then
    ngx.log(ngx.ERR, "Error parsing JSON: " .. tostring(data))
    return
end

-- Define key mappings: ["old_key"] = "new_key"
local key_map = {
    username = "name",
    email_address = "email",
    phone_number = "phone",
    user_id = "id",
    first_name = "firstName",
    last_name = "lastName",
    date_of_birth = "dob",
    postal_code = "zipCode"
    -- Add more mappings here as needed
}

-- Transform all keys
for old_key, new_key in pairs(key_map) do
    if data[old_key] ~= nil then
        data[new_key] = data[old_key]
        data[old_key] = nil
    end
end

-- Convert back to JSON and set as new body
local new_body = cjson.encode(data)
ngx.req.clear_header("Authorization")
ngx.req.set_body_data(new_body)

ngx.log(ngx.INFO, "Request body transformed with key mappings")