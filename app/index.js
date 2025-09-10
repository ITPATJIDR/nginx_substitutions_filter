const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

// Parse JSON body
app.use(bodyParser.json());

// Sample POST endpoint
app.post('/api', (req, res) => {
  console.log('Original request body:', req.body);
  res.json({
    message: 'Hello, ' + req.body.name,
    service: 'Express Backend',
    version: '1.0.0'
  });
});

// Sample GET endpoint
app.get('/api', (req, res) => {
  res.json({
    message: 'Hello from Express!',
    service: 'Express Backend',
    timestamp: new Date().toISOString(),
    features: ['REST API', 'JSON responses', 'Express framework']
  });
});

// Test endpoint for regex substitutions
app.get('/test-regex', (req, res) => {
  res.json({
    message: 'Testing regex substitutions',
    numbers: [123, 456, 789],
    text: 'Hello World with numbers 123 and 456',
    service: 'Express Backend'
  });
});

// Test endpoint for case-insensitive substitutions
app.get('/test-case', (req, res) => {
  res.json({
    message: 'Testing case variations: hello, Hello, HELLO',
    service: 'express backend',
    framework: 'EXPRESS'
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    service: 'Express App',
    message: 'Hello from health check'
  });
});

app.listen(port, () => {
  console.log(`Express app listening at http://localhost:${port}`);
});
