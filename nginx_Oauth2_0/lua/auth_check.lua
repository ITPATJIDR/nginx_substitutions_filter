-- Authentication check middleware with body transformation
local oauth2 = require "oauth2"
local cjson = require "cjson"

-- Get token from Authorization header or cookie
local token = oauth2.get_access_token() or oauth2.get_token_from_cookie()

if not token then
    ngx.status = 401
    ngx.header["Content-Type"] = "application/json"
    ngx.say('{"error": "Unauthorized", "message": "No access token provided"}')
    ngx.exit(401)
end

-- Validate token
local is_valid, user_info = oauth2.validate_token(token)

if not is_valid then
    ngx.status = 401
    ngx.header["Content-Type"] = "application/json"
    ngx.say('{"error": "Unauthorized", "message": "Invalid or expired token"}')
    ngx.exit(401)
end

-- Add user info to request headers
ngx.req.set_header("X-User-ID", user_info.sub or "")
ngx.req.set_header("X-User-Email", user_info.email or "")
ngx.req.set_header("X-User-Name", user_info.preferred_username or user_info.name or "")

-- Body transformation (username -> name)
if ngx.var.content_type and ngx.var.content_type:find("application/json") then
    local body = ngx.req.get_body_data()
    
    if body then
        local ok, data = pcall(cjson.decode, body)
        if ok and data then
            -- Transform username to name if present
            if data.username and not data.name then
                data.name = data.username
                data.username = nil
            end
            
            -- Add user context if available
            local user_id = user_info.sub or ""
            local user_email = user_info.email or ""
            
            if user_id ~= "" then
                data.user_id = user_id
            end
            if user_email ~= "" then
                data.user_email = user_email
            end
            
            -- Re-encode the body
            local new_body = cjson.encode(data)
            ngx.req.set_body_data(new_body)
        end
    end
end
