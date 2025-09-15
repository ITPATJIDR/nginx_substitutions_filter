-- OAuth callback handler
local oauth2 = require "oauth2"

local args = ngx.req.get_uri_args()
local code = args.code
local state = args.state
local error = args.error

-- Handle OAuth error
if error then
    ngx.status = 400
    ngx.header["Content-Type"] = "application/json"
    ngx.say('{"error": "OAuth Error", "message": "' .. (error or "Unknown error") .. '"}')
    ngx.exit(400)
end

-- Validate required parameters
if not code then
    ngx.status = 400
    ngx.header["Content-Type"] = "application/json"
    ngx.say('{"error": "Missing authorization code"}')
    ngx.exit(400)
end

-- Decode state to get redirect URI
local redirect_uri = "/"
if state then
    local decoded_state = ngx.decode_base64(state)
    if decoded_state then
        local timestamp, uri = decoded_state:match("([^:]+):(.+)")
        if uri then
            redirect_uri = uri
        end
    end
end

-- Exchange code for tokens
local redirect_uri_full = ngx.var.scheme .. "://" .. ngx.var.host .. "/callback"
local success, tokens = oauth2.exchange_code_for_tokens(code, redirect_uri_full)

if not success or not tokens then
    ngx.status = 500
    ngx.header["Content-Type"] = "application/json"
    ngx.say('{"error": "Failed to exchange authorization code for tokens"}')
    ngx.exit(500)
end

-- Set cookies with tokens
local access_token = tokens.access_token
local refresh_token = tokens.refresh_token

if access_token then
    ngx.header["Set-Cookie"] = "access_token=" .. access_token .. "; Path=/; HttpOnly; SameSite=Lax"
end

if refresh_token then
    ngx.header["Set-Cookie"] = "refresh_token=" .. refresh_token .. "; Path=/; HttpOnly; SameSite=Lax"
end

-- Redirect to original destination
ngx.redirect(redirect_uri)
