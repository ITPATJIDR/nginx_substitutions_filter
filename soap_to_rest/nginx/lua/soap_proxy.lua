local xml2lua = require("xml2lua")
local handler = require("xmlhandler.tree")
local cjson = require("cjson")

-- ==================== CONFIGURATION ====================
-- Convention-based routing configuration (can be overridden)
local config = {
    base_path = "/internal_rest_proxy",
    -- Pattern: {prefix} = {http_method, needs_id}
    action_patterns = {
        get = {method = ngx.HTTP_GET, needs_id = true},
        list = {method = ngx.HTTP_GET, needs_id = false},
        create = {method = ngx.HTTP_POST, needs_id = false},
        update = {method = ngx.HTTP_PUT, needs_id = true},
        delete = {method = ngx.HTTP_DELETE, needs_id = true},
    }
}

-- ==================== HELPER FUNCTIONS ====================

-- 1. Parse XML Request
local function parse_xml(xml_body)
    local h = handler:new()
    local parser = xml2lua.parser(h)
    parser:parse(xml_body)
    return h.root
end

-- 2. Extract SOAP Body and Operation
local function get_operation_data(root)
    local envelope = root.Envelope or root["soapenv:Envelope"] or root["soap:Envelope"]
    if not envelope then return nil, "No Envelope found" end
    
    local body = envelope.Body or envelope["soapenv:Body"] or envelope["soap:Body"]
    if not body then return nil, "No Body found" end
    
    for key, value in pairs(body) do
        local clean_key = key:match(".*:(.*)") or key
        return clean_key, value
    end
    
    return nil, "No Operation found"
end

-- 3. Parse operation name using convention
-- Example: "getUserRequest" -> action="get", resource="User", needs_id=true
local function parse_operation_name(op_name)
    -- Remove "Request" suffix
    local clean_name = op_name:gsub("Request$", "")
    
    -- Find matching action prefix
    for action, pattern in pairs(config.action_patterns) do
        if clean_name:lower():match("^" .. action) then
            -- Extract resource name (e.g., "getUser" -> "User")
            local resource = clean_name:sub(#action + 1)
            -- Convert to lowercase plural for REST convention
            local resource_path = resource:lower()
            if not resource_path:match("s$") then
                resource_path = resource_path .. "s"  -- Simple pluralization
            end
            
            return {
                action = action,
                resource = resource,
                resource_path = resource_path,
                method = pattern.method,
                needs_id = pattern.needs_id
            }
        end
    end
    
    return nil
end

-- 4. Clean namespaced keys from XML data
local function clean_keys(data)
    if type(data) ~= "table" then return data end
    
    local cleaned = {}
    for k, v in pairs(data) do
        local clean_k = k:match(".*:(.*)") or k
        cleaned[clean_k] = clean_keys(v)  -- Recursive for nested tables
    end
    return cleaned
end

-- 5. Generic JSON to XML converter (recursive)
local function json_to_xml(data, indent)
    indent = indent or ""
    local xml = ""
    
    if type(data) == "table" then
        -- Check if it's an array
        local is_array = #data > 0
        
        if is_array then
            for _, item in ipairs(data) do
                if type(item) == "table" then
                    xml = xml .. json_to_xml(item, indent)
                else
                    xml = xml .. indent .. tostring(item) .. "\n"
                end
            end
        else
            -- It's an object/dictionary
            for k, v in pairs(data) do
                xml = xml .. indent .. "<" .. k .. ">"
                if type(v) == "table" then
                    xml = xml .. "\n" .. json_to_xml(v, indent .. "  ") .. indent
                else
                    xml = xml .. tostring(v)
                end
                xml = xml .. "</" .. k .. ">\n"
            end
        end
    else
        xml = indent .. tostring(data) .. "\n"
    end
    
    return xml
end

-- ==================== MAIN HANDLER ====================

ngx.req.read_body()
local xml_body = ngx.req.get_body_data()

if not xml_body then
    ngx.status = 400
    ngx.say("No body provided")
    return
end

ngx.log(ngx.INFO, "[SOAP-TO-REST] 1. Intercepted SOAP Request:\n", xml_body)

-- Parse SOAP request
local root = parse_xml(xml_body)
local op_name, op_data = get_operation_data(root)
if not op_name then
    ngx.status = 400
    ngx.say("Invalid SOAP request: " .. tostring(op_data))
    return
end

local clean_op = op_name:gsub("wsdl:", ""):gsub("tns:", "")

-- Parse operation using convention
local op_info = parse_operation_name(clean_op)
if not op_info then
    ngx.status = 404
    ngx.say("Unknown operation pattern: " .. clean_op)
    return
end

ngx.log(ngx.INFO, "[SOAP-TO-REST] Operation parsed: action=", op_info.action, 
        " resource=", op_info.resource_path, " method=", op_info.method)

-- Clean XML data (remove namespaces)
local clean_data = clean_keys(op_data)

-- Build REST request
local path = config.base_path .. "/" .. op_info.resource_path
local rest_body = nil

if op_info.needs_id then
    -- Extract ID from data (assume field named "id")
    local id = clean_data.id
    if not id then
        ngx.status = 400
        ngx.say("Missing 'id' parameter for operation: " .. clean_op)
        return
    end
    path = path .. "/" .. id
    
    -- For PUT/PATCH, include body (exclude id from body)
    if op_info.method == ngx.HTTP_PUT then
        local body_data = {}
        for k, v in pairs(clean_data) do
            if k ~= "id" then
                body_data[k] = v
            end
        end
        if next(body_data) then
            rest_body = cjson.encode(body_data)
        end
    end
else
    -- For POST, include all data as body
    if op_info.method == ngx.HTTP_POST then
        rest_body = cjson.encode(clean_data)
    end
end

ngx.log(ngx.INFO, "[SOAP-TO-REST] 2. Converted to REST Request: ", 
        op_info.method == ngx.HTTP_GET and "GET" or 
        op_info.method == ngx.HTTP_POST and "POST" or
        op_info.method == ngx.HTTP_PUT and "PUT" or
        op_info.method == ngx.HTTP_DELETE and "DELETE",
        " ", path, rest_body and ("\nBody: " .. rest_body) or "")

-- Make REST request
local res = ngx.location.capture(path, {
    method = op_info.method,
    body = rest_body
})

-- Handle response
if res.status >= 200 and res.status < 300 then
    ngx.log(ngx.INFO, "[SOAP-TO-REST] 3. Received JSON Response:\n", res.body)
    
    local json_res = cjson.decode(res.body)
    
    -- Generate response tag
    local response_tag = clean_op:gsub("Request$", "Response")
    
    -- Convert JSON to XML dynamically
    local content_xml = json_to_xml(json_res, "         ")
    
    local soap_response = [[
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsdl="http://www.examples.com/wsdl/UserService.wsdl">
   <soapenv:Header/>
   <soapenv:Body>
      <wsdl:]] .. response_tag .. [[>
]] .. content_xml .. [[      </wsdl:]] .. response_tag .. [[>
   </soapenv:Body>
</soapenv:Envelope>
]]

    ngx.log(ngx.INFO, "[SOAP-TO-REST] 4. Converted to SOAP Response:\n", soap_response)
    ngx.header["Content-Type"] = "text/xml"
    ngx.say(soap_response)
else
    ngx.status = res.status
    ngx.say(res.body)
end
