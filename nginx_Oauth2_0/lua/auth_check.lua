-- Authentication check middleware
local oauth2 = require "oauth2"

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

-- Set user information as nginx variables for use in proxy headers
ngx.var.user_id = user_info.sub or ""
ngx.var.user_email = user_info.email or ""
ngx.var.user_name = user_info.preferred_username or user_info.name or ""

-- Add user info to request headers
ngx.req.set_header("X-User-ID", user_info.sub or "")
ngx.req.set_header("X-User-Email", user_info.email or "")
ngx.req.set_header("X-User-Name", user_info.preferred_username or user_info.name or "")
