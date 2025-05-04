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
      start_time: r.start_time,
      end_time: r.end_time,
      request_time: r.request_time,
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
    const {
      user_id,
      room_id,
      slots, // danh sách các slot thời gian [{ start_time, end_time }]
      purpose,
      request_time
    } = req.body;

    if (!Array.isArray(slots) || slots.length === 0) {
      return res.status(400).json({ message: 'Danh sách slot không hợp lệ' });
    }

    // B1: Sắp xếp slot theo thời gian bắt đầu
    const sortedSlots = slots.map(s => ({
      start: moment(s.start_time).add(7, 'hours'),
      end: moment(s.end_time).add(7, 'hours')
    })).sort((a, b) => a.start - b.start);

    // B2: Gom các slot liên tiếp
    const mergedSlots = [];
    let current = sortedSlots[0];

    for (let i = 1; i < sortedSlots.length; i++) {
      const next = sortedSlots[i];
      if (current.end.isSame(next.start)) {
        current.end = next.end; // gộp lại
      } else {
        mergedSlots.push(current);
        current = next;
      }
    }
    mergedSlots.push(current); // thêm phần cuối

    const count = await RoomBookingRequest.countDocuments();
    const createdRequests = [];

    // B3: Tạo từng yêu cầu từ nhóm đã gộp
    for (let i = 0; i < mergedSlots.length; i++) {
      const id = 'RB' + String(count + i + 1).padStart(3, '0') + '-' + room_id;

      const request = new RoomBookingRequest({
        id,
        user_id,
        room_id,
        start_time: mergedSlots[i].start.toDate(),
        end_time: mergedSlots[i].end.toDate(),
        purpose,
        status: 'pending',
        request_time: moment(request_time).add(7, 'hours').toDate()
      });

      await request.save();
      createdRequests.push(request);
    }

    res.status(201).json({ message: 'Đặt phòng thành công', requests: createdRequests });

  } catch (err) {
    res.status(500).json({ error: 'Lỗi khi tạo yêu cầu', detail: err.message });
  }
});

// cập nhật trạng thái phòng
router.put('/:id', async (req, res) => {
  try {
    const { status } = req.body;
    if (!['approved', 'rejected', 'cancelled'].includes(status)) {
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
