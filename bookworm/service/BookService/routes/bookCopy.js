const express = require('express');
const router = express.Router();
const BookCopy = require('../models/BookCopy');

// đếm số lượng sách có sẵn
router.get('/available-count/:bookId', async (req, res) => {
  try {
    const count = await BookCopy.countDocuments({
      book_id: req.params.bookId,
      status: 'available'
    });
    res.json({ availableCount: count });
  } catch (err) {
    res.status(500).json({ error: 'Lỗi khi đếm BookCopy có sẵn.' });
  }
});

// gửi yêu cầu mượn (borrowRequest)
router.put('/borrow/:bookId', async (req, res) => {
    try {
      const { bookId } = req.params;
  
      const copy = await BookCopy.findOneAndUpdate(
        { book_id: bookId, status: 'available' },
        { $set: { status: 'borrowed' } },
        { new: true }
      );
  
      if (!copy) return res.status(404).json({ error: 'No available copy found.' });
  
      res.json({ success: true, copy: {
        id: copy.id,
        book_id: copy.book_id,
        shelf_id: copy.shelf_id,
        status: copy.status
      }});
    } catch (err) {
      res.status(500).json({ error: 'Failed to update BookCopy.' });
    }
});

module.exports = router;