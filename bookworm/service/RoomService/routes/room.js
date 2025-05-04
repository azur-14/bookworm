// routes/roomRoutes.js
const express = require('express');
const router = express.Router();
const Room = require('../models/Room'); // đường dẫn đến file roomSchema bạn vừa gửi

// Lấy danh sách tất cả phòng (room_M, RBHP)
router.get('/', async (req, res) => {
  try {
    const rooms = await Room.find();
    res.status(200).json(rooms);
  } catch (error) {
    res.status(500).json({ message: 'Lỗi server', error: error.message });
  }
});

// cập nhật giá phòng
router.put('/:id/fee', async (req, res) => {
  const { id } = req.params;
  const { fee } = req.body;

  if (typeof fee !== 'number' || fee < 0) {
    return res.status(400).json({ message: 'Invalid fee value' });
  }
  try {
    const room = await Room.findOneAndUpdate(
      { id },
      { $set: { fee } },
      { new: true }
    );

    if (!room) {
      return res.status(404).json({ message: 'Room not found' });
    }

    res.status(200).json({ message: 'Fee updated', room });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
