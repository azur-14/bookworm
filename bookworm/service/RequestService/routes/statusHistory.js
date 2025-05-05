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

router.get('/:requestId', async (req, res) => {
  try {
    const requestId = req.params.requestId;

    // 1. Lấy các log theo chính requestId
    const directHistories = await RequestStatusHistory.find({ requestId }).sort({ changeTime: -1 });

    // 2. Tìm returnRequest liên quan
    const relatedReturn = await ReturnRequest.findOne({ borrowRequestId: requestId });

    let returnHistories = [];
    if (relatedReturn) {
      returnHistories = await RequestStatusHistory.find({ requestId: relatedReturn._id.toString() }).sort({ changeTime: -1 });
    }

    // 3. Gộp hai mảng
    const allHistories = [...directHistories, ...returnHistories];
    allHistories.sort((a, b) => b.changeTime - a.changeTime);

    res.json(allHistories);
  } catch (err) {
    console.error('❌ Lỗi khi lấy lịch sử:', err);
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
});

module.exports = router;
