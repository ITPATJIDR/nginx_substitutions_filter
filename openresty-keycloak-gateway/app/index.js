const express = require('express');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public '));

// Middleware to log all requests and headers
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  console.log('Headers:', JSON.stringify(req.headers, null, 2));
  next();
});

// Helper function to decode base64 token
function decodeToken(token) {
  try {
    // Convert URL-safe base64 back to standard base64
    const standardBase64 = token.replace(/-/g, '+').replace(/_/g, '/');
    
    // Add padding if needed
    const padding = standardBase64.length % 4;
    const paddedBase64 = padding ? standardBase64 + '='.repeat(4 - padding) : standardBase64;
    
    // Decode base64 and parse JSON
    const decoded = Buffer.from(paddedBase64, 'base64').toString('utf-8');
    return JSON.parse(decoded);
  } catch (error) {
    console.error('Error decoding token:', error);
    return null;
  }
}

// Main route
app.get('/', (req, res) => {
  const userToken = req.headers['x-real-name'];
  let userInfo = null;
  
  if (userToken) {
    userInfo = decodeToken(userToken);
  }

  const response = {
    message: 'Hello from Express app behind OpenResty Keycloak Gateway!',
    timestamp: new Date().toISOString(),
    headers: req.headers,
    userInfo: userInfo,
    requestInfo: {
      method: req.method,
      url: req.url,
      ip: req.ip,
      protocol: req.protocol
    }
  };

  res.json(response);
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// User info endpoint
app.get('/user', (req, res) => {
  const userToken = req.headers['x-real-name'];
  
  if (!userToken) {
    return res.status(401).json({
      error: 'No user token found in X-Real-Name header'
    });
  }

  const userInfo = decodeToken(userToken);
  
  if (!userInfo) {
    return res.status(400).json({
      error: 'Invalid user token format'
    });
  }

  res.json({
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
  console.log(`Access the app at http://localhost:${port}`);
});
