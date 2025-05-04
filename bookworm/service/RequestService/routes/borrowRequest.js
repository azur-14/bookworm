const express = require('express');
const axios = require('axios');
const router = express.Router();
const BorrowRequest = require('../models/BorrowRequest');
const RequestStatusHistory = require('../models/RequestStatusHistory');
const { v4: uuidv4 } = require('uuid');
const moment = require('moment');

// gửi yêu cầu mượn sách
router.post('/', async (req, res) => {
  try {
    const { user_id, book_id, receive_date, request_date, due_date } = req.body;

    // 1. Tạo BorrowRequest (chưa update BookCopy)
    const request = new BorrowRequest({
      id: uuidv4(),
      user_id,
      book_id: book_id,
      receive_date: moment(receive_date).add(7, 'hours'),
      request_date: moment(request_date).add(7, 'hours'),
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

// get tất cả BorrowRequest
router.get('/', async (req, res) => {
  try {
    const requests = await BorrowRequest.find().sort({ requestDate: -1 });
    res.json(requests);
  } catch (err) {
    res.status(500).json({ error: 'Lỗi khi tải danh sách yêu cầu mượn sách', detail: err.message });
  }
});

//update trạng thái theo id
router.put('/:id/status', async (req, res) => {
  const { id } = req.params;
  const { newStatus, changedBy, reason } = req.body;

  try {
    const request = await BorrowRequest.findOne({ id: id });
    if (!request) {
      return res.status(404).json({ message: 'Borrow request not found' });
    }

    const oldStatus = request.status;
    request.status = newStatus;
    await request.save();

    const history = new RequestStatusHistory({
      requestId: id,
      requestType: 'borrow',
      oldStatus,
      newStatus,
      changedBy,
      reason: reason || ''
    });
    await history.save();

    res.json({ message: 'Status updated and history recorded' });
  } catch (err) {
    console.error('Status update error:', err);
    res.status(500).json({ message: 'Internal server error' });
  }
});

module.exports = router;