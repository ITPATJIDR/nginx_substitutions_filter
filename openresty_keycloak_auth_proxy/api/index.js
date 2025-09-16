// api/index.js
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Middleware to extract user info from OAuth2-Proxy headers or JWT token
app.use((req, res, next) => {
    // OAuth2-Proxy passes user info via headers
    req.user = {
        username: req.headers['x-forwarded-user'] || req.headers['x-user'] || 'anonymous',
        email: req.headers['x-forwarded-email'] || req.headers['x-email'] || '',
        groups: req.headers['x-forwarded-groups'] || req.headers['x-groups'] || '',
        // JWT token is passed in Authorization header
        token: req.headers['authorization'] || ''
    };
    
    // If we have a JWT token but no user info from OAuth2-Proxy, 
    // extract basic info from JWT (for direct API access)
    if (req.user.token && !req.user.email) {
        try {
            const token = req.user.token.replace('Bearer ', '');
            const payload = JSON.parse(Buffer.from(token.split('.')[1], 'base64').toString());
            req.user.email = payload.email || payload.preferred_username || '';
            req.user.username = payload.preferred_username || payload.name || 'anonymous';
        } catch (err) {
            console.log('Could not parse JWT token:', err.message);
        }
    }
    
    console.log('Request headers:', {
        'x-forwarded-user': req.headers['x-forwarded-user'],
        'x-forwarded-email': req.headers['x-forwarded-email'],
        'x-forwarded-groups': req.headers['x-forwarded-groups'],
        'authorization': req.headers['authorization'] ? 'Bearer [JWT_TOKEN]' : 'none',
        'parsed-user': req.user
    });
    next();
});

// Routes
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        service: 'express-api',
        timestamp: new Date().toISOString()
    });
});

app.get('/', (req, res) => {
    res.json({
        message: 'Welcome to the secured Express API',
        user: req.user,
        authentication: {
            hasToken: !!req.user.token,
            tokenType: req.user.token ? 'JWT' : 'none',
            userAuthenticated: req.user.email !== ''
        },
        endpoints: [
            'GET /',
            'GET /health',
            'GET /profile',
            'GET /protected',
            'GET /token-info',
            'POST /data'
        ]
    });
});

app.get('/profile', (req, res) => {
    res.json({
        message: 'User profile information',
        user: req.user,
        serverTime: new Date().toISOString()
    });
});

app.get('/protected', (req, res) => {
    if (!req.user.email) {
        return res.status(401).json({ error: 'Authentication required' });
    }
    
    res.json({
        message: 'This is a protected resource',
        user: req.user,
        data: {
            secret: 'This is confidential data',
            accessTime: new Date().toISOString()
        }
    });
});

app.get('/token-info', (req, res) => {
    res.json({
        message: 'JWT Token Information',
        user: req.user,
        tokenInfo: {
            hasToken: !!req.user.token,
            tokenLength: req.user.token ? req.user.token.length : 0,
            tokenPrefix: req.user.token ? req.user.token.substring(0, 20) + '...' : 'none',
            headers: {
                'x-forwarded-user': req.headers['x-forwarded-user'],
                'x-forwarded-email': req.headers['x-forwarded-email'],
                'x-forwarded-groups': req.headers['x-forwarded-groups'],
                'authorization': req.headers['authorization'] ? 'Bearer [JWT_TOKEN]' : 'none'
            }
        }
    });
});

app.post('/data', (req, res) => {
    res.json({
        message: 'Data received',
        user: req.user,
        receivedData: req.body,
        timestamp: new Date().toISOString()
    });
});

// Error handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Endpoint not found' });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Express API server running on port ${PORT}`);
});

module.exports = app;