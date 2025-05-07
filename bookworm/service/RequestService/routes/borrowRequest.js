const express = require('express');
const axios = require('axios');
const router = express.Router();
const BorrowRequest = require('../models/BorrowRequest');
const RequestStatusHistory = require('../models/RequestStatusHistory');
const { v4: uuidv4 } = require('uuid');
const moment = require('moment');
const nodemailer = require('nodemailer');

/**
 * @swagger
 * /api/borrow:
 *   post:
 *     summary: Gửi yêu cầu mượn sách
 *     tags: [BorrowRequests]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               user_id:
 *                 type: string
 *               book_id:
 *                 type: string
 *               receive_date:
 *                 type: string
 *               request_date:
 *                 type: string
 *               due_date:
 *                 type: string
 *     responses:
 *       201:
 *         description: Tạo yêu cầu thành công
 *       500:
 *         description: Lỗi khi tạo yêu cầu
 */
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

/**
 * @swagger
 * /api/borrow/check/{userId}/{bookId}:
 *   get:
 *     summary: Kiểm tra xem người dùng đã mượn sách chưa
 *     tags: [BorrowRequests]
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: bookId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Trạng thái đã mượn hay chưa
 *       500:
 *         description: Lỗi server
 */
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

/**
 * @swagger
 * /api/borrow/user/{userId}:
 *   get:
 *     summary: Lấy tất cả yêu cầu mượn của người dùng
 *     tags: [BorrowRequests]
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Danh sách yêu cầu mượn
 *       500:
 *         description: Lỗi khi truy vấn
 */
// lấy tất cả yêu cầu mượn sách của ng dùng hiện tại
router.get('/user/:userId', async (req, res) => {
  try {
    const requests = await BorrowRequest.find({ user_id: req.params.userId }).sort({ request_date: -1 });
    res.json(requests);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch borrow requests' });
  }
});

/**
 * @swagger
 * /api/borrow:
 *   get:
 *     summary: Lấy tất cả yêu cầu mượn kèm tên sách và email
 *     tags: [BorrowRequests]
 *     responses:
 *       200:
 *         description: Danh sách yêu cầu mượn đã enrich
 *       500:
 *         description: Lỗi server
 */
// get tất cả BorrowRequest kèm email + tên sách
router.get('/', async (req, res) => {
  try {
    const requests = await BorrowRequest.find().sort({ requestDate: -1 });

    // Lấy danh sách userId và bookId duy nhất
    const userIds = [...new Set(requests.map(r => r.user_id))];
    const bookIds = [...new Set(requests.map(r => r.book_id))];

    // Gọi sang UserService để lấy email
    const userRes = await axios.post('http://localhost:3000/api/users/emails', { userIds });
    const emailMap = userRes.data;

    // Gọi sang BookService để lấy tên sách
    const bookRes = await axios.post('http://localhost:3003/api/books/titles', { bookIds });
    const bookMap = bookRes.data;

    // Gắn email và book title
    const enriched = requests.map(r => ({
      ...r.toObject(),
      userEmail: emailMap[r.user_id] || r.user_id,
      bookTitle: bookMap[r.book_id] || r.book_id,
    }));

    res.json(enriched);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Lỗi khi tải danh sách yêu cầu mượn sách', detail: err.message });
  }
});

/**
 * @swagger
 * /api/borrow/{id}/status:
 *   put:
 *     summary: Cập nhật trạng thái yêu cầu mượn
 *     tags: [BorrowRequests]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               newStatus:
 *                 type: string
 *               changedBy:
 *                 type: string
 *               reason:
 *                 type: string
 *     responses:
 *       200:
 *         description: Cập nhật trạng thái thành công
 *       404:
 *         description: Không tìm thấy yêu cầu
 */
//update trạng thái theo id
router.put('/:id/status', async (req, res) => {
  const { id } = req.params;
  const { newStatus, changedBy, reason } = req.body;

  try {
    const request = await BorrowRequest.findOne({ id: id });
    if (!request) {
      return res.status(404).json({ message: 'Borrow request not found' });
    }

    if (newStatus === 'cancelled' || newStatus === 'rejected') {
      const borrowRequest = await BorrowRequest.findOne({ id: req.params.id });
      if (borrowRequest?.book_copy_id) {
        await axios.put(`http://localhost:3003/api/bookcopies/${borrowRequest.book_copy_id}/status`, {
          newStatus: 'available'
        });
      }
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

/**
 * @swagger
 * /api/borrow/send-overdue-email/{borrowId}:
 *   post:
 *     summary: Gửi email nhắc nhở trễ hạn trả sách
 *     tags: [BorrowRequests]
 *     parameters:
 *       - in: path
 *         name: borrowId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Gửi email thành công
 *       400:
 *         description: Không tìm thấy email người dùng
 *       404:
 *         description: Không tìm thấy yêu cầu mượn
 *       500:
 *         description: Lỗi khi gửi mail
 */
// gửi mail nhắc nhở quá hạn
router.post('/send-overdue-email/:borrowId', async (req, res) => {
  const { borrowId } = req.params;

  try {
    // 1. Tìm phiếu mượn
    const request = await BorrowRequest.findOne({ id: borrowId });
    if (!request) return res.status(404).json({ error: 'Không tìm thấy yêu cầu mượn' });
    console.log(request.user_id);
    // 2. Lấy thông tin sách và người dùng
    const [bookRes, userRes] = await Promise.all([
      axios.get(`http://localhost:3003/api/books/${request.book_id}`),
      axios.get(`http://localhost:3000/api/users/${request.user_id}`)
    ]);

    const bookTitle = bookRes.data?.title || 'Không rõ';
    const email = userRes.data?.email;
    const dueDate = new Date(request.due_date).toLocaleDateString('vi-VN');

    if (!email) return res.status(400).json({ error: 'Không tìm thấy email người dùng' });

    // 3. Cấu hình Nodemailer
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: 'nhomcnpm1@gmail.com', // phải trùng với 'from'
        pass: 'abfk znlx ggfn ycpk', // App password (không phải mật khẩu thường)
      },
    });

    const mailOptions = {
      from: 'Thư viện SOA <nhomcnpm1@gmail.com>',
      to: email,
      subject: `Nhắc nhở trả sách: ${bookTitle}`,
      text: `Chào bạn,

Bạn đã quá hạn trả sách "${bookTitle}". Hạn trả là: ${dueDate}.

Vui lòng đem trả sách sớm để tránh phát sinh phí trễ hạn.

Trân trọng,
Thư viện SOA`,
    };

    // 4. Gửi email
    await transporter.sendMail(mailOptions);

    res.json({ message: 'Đã gửi email nhắc nhở trễ hạn thành công' });
  } catch (error) {
    console.error('Lỗi gửi email:', error);
    res.status(500).json({ message: 'Lỗi server', error: error.message });
  }
});

module.exports = router;