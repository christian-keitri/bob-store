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

// Use env variable if available, else fallback (don't hardcode password in production)
const DB = process.env.MONGODB_URI || "mongodb+srv://christianjoshuasalapate:ENGR.bob28@cluster0.4yh3ykr.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0";

// MIDDLEWARE
app.use(express.json()); // JSON parsing first

// CORS OPTIONS
const corsOptions = {
  origin: 'https://bobbys-store.web.app',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'x-auth-token'], // added x-auth-token here
};

// Enable CORS for all routes & preflight requests
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));

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
