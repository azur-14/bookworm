// routes/requestStatusHistory.js
const express = require('express');
const router = express.Router();
const RequestStatusHistory = require('../models/RequestStatusHistory');
const ReturnRequest = require('../models/ReturnRequest');

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
