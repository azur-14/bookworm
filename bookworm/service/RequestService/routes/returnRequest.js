const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const ReturnRequest = require('../models/ReturnRequest');
const BorrowRequest = require('../models/BorrowRequest');
const StatusHistory = require('../models/RequestStatusHistory');

/**
 * @swagger
 * /api/return/user/{userId}:
 *   get:
 *     summary: Lấy kết quả mượn sách (return) của người dùng
 *     tags: [ReturnRequests]
 *     parameters:
 *       - in: path
 *         name: userId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID người dùng
 *     responses:
 *       200:
 *         description: Danh sách yêu cầu trả sách
 *       500:
 *         description: Lỗi server
 */
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

/**
 * @swagger
 * /api/return:
 *   get:
 *     summary: Lấy tất cả yêu cầu trả sách
 *     tags: [ReturnRequests]
 *     responses:
 *       200:
 *         description: Thành công
 *       500:
 *         description: Lỗi server
 */
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

/**
 * @swagger
 * /api/return:
 *   post:
 *     summary: Tạo yêu cầu trả sách mới
 *     tags: [ReturnRequests]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               borrowRequestId:
 *                 type: string
 *               status:
 *                 type: string
 *     responses:
 *       201:
 *         description: Tạo thành công
 *       500:
 *         description: Lỗi khi tạo yêu cầu
 */
// Tạo returnRequest mới khi đã nhận sách
router.post('/', async (req, res) => {
  try {
    const { borrowRequestId, status } = req.body;
    const newRequest = new ReturnRequest({
      id: `r_${uuidv4()}`,
      borrow_request_id: borrowRequestId,
      status: status || 'processing',
    });

    await newRequest.save();
    res.status(201).json(newRequest);
  } catch (err) {
    res.status(500).json({ message: 'Error creating return request', error: err.message });
  }
});

/**
 * @swagger
 * /api/return/{id}/status:
 *   put:
 *     summary: Cập nhật trạng thái yêu cầu trả sách và ghi lịch sử
 *     tags: [ReturnRequests]
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
 *               condition:
 *                 type: string
 *               returnImageBase64:
 *                 type: string
 *     responses:
 *       200:
 *         description: Cập nhật thành công
 *       404:
 *         description: Không tìm thấy yêu cầu
 *       500:
 *         description: Lỗi server
 */
// Cập nhật trạng thái ReturnRequest và lưu lịch sử
router.put('/:id/status', async (req, res) => {
  const { newStatus, changedBy, reason, condition, returnImageBase64 } = req.body;

  try {
    const ret = await ReturnRequest.findOne({ id: req.params.id });
    if (!ret) return res.status(404).json({ message: 'ReturnRequest not found' });

    const oldStatus = ret.status;
    ret.status = newStatus;
    if (condition !== undefined) ret.condition = condition;
    if (returnImageBase64 !== undefined) ret.return_image = returnImageBase64;
    ret.return_date = new Date();
    await ret.save();

    const history = new StatusHistory({
      requestId: ret.id,
      requestType: 'return',
      oldStatus: oldStatus,
      newStatus: newStatus,
      changedBy: changedBy,
      changeTime: new Date(),
      reason: reason || '',
    });
    await history.save();

    res.status(200).json(ret);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error updating return request' });
  }
});

module.exports = router;