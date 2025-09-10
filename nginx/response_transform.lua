local cjson = require "cjson"

-- Get response body
local body = ngx.arg[1]
local eof = ngx.arg[2]

-- Skip if no body content
if not body then
    return
end

-- Only process complete responses (when eof is true)
if not eof then
    return
end

-- Log that we're processing the response
ngx.log(ngx.INFO, "Processing response transformation, eof: " .. tostring(eof))
ngx.log(ngx.INFO, "Response body length: " .. string.len(body))

-- Check if body is empty or just whitespace
if string.len(body) == 0 or string.match(body, "^%s*$") then
    ngx.log(ngx.INFO, "Empty response body, skipping transformation")
    return
end

-- Decode JSON
local success, data = pcall(cjson.decode, body)
if not success then
    ngx.log(ngx.ERR, "Error parsing JSON: " .. tostring(data))
    ngx.log(ngx.ERR, "Response body was: " .. body)
    return
end

-- Debug: log the original response
ngx.log(ngx.INFO, "Original response: " .. cjson.encode(data))

-- Define mappings: ["old_key"] = "new_key"
-- Here we're reversing the request mapping (name → username, etc.)
local key_map = {
    name = "username",
    email = "email_address",
    phone = "phone_num",
    id = "user_id"
    -- add more mappings here
}

-- Transform top-level keys
for old_key, new_key in pairs(key_map) do
    if data[old_key] ~= nil then
        data[new_key] = data[old_key]
        data[old_key] = nil
    end
end

-- (Optional) Deep transform inside nested tables
local function transform_nested(tbl)
    if type(tbl) ~= "table" then return end
    for k, v in pairs(tbl) do
        -- If key matches, rename it
        if key_map[k] then
            tbl[key_map[k]] = v
            tbl[k] = nil
        end
        -- Recurse into nested tables
        if type(v) == "table" then
            transform_nested(v)
        end
    end
end

transform_nested(data)

-- Convert back to JSON
local new_body = cjson.encode(data)

-- Replace the response body
ngx.arg[1] = new_body

-- Debug: log the transformed response
ngx.log(ngx.INFO, "Transformed response: " .. new_body)
ngx.log(ngx.INFO, "Response body transformed with key mappings")
