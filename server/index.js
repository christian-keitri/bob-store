const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const authRouter = require('./routes/auth');
const adminRouter = require('./routes/admin');
const productRouter = require('./routes/product');
const userRouter = require('./routes/user');

const app = express();
const PORT = process.env.PORT || 3000;
const DB = "your_mongodb_connection_string_here";

// CORS options for your frontend
const corsOptions = {
  origin: 'https://bobbys-store.web.app', // your frontend URL
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'x-auth-token'],
};

// Apply CORS globally *before* routes
app.use(cors(corsOptions));

// Handle preflight requests for all routes
app.options('*', cors(corsOptions));

// Middleware to parse JSON bodies
app.use(express.json());

// Your routers
app.use(authRouter);
app.use(adminRouter);
app.use(productRouter);
app.use(userRouter);

// Test route
app.get('/api/ping', (req, res) => res.json({ message: 'pong' }));

// Connect to MongoDB
mongoose.connect(DB)
  .then(() => console.log('Connection Successful'))
  .catch(err => console.error('MongoDB connection error:', err));

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server connected at port ${PORT}`);
});
