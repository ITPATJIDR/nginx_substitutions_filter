const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Sample endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'API is running' });
});

app.get('/api/users', (req, res) => {
  res.json({
    users: [
      { id: 1, name: 'John Doe', email: 'john@example.com' },
      { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
    ]
  });
});

app.post('/api/users', (req, res) => {
  const user = req.body;
  res.status(201).json({
    message: 'User created',
    user: { id: 3, ...user }
  });
});

app.get('/api/data', (req, res) => {
  res.json({
    timestamp: new Date().toISOString(),
    data: 'Sample data from backend'
  });
});

// Catch all route
app.all('*', (req, res) => {
  res.status(404).json({
    error: 'Not found',
    path: req.path,
    method: req.method
  });
});

app.listen(PORT, () => {
  console.log(`API server listening on port ${PORT}`);
});

