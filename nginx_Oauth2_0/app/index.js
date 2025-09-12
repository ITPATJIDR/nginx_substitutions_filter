const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const port = 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  console.log('Headers:', req.headers);
  if (req.body && Object.keys(req.body).length > 0) {
    console.log('Body:', req.body);
  }
  next();
});

// In-memory data store
let users = [
  { id: 1, name: 'John Doe', email: 'john@example.com', role: 'admin' },
  { id: 2, name: 'Jane Smith', email: 'jane@example.com', role: 'user' }
];

let posts = [
  { id: 1, title: 'First Post', content: 'This is the first post', userId: 1, createdAt: new Date().toISOString() },
  { id: 2, title: 'Second Post', content: 'This is the second post', userId: 2, createdAt: new Date().toISOString() }
];

// Helper function to get next ID
const getNextId = (array) => Math.max(...array.map(item => item.id), 0) + 1;

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    service: 'Simple Express API',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to Simple Express API',
    version: '1.0.0',
    endpoints: {
      users: '/api/users',
      posts: '/api/posts',
      health: '/health'
    }
  });
});

// Users API
app.get('/api/users', (req, res) => {
  res.json({
    success: true,
    data: users,
    count: users.length
  });
});

app.get('/api/users/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const user = users.find(u => u.id === id);
  
  if (!user) {
    return res.status(404).json({
      success: false,
      message: 'User not found'
    });
  }
  
  res.json({
    success: true,
    data: user
  });
});

app.post('/api/users', (req, res) => {
  const { name, email, role = 'user' } = req.body;
  
  if (!name || !email) {
    return res.status(400).json({
      success: false,
      message: 'Name and email are required'
    });
  }
  
  const newUser = {
    id: getNextId(users),
    name,
    email,
    role,
    createdAt: new Date().toISOString()
  };
  
  users.push(newUser);
  
  res.status(201).json({
    success: true,
    data: newUser,
    message: 'User created successfully'
  });
});

app.put('/api/users/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const userIndex = users.findIndex(u => u.id === id);
  
  if (userIndex === -1) {
    return res.status(404).json({
      success: false,
      message: 'User not found'
    });
  }
  
  const { name, email, role } = req.body;
  const updatedUser = {
    ...users[userIndex],
    ...(name && { name }),
    ...(email && { email }),
    ...(role && { role }),
    updatedAt: new Date().toISOString()
  };
  
  users[userIndex] = updatedUser;
  
  res.json({
    success: true,
    data: updatedUser,
    message: 'User updated successfully'
  });
});

app.delete('/api/users/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const userIndex = users.findIndex(u => u.id === id);
  
  if (userIndex === -1) {
    return res.status(404).json({
      success: false,
      message: 'User not found'
    });
  }
  
  users.splice(userIndex, 1);
  
  res.json({
    success: true,
    message: 'User deleted successfully'
  });
});

// Posts API
app.get('/api/posts', (req, res) => {
  res.json({
    success: true,
    data: posts,
    count: posts.length
  });
});

app.get('/api/posts/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const post = posts.find(p => p.id === id);
  
  if (!post) {
    return res.status(404).json({
      success: false,
      message: 'Post not found'
    });
  }
  
  res.json({
    success: true,
    data: post
  });
});

app.post('/api/posts', (req, res) => {
  const { title, content, userId } = req.body;
  
  if (!title || !content || !userId) {
    return res.status(400).json({
      success: false,
      message: 'Title, content, and userId are required'
    });
  }
  
  const newPost = {
    id: getNextId(posts),
    title,
    content,
    userId: parseInt(userId),
    createdAt: new Date().toISOString()
  };
  
  posts.push(newPost);
  
  res.status(201).json({
    success: true,
    data: newPost,
    message: 'Post created successfully'
  });
});

app.put('/api/posts/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const postIndex = posts.findIndex(p => p.id === id);
  
  if (postIndex === -1) {
    return res.status(404).json({
      success: false,
      message: 'Post not found'
    });
  }
  
  const { title, content } = req.body;
  const updatedPost = {
    ...posts[postIndex],
    ...(title && { title }),
    ...(content && { content }),
    updatedAt: new Date().toISOString()
  };
  
  posts[postIndex] = updatedPost;
  
  res.json({
    success: true,
    data: updatedPost,
    message: 'Post updated successfully'
  });
});

app.delete('/api/posts/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const postIndex = posts.findIndex(p => p.id === id);
  
  if (postIndex === -1) {
    return res.status(404).json({
      success: false,
      message: 'Post not found'
    });
  }
  
  posts.splice(postIndex, 1);
  
  res.json({
    success: true,
    message: 'Post deleted successfully'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found'
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error'
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Simple Express API listening at http://0.0.0.0:${port}`);
  console.log('Available endpoints:');
  console.log('  GET  /health - Health check');
  console.log('  GET  / - API info');
  console.log('  GET  /api/users - Get all users');
  console.log('  GET  /api/users/:id - Get user by ID');
  console.log('  POST /api/users - Create user');
  console.log('  PUT  /api/users/:id - Update user');
  console.log('  DELETE /api/users/:id - Delete user');
  console.log('  GET  /api/posts - Get all posts');
  console.log('  GET  /api/posts/:id - Get post by ID');
  console.log('  POST /api/posts - Create post');
  console.log('  PUT  /api/posts/:id - Update post');
  console.log('  DELETE /api/posts/:id - Delete post');
});
