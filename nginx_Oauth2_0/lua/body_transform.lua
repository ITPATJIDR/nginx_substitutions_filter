-- Request body transformation
local cjson = require "cjson"

-- Only process JSON requests
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
            if ngx.var.user_id then
                data.user_id = ngx.var.user_id
            end
            if ngx.var.user_email then
                data.user_email = ngx.var.user_email
            end
            
            -- Re-encode the body
            local new_body = cjson.encode(data)
            ngx.req.set_body_data(new_body)
        end
    end
end
