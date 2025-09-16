// api/index.js
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-client');

const app = express();
const PORT = process.env.PORT || 3000;

// JWT verification setup
const client = jwksClient({
    jwksUri: 'http://192.168.101.13:8080/realms/myrealm/protocol/openid-connect/certs'
});

function getKey(header, callback) {
    client.getSigningKey(header.kid, (err, key) => {
        const signingKey = key.publicKey || key.rsaPublicKey;
        callback(null, signingKey);
    });
}

// Middleware
app.use(cors());
app.use(express.json());

// JWT verification middleware
const verifyJWT = (req, res, next) => {
    const token = req.headers['authorization']?.replace('Bearer ', '') || req.headers['x-access-token'];
    
    if (!token) {
        return res.status(401).json({ error: 'No token provided' });
    }

    jwt.verify(token, getKey, {
        audience: 'oauth2-proxy-client',
        issuer: 'http://192.168.101.13:8080/realms/myrealm',
        algorithms: ['RS256']
    }, (err, decoded) => {
        if (err) {
            console.error('JWT verification error:', err);
            return res.status(401).json({ error: 'Invalid token' });
        }
        
        req.user = {
            username: decoded.preferred_username || decoded.sub,
            email: decoded.email || '',
            groups: decoded.groups || [],
            token: decoded
        };
        console.log('JWT verified user:', req.user);
        next();
    });
};

// Middleware to log user info from OAuth2-proxy (fallback)
app.use((req, res, next) => {
    if (!req.user) {
        req.user = {
            username: req.headers['x-user'] || 'anonymous',
            email: req.headers['x-email'] || '',
            groups: req.headers['x-groups'] || ''
        };
        console.log('User info from headers:', req.user);
    }
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

app.get('/protected', verifyJWT, (req, res) => {
    res.json({
        message: 'This is a protected resource (JWT verified)',
        user: req.user,
        data: {
            secret: 'This is confidential data',
            accessTime: new Date().toISOString(),
            tokenInfo: {
                issuedAt: new Date(req.user.token.iat * 1000).toISOString(),
                expiresAt: new Date(req.user.token.exp * 1000).toISOString(),
                issuer: req.user.token.iss
            }
        }
    });
});

app.get('/jwt-info', verifyJWT, (req, res) => {
    res.json({
        message: 'JWT Token Information',
        user: req.user,
        token: req.user.token,
        headers: {
            authorization: req.headers['authorization'] ? 'Present' : 'Not present',
            xAccessToken: req.headers['x-access-token'] ? 'Present' : 'Not present'
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