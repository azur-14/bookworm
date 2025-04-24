const express = require('express');
const router = express.Router();
const RoomBookingRequest = require('../models/RoomBookingRequest');

// lấy tất cả yêu cầu đặt phòng
router.get('/', async (req, res) => {
  try {
    const requests = await RoomBookingRequest.find().populate('user_id').populate('room_id');
    res.status(200).json(requests);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
});

// Lấy tất cả RoomBookingRequest của người dùng
router.get('/user/:userId', async (req, res) => {
  try {
    const requests = await RoomBookingRequest.find({ user_id: req.params.userId });
    res.json(requests);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch booking requests' });
  }
});

module.exports = router;
