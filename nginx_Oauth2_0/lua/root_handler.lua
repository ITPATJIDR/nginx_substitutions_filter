-- Root handler - show login or user info
local oauth2 = require "oauth2"

-- Get token from cookie
local token = oauth2.get_token_from_cookie()

if not token then
    -- No token, show login page
    ngx.header["Content-Type"] = "text/html"
    ngx.say([[
<!DOCTYPE html>
<html>
<head>
    <title>Login Required</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .login-btn { 
            background-color: #007bff; 
            color: white; 
            padding: 10px 20px; 
            text-decoration: none; 
            border-radius: 5px; 
            display: inline-block; 
            margin: 20px;
        }
        .login-btn:hover { background-color: #0056b3; }
    </style>
</head>
<body>
    <h1>Welcome to the API Gateway</h1>
    <p>Please log in to access the protected resources.</p>
    <a href="/login" class="login-btn">Login with Keycloak</a>
</body>
</html>
    ]])
    return
end

-- Validate token
local is_valid, user_info = oauth2.validate_token(token)

if not is_valid then
    -- Invalid token, clear cookies and show login
    ngx.header["Set-Cookie"] = "access_token=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT; HttpOnly"
    ngx.header["Set-Cookie"] = "refresh_token=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT; HttpOnly"
    
    ngx.header["Content-Type"] = "text/html"
    ngx.say([[
<!DOCTYPE html>
<html>
<head>
    <title>Session Expired</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .login-btn { 
            background-color: #007bff; 
            color: white; 
            padding: 10px 20px; 
            text-decoration: none; 
            border-radius: 5px; 
            display: inline-block; 
            margin: 20px;
        }
        .login-btn:hover { background-color: #0056b3; }
    </style>
</head>
<body>
    <h1>Session Expired</h1>
    <p>Your session has expired. Please log in again.</p>
    <a href="/login" class="login-btn">Login with Keycloak</a>
</body>
</html>
    ]])
    return
end

-- Show user info
ngx.header["Content-Type"] = "text/html"
ngx.say([[
<!DOCTYPE html>
<html>
<head>
    <title>Welcome</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 50px; }
        .user-info { background-color: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .btn { 
            background-color: #dc3545; 
            color: white; 
            padding: 10px 20px; 
            text-decoration: none; 
            border-radius: 5px; 
            display: inline-block; 
            margin: 10px;
        }
        .btn:hover { background-color: #c82333; }
        .api-link {
            background-color: #28a745;
            color: white;
            padding: 10px 20px;
            text-decoration: none;
            border-radius: 5px;
            display: inline-block;
            margin: 10px;
        }
        .api-link:hover { background-color: #218838; }
    </style>
</head>
<body>
    <h1>Welcome, ]] .. (user_info.preferred_username or user_info.name or "User") .. [[!</h1>
    
    <div class="user-info">
        <h3>User Information:</h3>
        <p><strong>ID:</strong> ]] .. (user_info.sub or "N/A") .. [[</p>
        <p><strong>Email:</strong> ]] .. (user_info.email or "N/A") .. [[</p>
        <p><strong>Name:</strong> ]] .. (user_info.name or "N/A") .. [[</p>
    </div>
    
    <div>
        <a href="/api" class="api-link">Access API</a>
        <a href="/logout" class="btn">Logout</a>
    </div>
</body>
</html>
]])
