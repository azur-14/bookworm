const express = require('express');
const router = express.Router();
const Category = require('../models/Category');

//lấy danh sách category (book_M)
router.get('/', async (req, res) => {
  try {
    const categories = await Category.find().sort({ name: 1 });
    res.json(categories);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
});

module.exports = router;
