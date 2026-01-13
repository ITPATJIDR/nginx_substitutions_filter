const express = require('express');
const soap = require('soap');
const fs = require('fs');
const path = require('path');

const app = express();
const port = 8000;

// Mock Database
let users = [
    { id: '1', name: 'John Doe', email: 'john@example.com' },
    { id: '2', name: 'Jane Smith', email: 'jane@example.com' }
];

// Service Implementation
const service = {
    UserService: {
        UserPort: {
            getUser: function(args) {
                console.log('getUser called with:', args);
                const user = users.find(u => u.id === args.id);
                if (user) {
                    return { name: user.name, email: user.email };
                }
                return { name: 'Not Found', email: 'N/A' };
            },
            createUser: function(args) {
                console.log('createUser called with:', args);
                const newId = (users.length + 1).toString();
                const newUser = {
                    id: newId,
                    name: args.name,
                    email: args.email
                };
                users.push(newUser);
                return { id: newId, status: 'Success' };
            },
            listUsers: function(args) {
                console.log('listUsers called');
                // soap module handles array of objects differently depending on version/config, 
                // but usually for 'xsd:string' maxOccurs="unbounded", it expects an array of strings or simple types if mapped simplistically.
                // However, our WSDL defined it as xsd:string maxOccurs="unbounded" inside 'users'.
                // Let's return a JSON stringified list for simplicity in this demo or just names.
                // To be strictly correct with the WSDL type "xsd:string", we should return an array of strings.
                return {
                    users: users.map(u => `${u.id}: ${u.name} (${u.email})`)
                };
            }
        }
    }
};

// Load WSDL
const wsdlEnv = fs.readFileSync(path.join(__dirname, 'service.wsdl'), 'utf8');

app.listen(port, function() {
    console.log(`Express server listening on port ${port}`);
    // Enable SOAP service
    soap.listen(app, '/wsdl', service, wsdlEnv, function(){
      console.log('SOAP server initialized at http://localhost:8000/wsdl?wsdl');
    });
});
