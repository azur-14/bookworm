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

module.exports = router;
