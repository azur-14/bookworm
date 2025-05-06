const express = require('express');
const connectDB = require('./dtb');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');

const categoryRoutes = require('./routes/category');
const bookRoutes = require('./routes/book');
const shelfRoutes = require('./routes/shelf');
const bookCopyRoutes = require('./routes/bookCopy');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

const app = express();
const PORT = process.env.PORT;

// --- thêm bodyParser giới hạn size ---
app.use(express.json({ limit: '20mb' }));   // tăng giới hạn payload
app.use(express.urlencoded({ extended: true, limit: '20mb' }));

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
          title: 'BookService API',
          version: '1.0.0',
          description: 'API quản lý sách',
        },
        servers: [
          {
            url: 'http://localhost:3003',
          },
        ],
      },
      apis: ['./routes/*.js'],
});
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Routes
app.use('/api/categories', categoryRoutes);
app.use('/api/books', bookRoutes);
app.use('/api/shelves', shelfRoutes);
app.use('/api/bookcopies', bookCopyRoutes);

// Khởi chạy server
app.listen(PORT, () => {
    console.log(`BookService chạy trên cổng ${PORT}`);
    console.log(`📚 Swagger docs tại http://localhost:${PORT}/api-docs`);
});
