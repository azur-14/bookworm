const express = require('express');
const router = express.Router();
const Category = require('../models/Category');

/**
 * @swagger
 * /api/categories:
 *   get:
 *     summary: Lấy danh sách tất cả thể loại sách
 *     tags: [Categories]
 *     responses:
 *       200:
 *         description: Trả về danh sách thể loại
 *       500:
 *         description: Lỗi server
 */
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
