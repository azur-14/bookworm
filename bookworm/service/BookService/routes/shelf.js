const express = require('express');
const router = express.Router();
const Shelf = require('../models/Shelves');

// GET /api/shelves - lấy danh sách tất cả kệ sách
router.get('/', async (req, res) => {
  try {
    const shelves = await Shelf.find().sort({ id: 1 }); // sắp xếp theo id tăng dần
    res.json(shelves);
  } catch (err) {
    res.status(500).json({ error: 'Lỗi khi truy vấn kệ sách.' });
  }
});

router.get('/available', async (req, res) => {
  try {
    const shelves = await Shelf.find({
      $expr: { $gt: ["$capacityLimit", "$capacity"] } // đúng nghĩa: còn chỗ
    });
    res.json(shelves);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi khi lấy danh sách kệ còn chỗ', error: err.message });
  }
});

module.exports = router;
