-- Response body transformation
local cjson = require "cjson"

-- Only process JSON responses
if ngx.header.content_type and ngx.header.content_type:find("application/json") then
    local chunk, eof = ngx.arg[1], ngx.arg[2]
    
    if not eof then
        ngx.arg[1] = chunk
        return
    end
    
    if chunk then
        local ok, data = pcall(cjson.decode, chunk)
        if ok and data then
            -- Transform name back to username if present
            if data.name and not data.username then
                data.username = data.name
                data.name = nil
            end
            
            -- Add authentication status
            data.authenticated = true
            if ngx.var.user_id then
                data.user_id = ngx.var.user_id
            end
            
            -- Re-encode the response
            local new_chunk = cjson.encode(data)
            ngx.arg[1] = new_chunk
        else
            ngx.arg[1] = chunk
        end
    end
end
