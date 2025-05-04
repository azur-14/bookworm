const express = require('express');
const router = express.Router();
const Bill = require('../models/Bill');

// lấy danh sách tất cả các hóa đơn
router.get('/', async (req, res) => {
  try {
    const bills = await Bill.find().sort({ date: -1 });
    res.json(bills);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch bills', details: err.message });
  }
});

// tạo mới một hóa đơn
router.post('/', async (req, res) => {
  try {
    const bill = new Bill(req.body);
    await bill.save();
    res.status(201).json(bill);
  } catch (err) {
    res.status(400).json({ error: 'Failed to create bill', details: err.message });
  }
});

module.exports = router;
