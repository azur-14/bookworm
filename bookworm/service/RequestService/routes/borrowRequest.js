const express = require('express');
const axios = require('axios');
const router = express.Router();
const BorrowRequest = require('../models/BorrowRequest');
const { v4: uuidv4 } = require('uuid');

// gửi yêu cầu mượn sách
router.post('/', async (req, res) => {
  try {
    const { user_id, book_id, due_date } = req.body;

    // 1. Tạo BorrowRequest (chưa update BookCopy)
    const request = new BorrowRequest({
      id: uuidv4(),
      user_id,
      book_id: book_id,
      book_copy_id: null, // tạm null, sẽ cập nhật sau
      book_id,
      due_date
    });

    await request.save();

    // 2. Gọi sang BookService để update 1 bản sao thành 'borrowed'
    const bookServiceURL = `http://localhost:3003/api/bookcopies/borrow/${book_id}`;
    const response = await axios.put(bookServiceURL);

    const copy = response.data.copy;
    if (!copy || !copy.id) {
      // Nếu thất bại → rollback request nếu cần
      await BorrowRequest.deleteOne({ id: request.id }); // hoặc cập nhật trạng thái rejected
      return res.status(404).json({ error: 'No available copy to assign.' });
    }

    // 3. Cập nhật BorrowRequest với `book_copy_id`
    request.book_copy_id = copy.id;
    await request.save();

    res.status(201).json({ message: 'Borrow request created.', copy, request });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Lỗi khi tạo yêu cầu mượn sách.' });
  }
});

//check đã mượn sách này chưa
router.get('/check/:userId/:bookId', async (req, res) => {
  const { userId, bookId } = req.params;
  try {
    const existing = await BorrowRequest.findOne({
      user_id: userId,
      book_id: bookId,
      status: { $in: ['pending', 'approved'] }
    });

    res.json({ alreadyBorrowed: !!existing });
  } catch (e) {
    res.status(500).json({ error: 'Server error' });
  }
});

// lấy tất cả yêu cầu mượn sách của ng dùng hiện tại
router.get('/user/:userId', async (req, res) => {
  try {
    const requests = await BorrowRequest.find({ user_id: req.params.userId }).sort({ request_date: -1 });
    res.json(requests);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch borrow requests' });
  }
});

module.exports = router;