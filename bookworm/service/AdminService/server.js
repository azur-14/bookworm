const express = require('express');
const connectDB = require('./dtb');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');

const systemconfigRoutes = require('./routes/systemconfig');
const activityLogRoutes = require('./routes/log');

const app = express();
const PORT = process.env.PORT;

app.use(cors());
app.use(express.json());
app.use(bodyParser.json());

// Kết nối MongoDB
connectDB();

// Routes
app.use('/api/systemConfig', systemconfigRoutes);
app.use('/api/logs', activityLogRoutes);

// Khởi chạy server
app.listen(PORT, () => {
    console.log(`AdminService chạy trên cổng ${PORT}`);
});
