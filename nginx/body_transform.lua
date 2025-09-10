local cjson = require "cjson"

-- Get body
local body = ngx.req.get_body_data()
if not body then
    return
end

-- Decode JSON
local success, data = pcall(cjson.decode, body)
if not success then
    ngx.log(ngx.ERR, "Error parsing JSON: " .. tostring(data))
    return
end

-- Define mappings: ["old_key"] = "new_key"
local key_map = {
    username = "name",
    email_address = "email",
    phone_num = "phone",
    user_id = "id"
    -- add more mappings here
}

-- Transform keys
for old_key, new_key in pairs(key_map) do
    if data[old_key] ~= nil then
        data[new_key] = data[old_key]
        data[old_key] = nil
    end
end

-- Encode JSON back
local new_body = cjson.encode(data)
ngx.req.set_body_data(new_body)

ngx.log(ngx.INFO, "Request body transformed with key mappings")
