-- Lua script for transforming request and response bodies
local cjson = require "cjson"

-- Transform request body (username -> name)
function transform_request_body()
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
end

-- Transform response body (name -> username)
function transform_response_body()
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
end

-- Main execution
if ngx.var.request_method == "POST" or ngx.var.request_method == "PUT" or ngx.var.request_method == "PATCH" then
    transform_request_body()
else
    transform_response_body()
end
