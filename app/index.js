const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

// Parse JSON body
app.use(bodyParser.json());

// Middleware to transform request body (username -> name)
app.use((req, res, next) => {
  if (req.body && req.body.username !== undefined) {
    console.log('Transforming request: username -> name');
    req.body.name = req.body.username;
    delete req.body.username;
  }
  next();
});

// Middleware to transform response body (name -> username)
app.use((req, res, next) => {
  const originalJson = res.json;
  res.json = function(data) {
    if (data && typeof data === 'object') {
      // Transform name back to username in response
      if (data.name !== undefined) {
        data.username = data.name;
        delete data.name;
      }
      
      // Transform any text containing 'name' to 'username'
      if (data.message && typeof data.message === 'string') {
        data.message = data.message.replace(/name/g, 'username');
      }
      
      // Transform receivedField
      if (data.receivedField === 'name') {
        data.receivedField = 'username';
      }
    }
    return originalJson.call(this, data);
  };
  next();
});

// Sample POST endpoint
app.post('/api', (req, res) => {
  console.log('Request body after transformation:', req.body);
  res.json({
    message: 'Hello, ' + req.body.name,
    receivedField: 'name', // This will be transformed back to 'username' by middleware
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
