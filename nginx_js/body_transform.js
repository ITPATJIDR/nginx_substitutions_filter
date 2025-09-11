// njs module for transforming request and response bodies
// Based on nginx njs-examples structure

function transformRequest(r) {
    // Remove authorization headers from request
    r.headersOut['Authorization'] = undefined;
    r.headersOut['X-API-Key'] = undefined;
    r.headersOut['X-Auth-Token'] = undefined;
    
    // Read the request body
    var body = r.requestBody;
    
    if (!body) {
        // If no body, just return 200 and let nginx proxy
        r.return(200, "No body to transform");
        return;
    }
    
    try {
        // Parse JSON
        var json = JSON.parse(body);
        
        // Transform username to name in request
        if (json.username !== undefined) {
            json.name = json.username;
            delete json.username;
        }
        
        // Convert back to JSON and set as new body
        r.requestBody = JSON.stringify(json);
        
        // Log the transformation
        r.log("Request body transformed: username -> name");
        
        // Return the transformed data
        r.return(200, JSON.stringify(json));
        
    } catch (e) {
        r.log("Error transforming request body: " + e.message);
        r.return(400, "Invalid JSON");
    }
}

function transformResponse(r) {
    // Read the response body
    var body = r.responseBody;
    
    if (!body) {
        return;
    }
    
    try {
        // Parse JSON
        var json = JSON.parse(body);
        
        // Transform name back to username in response
        if (json.name !== undefined) {
            json.username = json.name;
            delete json.name;
        }
        
        // Also transform any nested objects
        if (json.message && typeof json.message === 'string') {
            json.message = json.message.replace(/name/g, 'username');
        }
        
        // Convert back to JSON and set as new body
        r.responseBody = JSON.stringify(json);
        
        // Log the transformation
        r.log("Response body transformed: name -> username");
        
    } catch (e) {
        r.log("Error transforming response body: " + e.message);
    }
}

// Export functions for use in nginx config
export default { transformRequest, transformResponse };