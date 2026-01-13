local xml2lua = require("xml2lua")
local handler = require("xmlhandler.tree")
local cjson = require("cjson")

-- 1. Helper: Parse XML Request
local function parse_xml(xml_body)
    local h = handler:new()
    local parser = xml2lua.parser(h)
    parser:parse(xml_body)
    return h.root
end

-- 2. Helper: Find SOAP Body and Operation
local function get_operation_data(root)
    -- This handles standard soapenv:Envelope/soapenv:Body structure
    -- We need to be resilient to namespaces. xml2lua usually strips namespaces or keeps them as keys.
    -- We'll just look for Body.
    
    local envelope = root.Envelope or root["soapenv:Envelope"] or root["soap:Envelope"]
    if not envelope then return nil, "No Envelope found" end
    
    local body = envelope.Body or envelope["soapenv:Body"] or envelope["soap:Body"]
    if not body then return nil, "No Body found" end
    
    -- The first child of Body is usually the Operation Request
    for key, value in pairs(body) do
        -- stripping namespace from key i.e. "wsdl:getUserRequest" -> "getUserRequest"
        local clean_key = key:match(".*:(.*)") or key
        return clean_key, value
    end
    
    return nil, "No Operation found"
end

-- 3. Configuration: Mapping Operations to REST Endpoints
-- Modify this table to add new endpoints in the future
local operation_map = {
    getUserRequest = {
        method = ngx.HTTP_GET,
        path_template = "/internal_rest_proxy/users/%s",
        path_param = "id" -- Key in XML to use for path replacement
    },
    createUserRequest = {
        method = ngx.HTTP_POST,
        path = "/internal_rest_proxy/users",
        body_param = true -- Send all fields as JSON body
    },
    listUsersRequest = {
        method = ngx.HTTP_GET,
        path = "/internal_rest_proxy/users"
    }
}

-- 4. Main Request Handler
ngx.req.read_body()
local xml_body = ngx.req.get_body_data()

if not xml_body then
    ngx.status = 400
    ngx.say("No body provided")
    return
end

ngx.log(ngx.INFO, "[SOAP-TO-REST] 1. Intercepted SOAP Request:\n", xml_body)

local root = parse_xml(xml_body)
local op_name, op_data = get_operation_data(root)
local clean_op = op_name:gsub("wsdl:", ""):gsub("tns:", "") -- Cleanup if still has prefixes

local config = operation_map[clean_op]

if not config then
    ngx.status = 404
    ngx.say("SOAP Operation not supported: " .. tostring(clean_op))
    return
end

-- Prepare Subrequest
local res
if config.method == ngx.HTTP_GET then
    local path = config.path
    if config.path_template and config.path_param then
        -- Handle converting nested keys if needed, e.g. wsdl:id -> id.
        -- op_data might have namespaced keys.
        local param_val
        for k,v in pairs(op_data) do
            if k:find(config.path_param) then
                param_val = v
                break
            end
        end
        if not param_val then 
             -- try direct access if xml2lua stripped it
             param_val = op_data[config.path_param]
        end
        
        if param_val then
             path = string.format(config.path_template, param_val)
        else
             ngx.status = 400
             ngx.say("Missing parameter: " .. config.path_param)
             return
        end
    end
    
    ngx.log(ngx.INFO, "[SOAP-TO-REST] 2. Parsed & Converted to GET Request: Path=", path)
    res = ngx.location.capture(path, { method = ngx.HTTP_GET })

elseif config.method == ngx.HTTP_POST then
    -- Convert Lua table (op_data) to JSON
    -- Need to clean keys (remove "wsdl:" etc) for typical REST APIs
    local json_payload = {}
    for k,v in pairs(op_data) do
        local clean_k = k:match(".*:(.*)") or k
        json_payload[clean_k] = v
    end
    
    local json_str = cjson.encode(json_payload)
    ngx.log(ngx.INFO, "[SOAP-TO-REST] 2. Parsed & Converted to JSON Request:\n", json_str)

    res = ngx.location.capture(config.path, {
        method = ngx.HTTP_POST,
        body = json_str
    })
end

-- 5. Response Handler (JSON -> XML)
if res.status >= 200 and res.status < 300 then
    ngx.log(ngx.INFO, "[SOAP-TO-REST] 3. Received JSON Response from Backend:\n", res.body)
    local json_res = cjson.decode(res.body)
    
    -- Construct XML Response
    -- We can use xml2lua.toXml but for specific SOAP structure manual building might be easier/cleaner
    -- Structure: <soap:Envelope><soap:Body><ResponseTag>...</ResponseTag></soap:Body></soap:Envelope>
    
    local response_tag = clean_op:gsub("Request", "Response") -- e.g. getUserResponse
    local content_xml = ""
    
    if type(json_res) == "table" then
        if json_res.users and type(json_res.users) == "table" then
             -- Handle listUsers array special case
             local list_content = ""
             for _, u in ipairs(json_res.users) do
                  -- simplistic mapping for the demo
                  list_content = list_content .. "<users>" .. u.id .. ": " .. u.name .. " (" .. u.email .. ")</users>"
             end
             content_xml = list_content
        else
            -- Check for simple k-v
            for k,v in pairs(json_res) do
                content_xml = content_xml .. "<" .. k .. ">" .. tostring(v) .. "</" .. k .. ">"
            end
        end
    end
    
    local soap_response = [[
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsdl="http://www.examples.com/wsdl/UserService.wsdl">
   <soapenv:Header/>
   <soapenv:Body>
      <wsdl:]] .. response_tag .. [[>
         ]] .. content_xml .. [[
      </wsdl:]] .. response_tag .. [[>
   </soapenv:Body>
</soapenv:Envelope>
]]

    
    ngx.log(ngx.INFO, "[SOAP-TO-REST] 4. Converted to SOAP Response:\n", soap_response)
    ngx.header["Content-Type"] = "text/xml"
    ngx.say(soap_response)

else
    -- Error handling
    ngx.status = res.status
    ngx.say(res.body)
end
