const soap = require('soap');

const url = 'http://localhost:8000/wsdl?wsdl';

soap.createClient(url, function (err, client) {
    if (err) {
        console.error('Error creating client:', err);
        return;
    }

    // 1. getUser
    client.getUser({ id: '1' }, function (err, result) {
        console.log('getUser(1):', result);
    });

    // 2. createUser
    client.createUser({ name: 'Alice', email: 'alice@example.com' }, function (err, result) {
        console.log('createUser(Alice):', result);
    });

    // 3. listUsers
    client.listUsers({}, function (err, result) {
        console.log('listUsers:', result);
    });
});
