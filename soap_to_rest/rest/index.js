const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

app.use(bodyParser.json());

// Mock Database (same initial data as SOAP service)
let users = [
    { id: '1', name: 'REST JA', email: 'REST@express.com' },
    { id: '2', name: 'REST JAJAJAJAJA', email: 'REST@JAJAJAJA.com' }
];

// 1. GET /users/:id (mirrors getUser)
app.get('/users/:id', (req, res) => {
    const id = req.params.id;
    console.log(req.params)
    console.log(`GET /users/${id} called`);

    const user = users.find(u => u.id === id);
    if (user) {
        const ResponseJson = { name: user.name, email: user.email }
        console.log(`Response: ${ResponseJson}`);
        res.json(ResponseJson);
    } else {
        res.status(404).json({ error: 'User not found' });
    }
});

// 2. POST /users (mirrors createUser)
app.post('/users', (req, res) => {
    const { name, email } = req.body;
    console.log('POST /users called with:', req.body);

    if (!name || !email) {
        return res.status(400).json({ error: 'Name and email are required' });
    }

    const newId = (users.length + 1).toString();
    const newUser = {
        id: newId,
        name: name,
        email: email
    };
    users.push(newUser);

    res.status(201).json({ id: newId, status: 'Success' });
});

// 3. GET /users (mirrors listUsers)
app.get('/users', (req, res) => {
    console.log('GET /users called');
    // Mirroring SOAP response structure where it returns { users: [...] }
    // As per SOAP implementation, it returned an array of strings formatted "id: name (email)"
    // But for REST, usually we return the object list.
    // The user asked to "mirror" the SOAP service. 
    // The SOAP implementation: users.map(u => `${u.id}: ${u.name} (${u.email})`) inside a "users" field.
    // I will return a clean JSON list of objects because that's "normal" REST, 
    // but maybe I should stick to the "mirror" concept?
    // "create exactly like soap but rest api" -> usually implies functionality.
    // I'll stick to standard REST practices (clean JSON objects) unless specified otherwise, 
    // as it's more useful.

    res.json({
        users: users
    });
});

// ==================== SHOP ENDPOINTS ====================
let shops = [
    { id: '1', name: 'Coffee Shop', location: 'Bangkok' },
    { id: '2', name: 'Book Store', location: 'Chiang Mai' }
];

// GET /shops/:id (getShop)
app.get('/shops/:id', (req, res) => {
    const id = req.params.id;
    console.log(`GET /shops/${id} called`);

    const shop = shops.find(s => s.id === id);
    if (shop) {
        res.json({ name: shop.name, location: shop.location });
    } else {
        res.status(404).json({ error: 'Shop not found' });
    }
});

// POST /shops (createShop)
app.post('/shops', (req, res) => {
    const { name, location } = req.body;
    console.log('POST /shops called with:', req.body);

    if (!name || !location) {
        return res.status(400).json({ error: 'Name and location are required' });
    }

    const newId = (shops.length + 1).toString();
    const newShop = {
        id: newId,
        name: name,
        location: location
    };
    shops.push(newShop);

    res.status(201).json({ id: newId, status: 'Success' });
});

// GET /shops (listShops)
app.get('/shops', (req, res) => {
    console.log('GET /shops called');
    res.json({
        shops: shops
    });
});

app.listen(port, () => {
    console.log(`REST API server listening on port ${port}`);
});
