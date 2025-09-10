const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

// Parse JSON body
app.use(bodyParser.json());

// Sample POST endpoint
app.post('/api', (req, res) => {
  console.log('Received request body:', req.body);
  // Handle the transformed name field (username -> name)
  const name = req.body.name || 'Unknown';
  res.json({
    message: 'Hello, ' + name,
    name: name,
    timestamp: new Date().toISOString()
  });
});

// Sample GET endpoint
app.get('/api', (req, res) => {
  res.json({
    message: 'Hello from Express!',
    timestamp: new Date().toISOString()
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', service: 'Express App' });
});

app.listen(port, () => {
  console.log(`Express app listening at http://localhost:${port}`);
});
