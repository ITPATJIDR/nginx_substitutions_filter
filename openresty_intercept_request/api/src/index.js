import express from 'express';
import morgan from 'morgan';

const app = express();
const port = process.env.PORT || 3000;

app.use(morgan('dev'));
app.use(express.json());

// Health check endpoint
app.get('/', (req, res) => {
  res.type('text/plain').send('OK');
});

// Public status endpoint
app.get('/api/status', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    message: 'API is running'
  });
});

// Success endpoint
app.get('/api/hello', (req, res) => {
  const user = req.header('x-user') || 'guest';
  res.json({ 
    message: `Hello, ${user}!`, 
    timestamp: new Date().toISOString() 
  });
});

// Endpoint that sometimes fails (for testing)
app.get('/api/random', (req, res) => {
  // 30% chance of failure
  if (Math.random() < 0.3) {
    return res.status(503).json({ 
      error: 'Service temporarily unavailable',
      timestamp: new Date().toISOString()
    });
  }
  
  res.json({
    message: 'Success!',
    random: Math.random(),
    timestamp: new Date().toISOString()
  });
});

// Data endpoint
app.post('/api/data', (req, res) => {
  const data = req.body;
  res.json({
    received: data,
    processed: true,
    timestamp: new Date().toISOString()
  });
});

// Error handling
app.use((req, res) => {
  res.status(404).json({ 
    error: 'Not Found',
    path: req.path,
    timestamp: new Date().toISOString()
  });
});

app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ 
    error: 'Internal Server Error',
    message: err.message,
    timestamp: new Date().toISOString()
  });
});

app.listen(port, () => {
  console.log(`API listening on port ${port}`);
});

