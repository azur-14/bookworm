const express = require('express');
const connectDB = require('./dtb');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');

const systemconfigRoutes = require('./routes/systemconfig');
const activityLogRoutes = require('./routes/log');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

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
          title: 'AdminService API',
          version: '1.0.0',
          description: 'API admin',
        },
        servers: [
          {
            url: 'http://localhost:3004',
          },
        ],
      },
      apis: ['./routes/*.js'],
});
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Routes
app.use('/api/systemConfig', systemconfigRoutes);
app.use('/api/logs', activityLogRoutes);

// Khởi chạy server
app.listen(PORT, () => {
    console.log(`AdminService chạy trên cổng ${PORT}`);
    console.log(`📚 Swagger docs tại http://localhost:${PORT}/api-docs`);
});
