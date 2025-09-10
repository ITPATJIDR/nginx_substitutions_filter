const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

// Parse JSON body
app.use(bodyParser.json());


// Sample POST endpoint
app.post('/api', (req, res) => {
  console.log('Original request body:', req.body);
  // Handle both username and name fields
  const name = req.body.name || req.body.username || 'Unknown';
  res.json({
    message: 'Hello, ' + name,
    receivedField: 'name', // This will be transformed to 'username' by Nginx
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
