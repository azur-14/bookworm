// routes/requestStatusHistory.js
const express = require('express');
const router = express.Router();
const RequestStatusHistory = require('../models/RequestStatusHistory');
const ReturnRequest = require('../models/ReturnRequest');

/**
 * @swagger
 * /api/request-status-history:
 *   post:
 *     summary: Lưu lịch sử thay đổi trạng thái yêu cầu
 *     tags: [RequestStatusHistory]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               requestId:
 *                 type: string
 *               requestType:
 *                 type: string
 *               oldStatus:
 *                 type: string
 *               newStatus:
 *                 type: string
 *               changedBy:
 *                 type: string
 *               reason:
 *                 type: string
 *     responses:
 *       201:
 *         description: Lưu thành công
 *       500:
 *         description: Lỗi server
 */
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

/**
 * @swagger
 * /api/request-status-history/{requestId}:
 *   get:
 *     summary: Lấy lịch sử thay đổi trạng thái theo requestId (bao gồm borrow & return nếu liên kết)
 *     tags: [RequestStatusHistory]
 *     parameters:
 *       - in: path
 *         name: requestId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID yêu cầu (borrow hoặc return)
 *     responses:
 *       200:
 *         description: Danh sách lịch sử trạng thái
 *       500:
 *         description: Lỗi server
 */
router.get('/:requestId', async (req, res) => {
  try {
    const requestId = req.params.requestId;

    // Tìm lịch sử trực tiếp của requestId
    const directHistories = await RequestStatusHistory.find({ requestId }).sort({ changeTime: -1 });

    // Kiểm tra xem đây có phải là borrowRequestId không (nếu có ReturnRequest liên kết)
    const relatedReturn = await ReturnRequest.findOne({ borrowRequestId: requestId });

    let returnHistories = [];
    if (relatedReturn) {
      // Nếu là borrowRequest, lấy thêm lịch sử của ReturnRequest liên kết
      returnHistories = await RequestStatusHistory.find({ requestId: relatedReturn._id.toString() }).sort({ changeTime: -1 });
    }

    // Gộp và sắp xếp toàn bộ
    const allHistories = [...directHistories, ...returnHistories];
    allHistories.sort((a, b) => b.changeTime - a.changeTime);

    res.json(allHistories);
  } catch (err) {
    console.error('❌ Lỗi khi lấy lịch sử:', err);
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
});

module.exports = router;
