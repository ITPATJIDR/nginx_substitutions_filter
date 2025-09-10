-- Lua script for transforming request and response bodies
local cjson = require "cjson"

-- Transform request body (username -> name)
function transform_request_body()
    local ngx = ngx
    local req = ngx.req
    
    -- Read request body
    ngx.req.read_body()
    local body = ngx.req.get_body_data()
    
    if body then
        local success, json = pcall(cjson.decode, body)
        if success and json and json.username then
            -- Transform username to name
            json.name = json.username
            json.username = nil
            
            -- Set new body
            ngx.req.set_body_data(cjson.encode(json))
            ngx.log(ngx.INFO, "Transformed request: username -> name")
        end
    end
end

-- Transform response body (name -> username)
function transform_response_body()
    local ngx = ngx
    local res = ngx.arg[1]
    
    if res then
        local success, json = pcall(cjson.decode, res)
        if success and json then
            -- Transform name back to username
            if json.name then
                json.username = json.name
                json.name = nil
            end
            
            -- Transform any text containing 'name' to 'username'
            if json.message and type(json.message) == "string" then
                json.message = string.gsub(json.message, "name", "username")
            end
            
            -- Transform receivedField
            if json.receivedField == "name" then
                json.receivedField = "username"
            end
            
            -- Set new response
            ngx.arg[1] = cjson.encode(json)
            ngx.log(ngx.INFO, "Transformed response: name -> username")
        end
    end
end
