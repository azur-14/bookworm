// routes/requestStatusHistory.js
const express = require('express');
const router = express.Router();
const RequestStatusHistory = require('../models/RequestStatusHistory');

router.post('/', async (req, res) => {
  try {
    const history = new RequestStatusHistory(req.body);
    await history.save();
    res.status(201).json({ message: 'Lưu lịch sử thành công', history });
  } catch (err) {
    console.error('Lỗi lưu lịch sử:', err);
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
});

module.exports = router;
