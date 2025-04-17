// routes/roomRoutes.js
const express = require('express');
const router = express.Router();
const Room = require('../models/Room'); // đường dẫn đến file roomSchema bạn vừa gửi

// Lấy danh sách tất cả phòng (room_M)
router.get('/', async (req, res) => {
  try {
    const rooms = await Room.find();
    res.status(200).json(rooms);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi server', error: error.message });
  }
});

module.exports = router;
