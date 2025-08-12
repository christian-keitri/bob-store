// IMPORTS
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

// IMPORT ROUTERS
const authRouter = require('./routes/auth');
const adminRouter = require('./routes/admin');
const productRouter = require('./routes/product');
const userRouter = require('./routes/user');

// INIT
const PORT = process.env.PORT || 3000;
const app = express();

// TODO: For security, use environment variables instead of hardcoding your connection string
const DB = "mongodb+srv://christianjoshuasalapate:ENGR.bob28@cluster0.4yh3ykr.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0";

// CORS OPTIONS
const corsOptions = {
  origin: 'https://bobbys-store.web.app', // Your Firebase-hosted frontend URL
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};

// MIDDLEWARE
app.use(cors(corsOptions));          // Enable CORS for all routes
app.options('*', cors(corsOptions)); // Enable pre-flight across-the-board
app.use(express.json());             // Parse JSON bodies

// ROUTES
app.use(authRouter);
app.use(adminRouter);
app.use(productRouter);
app.use(userRouter);

// TEST ROUTE
app.get('/api/ping', (req, res) => {
  res.json({ message: 'pong' });
});

// MONGOOSE CONNECTION
mongoose
  .connect(DB)
  .then(() => {
    console.log('Connection Successful');
  })
  .catch((e) => {
    console.error('MongoDB connection error:', e);
  });

// SERVER START
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server connected at port ${PORT}`);
});
