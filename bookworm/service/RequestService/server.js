const express = require('express');
const connectDB = require('./dtb');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');

const roomBookingRequestRoutes = require('./routes/roomBookingRequest');
const borrowRequestRoutes = require('./routes/borrowRequest');

const app = express();
const PORT = process.env.PORT;

app.use(cors());
app.use(express.json());
app.use(bodyParser.json());

// Kết nối MongoDB
connectDB();

// Routes
app.use('/api/roomBookingRequest', roomBookingRequestRoutes);
app.use('/api/borrowRequest', borrowRequestRoutes);

// Khởi chạy server
app.listen(PORT, () => {
    console.log(`🚀 RequestService chạy trên cổng ${PORT}`);
});
