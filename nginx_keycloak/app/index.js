const express = require('express');
const session = require('express-session');
const axios = require('axios');
const cors = require('cors');
const helmet = require('helmet');
const qs = require('qs');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Keycloak configuration
const KEYCLOAK_URL = process.env.KEYCLOAK_URL || 'http://keycloak:8080';
const KEYCLOAK_REALM = process.env.KEYCLOAK_REALM || 'master';
const KEYCLOAK_CLIENT_ID = process.env.KEYCLOAK_CLIENT_ID || 'nginx-client';
const KEYCLOAK_CLIENT_SECRET = process.env.KEYCLOAK_CLIENT_SECRET || 'your-client-secret-here';
const REDIRECT_URI = process.env.REDIRECT_URI || 'http://localhost/callback';

// Middleware
app.use(helmet());
app.use(cors({
  origin: true,
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Session configuration
app.use(session({
  secret: process.env.SESSION_SECRET || 'your-session-secret-change-this',
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: false, // Set to true if using HTTPS
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000 // 24 hours
  }
}));

// Utility functions
const getKeycloakUrls = () => ({
  auth: `${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/auth`,
  token: `${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/token`,
  userinfo: `${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/userinfo`,
  logout: `${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/logout`
});

const isAuthenticated = (req, res, next) => {
  if (req.session && req.session.user) {
    return next();
  }
  return res.status(401).json({ error: 'Authentication required' });
};

// Routes

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    service: 'express-app'
  });
});

// Home page
app.get('/', (req, res) => {
  if (req.session && req.session.user) {
    res.json({
      message: 'Welcome to the protected application!',
      user: req.session.user,
      authenticated: true,
      links: {
        api: '/api',
        logout: '/logout'
      }
    });
  } else {
    res.json({
      message: 'Welcome! Please login to access protected resources.',
      authenticated: false,
      links: {
        login: '/login'
      }
    });
  }
});

// Login endpoint
app.get('/login', (req, res) => {
  const state = uuidv4();
  req.session.state = state;
  
  const keycloakUrls = getKeycloakUrls();
  const authUrl = `${keycloakUrls.auth}?${qs.stringify({
    client_id: KEYCLOAK_CLIENT_ID,
    redirect_uri: REDIRECT_URI,
    response_type: 'code',
    scope: 'openid profile email',
    state: state
  })}`;
  
  res.redirect(authUrl);
});

// OAuth callback
app.get('/callback', async (req, res) => {
  const { code, state } = req.query;
  
  // Verify state parameter
  if (!state || state !== req.session.state) {
    return res.status(400).json({ error: 'Invalid state parameter' });
  }
  
  if (!code) {
    return res.status(400).json({ error: 'Authorization code not provided' });
  }
  
  try {
    const keycloakUrls = getKeycloakUrls();
    
    // Exchange code for tokens
    const tokenResponse = await axios.post(keycloakUrls.token, qs.stringify({
      grant_type: 'authorization_code',
      client_id: KEYCLOAK_CLIENT_ID,
      client_secret: KEYCLOAK_CLIENT_SECRET,
      code: code,
      redirect_uri: REDIRECT_URI
    }), {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    });
    
    const { access_token, refresh_token } = tokenResponse.data;
    
    // Get user info
    const userResponse = await axios.get(keycloakUrls.userinfo, {
      headers: {
        Authorization: `Bearer ${access_token}`
      }
    });
    
    // Store user session
    req.session.user = {
      id: userResponse.data.sub,
      username: userResponse.data.preferred_username,
      email: userResponse.data.email,
      name: userResponse.data.name,
      roles: userResponse.data.realm_access?.roles || []
    };
    req.session.tokens = {
      access_token,
      refresh_token
    };
    
    // Clean up state
    delete req.session.state;
    
    res.redirect('/');
  } catch (error) {
    console.error('OAuth callback error:', error.response?.data || error.message);
    res.status(500).json({ 
      error: 'Authentication failed',
      details: error.response?.data || error.message
    });
  }
});

// Logout endpoint
app.get('/logout', async (req, res) => {
  const refreshToken = req.session.tokens?.refresh_token;
  
  // Destroy local session
  req.session.destroy((err) => {
    if (err) {
      console.error('Session destruction error:', err);
    }
  });
  
  // Logout from Keycloak
  if (refreshToken) {
    try {
      const keycloakUrls = getKeycloakUrls();
      await axios.post(keycloakUrls.logout, qs.stringify({
        client_id: KEYCLOAK_CLIENT_ID,
        client_secret: KEYCLOAK_CLIENT_SECRET,
        refresh_token: refreshToken
      }), {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      });
    } catch (error) {
      console.error('Keycloak logout error:', error.response?.data || error.message);
    }
  }
  
  res.json({ message: 'Logged out successfully' });
});

// Protected API routes
app.get('/api', isAuthenticated, (req, res) => {
  res.json({
    message: 'Welcome to the API!',
    user: req.session.user,
    endpoints: [
      'GET /api/profile',
      'GET /api/data',
      'POST /api/data'
    ]
  });
});

app.get('/api/profile', isAuthenticated, (req, res) => {
  res.json({
    profile: req.session.user
  });
});

app.get('/api/data', isAuthenticated, (req, res) => {
  res.json({
    data: [
      { id: 1, name: 'Sample Data 1', value: 'Value 1' },
      { id: 2, name: 'Sample Data 2', value: 'Value 2' },
      { id: 3, name: 'Sample Data 3', value: 'Value 3' }
    ],
    user: req.session.user.username
  });
});

app.post('/api/data', isAuthenticated, (req, res) => {
  const { name, value } = req.body;
  
  if (!name || !value) {
    return res.status(400).json({ error: 'Name and value are required' });
  }
  
  const newData = {
    id: Date.now(),
    name,
    value,
    createdBy: req.session.user.username,
    createdAt: new Date().toISOString()
  };
  
  res.status(201).json({
    message: 'Data created successfully',
    data: newData
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    error: 'Something went wrong!',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Express app listening on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`Keycloak URL: ${KEYCLOAK_URL}`);
  console.log(`Keycloak Realm: ${KEYCLOAK_REALM}`);
  console.log(`Client ID: ${KEYCLOAK_CLIENT_ID}`);
});
