const express = require('express');
const connectDB = require('./dtb');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

const roomBookingRequestRoutes = require('./routes/roomBookingRequest');
const borrowRequestRoutes = require('./routes/borrowRequest');
const returnRequestRoutes = require('./routes/returnRequest');
const statusHistoryRoutes = require('./routes/statusHistory')
const billRoutes = require('./routes/bill');

const app = express();
const PORT = process.env.PORT;

app.use(cors());
app.use(express.json());
app.use(bodyParser.json());

// Kết nối MongoDB
connectDB();
// Cấu hình Swagger
const swaggerSpec = swaggerJsdoc({
  definition: {
        openapi: '3.0.0',
        info: {
          title: 'RequestService API',
          version: '1.0.0',
          description: 'API quản lý yêu cầu',
        },
        servers: [
          {
            url: 'http://localhost:3002',
          },
        ],
      },
      apis: ['./routes/*.js'],
});
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
// Routes
app.use('/api/roomBookingRequest', roomBookingRequestRoutes);
app.use('/api/borrowRequest', borrowRequestRoutes);
app.use('/api/returnRequest', returnRequestRoutes);
app.use('/api/requestStatusHistory', statusHistoryRoutes);
app.use('/api/bill', billRoutes);

// Khởi chạy server
app.listen(PORT, () => {
    console.log(`🚀 RequestService chạy trên cổng ${PORT}`);
    console.log(`📚 Swagger docs tại http://localhost:${PORT}/api-docs`);
});
