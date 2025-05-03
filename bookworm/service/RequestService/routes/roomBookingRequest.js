const express = require('express');
const router = express.Router();
const moment = require('moment');
const RoomBookingRequest = require('../models/RoomBookingRequest');

// lấy tất cả yêu cầu đặt phòng
router.get('/', async (req, res) => {
  try {
    const requests = await RoomBookingRequest.find()
      .populate('user_id')
      .populate('room_id');

    const result = requests.map(r => ({
      ...r.toObject(),
      start_time: moment(r.start_time).subtract(7, 'hours').toDate(),
      end_time: moment(r.end_time).subtract(7, 'hours').toDate(),
      request_time: moment(r.request_time).add(7, 'hours').toDate(),
    }));
    
    res.status(200).json(result);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
});

// Lấy tất cả RoomBookingRequest của người dùng
router.get('/user/:userId', async (req, res) => {
  try {
    const requests = await RoomBookingRequest.find({ user_id: req.params.userId });
    res.json(requests);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch booking requests' });
  }
});

// Thêm yêu cầu đặt phòng
router.post('/', async (req, res) => {
  try {
    // Đếm số yc hiện có để sinh id dạng b001, b002…
    const count = await RoomBookingRequest.countDocuments();
    const nextId = 'RB' + String(count + 1).padStart(3, '0');

    const {
      user_id,
      room_id,
      start_time,
      end_time,
      status,
      purpose,
      request_time
    } = req.body;

    const newRequest = new RoomBookingRequest({
      id: nextId + "-" + room_id,
      user_id,
      room_id,
      start_time: moment(start_time).add(7, 'hours').toDate(),
      end_time: moment(end_time).add(7, 'hours').toDate(),
      status,
      purpose,
      request_time: moment(request_time).add(7, 'hours').toDate(),
    });

    await newRequest.save();
    res.status(201).json({ message: 'Đặt phòng thành công', request: newRequest });
  } catch (err) {
    res.status(500).json({ error: 'Lỗi khi tạo yêu cầu', detail: err.message });
  }
});

// cập nhật trạng thái phòng
router.put('/:id', async (req, res) => {
  try {
    const { status } = req.body;
    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ message: 'Trạng thái không hợp lệ' });
    }

    const updated = await RoomBookingRequest.findOneAndUpdate(
      { id: req.params.id },
      { status: status },
      { new: true }
    );

    if (!updated) {
      return res.status(404).json({ message: 'Không tìm thấy yêu cầu' });
    }

    res.status(200).json({ message: 'Cập nhật trạng thái thành công', request: updated });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
});

module.exports = router;
