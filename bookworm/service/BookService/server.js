const express = require('express');
const connectDB = require('./dtb');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');

const categoryRoutes = require('./routes/category');
const bookRoutes = require('./routes/book');
const shelfRoutes = require('./routes/shelf');
const bookCopyRoutes = require('./routes/bookCopy');

const app = express();
const PORT = process.env.PORT;

app.use(cors());
app.use(express.json());
app.use(bodyParser.json());

// Kết nối MongoDB
connectDB();

// Routes
app.use('/api/categories', categoryRoutes);
app.use('/api/books', bookRoutes);
app.use('/api/shelves', shelfRoutes);
app.use('/api/bookcopies', bookCopyRoutes);

// Khởi chạy server
app.listen(PORT, () => {
    console.log(`BookService chạy trên cổng ${PORT}`);
});
