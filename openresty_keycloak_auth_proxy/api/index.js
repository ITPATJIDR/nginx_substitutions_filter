// api/index.js
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Middleware to log user info from OAuth2-proxy
app.use((req, res, next) => {
    req.user = {
        username: req.headers['x-user'] || 'anonymous',
        email: req.headers['x-email'] || '',
        groups: req.headers['x-groups'] || ''
    };
    console.log('User info:', req.user);
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
        endpoints: [
            'GET /',
            'GET /health',
            'GET /profile',
            'GET /protected',
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