-- OAuth 2.0 utility functions
local http = require "resty.http"
local cjson = require "cjson"

local _M = {}

-- Configuration
local KEYCLOAK_URL = os.getenv("KEYCLOAK_URL") or "http://keycloak:8080"
local KEYCLOAK_REALM = os.getenv("KEYCLOAK_REALM") or "master"
local KEYCLOAK_CLIENT_ID = os.getenv("KEYCLOAK_CLIENT_ID") or "nginx-client"
local KEYCLOAK_CLIENT_SECRET = os.getenv("KEYCLOAK_CLIENT_SECRET") or "your-client-secret-here"

-- Get access token from Authorization header
function _M.get_access_token()
    local auth_header = ngx.var.http_authorization
    if not auth_header then
        return nil
    end
    
    local token = auth_header:match("Bearer%s+(.+)")
    return token
end

-- Get access token from cookie
function _M.get_token_from_cookie()
    local cookie = ngx.var.cookie_access_token
    return cookie
end

-- Validate token with Keycloak
function _M.validate_token(token)
    if not token then
        return false, "No token provided"
    end
    
    -- Check cache first
    local cache = ngx.shared.oauth_cache
    local cached = cache:get("token:" .. token)
    if cached then
        return true, cjson.decode(cached)
    end
    
    local httpc = http.new()
    local res, err = httpc:request_uri(KEYCLOAK_URL .. "/realms/" .. KEYCLOAK_REALM .. "/protocol/openid-connect/userinfo", {
        method = "GET",
        headers = {
            ["Authorization"] = "Bearer " .. token,
            ["Content-Type"] = "application/json"
        }
    })
    
    if not res then
        ngx.log(ngx.ERR, "Failed to validate token: ", err)
        return false, "Token validation failed"
    end
    
    if res.status ~= 200 then
        ngx.log(ngx.ERR, "Token validation failed with status: ", res.status)
        return false, "Invalid token"
    end
    
    local user_info = cjson.decode(res.body)
    
    -- Cache the result for 5 minutes
    cache:set("token:" .. token, res.body, 300)
    
    return true, user_info
end

-- Exchange authorization code for tokens
function _M.exchange_code_for_tokens(code, redirect_uri)
    local httpc = http.new()
    local res, err = httpc:request_uri(KEYCLOAK_URL .. "/realms/" .. KEYCLOAK_REALM .. "/protocol/openid-connect/token", {
        method = "POST",
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded"
        },
        body = "grant_type=authorization_code" ..
               "&client_id=" .. KEYCLOAK_CLIENT_ID ..
               "&client_secret=" .. KEYCLOAK_CLIENT_SECRET ..
               "&code=" .. code ..
               "&redirect_uri=" .. redirect_uri
    })
    
    if not res then
        ngx.log(ngx.ERR, "Failed to exchange code for tokens: ", err)
        return false, nil
    end
    
    if res.status ~= 200 then
        ngx.log(ngx.ERR, "Token exchange failed with status: ", res.status, " body: ", res.body)
        return false, nil
    end
    
    local tokens = cjson.decode(res.body)
    return true, tokens
end

return _M
