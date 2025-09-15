'use strict'

const express = require('express')

const app = express()
const port = process.env.PORT || 3000

app.get('/', (req, res) => {
  res.json({ message: 'API root', time: new Date().toISOString() })
})

app.get('/api/public/hello', (req, res) => {
  res.json({ message: 'Hello from public route' })
})

app.get('/api/protected/hello', (req, res) => {
  const user = req.header('X-User') || 'unknown'
  const email = req.header('X-Email') || null
  res.json({ message: 'Hello from protected route', user, email })
})

app.listen(port, () => {
  console.log(`API listening on ${port}`)
})


