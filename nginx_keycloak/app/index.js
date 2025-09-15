const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  console.log('Headers:', JSON.stringify(req.headers, null, 2));
  next();
});

// Helper function to decode user information from headers
function getUserInfo(req) {
  // Check for user info headers set by nginx
  const userHeader = req.headers['x-user-info'];
  const userEmail = req.headers['x-user-email'];
  const userName = req.headers['x-user-name'];
  const userRoles = req.headers['x-user-roles'];
  
  if (userHeader) {
    try {
      // If nginx passes encoded user info
      return JSON.parse(Buffer.from(userHeader, 'base64').toString());
    } catch (error) {
      console.warn('Failed to decode user header:', error);
    }
  }
  
  // Fallback to individual headers
  return {
    email: userEmail,
    name: userName,
    roles: userRoles ? userRoles.split(',') : [],
    authenticated: !!(userEmail || userName)
  };
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    service: 'express-app'
  });
});

// Main route
app.get('/', (req, res) => {
  const userInfo = getUserInfo(req);
  
  const response = {
    message: 'Hello from Express app behind nginx with Keycloak!',
    timestamp: new Date().toISOString(),
    user: userInfo,
    headers: req.headers,
    requestInfo: {
      method: req.method,
      url: req.url,
      ip: req.ip,
      protocol: req.protocol,
      secure: req.secure
    }
  };

  res.json(response);
});

// User info endpoint
app.get('/user', (req, res) => {
  const userInfo = getUserInfo(req);
  
  if (!userInfo.authenticated) {
    return res.status(401).json({
      error: 'No user information found',
      message: 'User not authenticated or headers missing'
    });
  }

  res.json({
    user: userInfo,
    timestamp: new Date().toISOString()
  });
});

// Protected admin endpoint
app.get('/admin', (req, res) => {
  const userInfo = getUserInfo(req);
  
  if (!userInfo.authenticated) {
    return res.status(401).json({
      error: 'Authentication required'
    });
  }
  
  const hasAdminRole = userInfo.roles && userInfo.roles.some(role => 
    role.toLowerCase().includes('admin')
  );
  
  if (!hasAdminRole) {
    return res.status(403).json({
      error: 'Admin access required',
      userRoles: userInfo.roles
    });
  }

  res.json({
    message: 'Welcome to admin area!',
    user: userInfo,
    timestamp: new Date().toISOString()
  });
});

// API endpoints
app.get('/api/data', (req, res) => {
  const userInfo = getUserInfo(req);
  
  res.json({
    data: [
      { id: 1, name: 'Item 1', value: 100 },
      { id: 2, name: 'Item 2', value: 200 },
      { id: 3, name: 'Item 3', value: 300 }
    ],
    user: userInfo,
    timestamp: new Date().toISOString()
  });
});

// Debug endpoint to show all headers
app.get('/debug', (req, res) => {
  res.json({
    headers: req.headers,
    query: req.query,
    params: req.params,
    body: req.body,
    url: req.url,
    method: req.method,
    user: getUserInfo(req),
    timestamp: new Date().toISOString()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Internal server error',
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not found',
    url: req.url,
    timestamp: new Date().toISOString()
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Express app listening on port ${port}`);
  console.log(`Health check: http://localhost:${port}/health`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});
