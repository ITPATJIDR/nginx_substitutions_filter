import express from 'express';
import morgan from 'morgan';

const app = express();
const port = process.env.PORT || 3000;

app.use(morgan('dev'));
app.use(express.json());

// Public routes (no authentication required)
app.get('/', (req, res) => {
  res.type('text/plain').send('OK');
});

app.get('/api/public/status', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    message: 'This is a public endpoint - no auth required'
  });
});

app.get('/api/public/info', (req, res) => {
  res.json({
    service: 'example-api',
    version: '1.0.0',
    description: 'Public API information'
  });
});

// Protected routes (require authentication)
app.get('/api/hello', (req, res) => {
  const user = req.header('x-user') || 'anonymous';
  res.json({ message: `Hello, ${user}!`, time: new Date().toISOString() });
});

app.get('/api/protected/profile', (req, res) => {
  const user = req.header('x-user') || 'anonymous';
  if (user === 'anonymous') {
    return res.status(401).json({ error: 'Authentication required' });
  }
  res.json({
    user: user,
    profile: {
      role: 'user',
      permissions: ['read', 'write'],
      lastLogin: new Date().toISOString()
    }
  });
});

app.get('/api/protected/admin', (req, res) => {
  const user = req.header('x-user') || 'anonymous';
  if (user === 'anonymous') {
    return res.status(401).json({ error: 'Authentication required' });
  }
  res.json({
    message: `Admin access granted for ${user}`,
    adminData: {
      serverStats: { uptime: '1h 23m', requests: 1234 },
      timestamp: new Date().toISOString()
    }
  });
});

app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`API listening on port ${port}`);
});