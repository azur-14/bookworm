const express = require('express');
const router = express.Router();
const ReturnRequest = require('../models/ReturnRequest');
const BorrowRequest = require('../models/BorrowRequest');

// lấy kết quả mượn sách của người dùng hiện tại
router.get('/user/:userId', async (req, res) => {
    try {
      const borrowIds = await BorrowRequest.find({ user_id: req.params.userId }).distinct('id');
  
      const requests = await ReturnRequest.find().where('borrow_request_id').in(borrowIds);
      res.json(requests);
    } catch (err) {
      console.error('❌ Error in return-requests:', err);
      res.status(500).json({ error: 'Failed to fetch return requests' });
    }
});

// Lấy toàn bộ return requests
router.get('/', async (req, res) => {
  try {
    const list = await ReturnRequest.find().sort({ return_date: -1 });
    res.json(list);
  } catch (err) {
    console.error('❌ Error fetching all return requests:', err);
    res.status(500).json({ error: 'Failed to fetch return requests' });
  }
});

module.exports = router;