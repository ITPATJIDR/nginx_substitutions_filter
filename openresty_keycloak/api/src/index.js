import express from 'express';
import morgan from 'morgan';

const app = express();
const port = process.env.PORT || 3000;

app.use(morgan('dev'));
app.use(express.json());

app.get('/', (req, res) => {
  res.type('text/plain').send('OK');
});

app.get('/api/hello', (req, res) => {
  const user = req.header('x-user') || 'anonymous';
  res.json({ message: `Hello, ${user}!`, time: new Date().toISOString() });
});

app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`API listening on port ${port}`);
});


