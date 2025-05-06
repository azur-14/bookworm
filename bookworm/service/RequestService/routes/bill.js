const express = require('express');
const router = express.Router();
const Bill = require('../models/Bill');

/**
 * @swagger
 * /api/bill:
 *   get:
 *     summary: Lấy danh sách tất cả các hóa đơn
 *     tags: [Bills]
 *     responses:
 *       200:
 *         description: Danh sách hóa đơn
 *       500:
 *         description: Lỗi khi truy vấn hóa đơn
 */
// lấy danh sách tất cả các hóa đơn
router.get('/', async (req, res) => {
  try {
    const bills = await Bill.find().sort({ date: -1 });
    res.json(bills);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch bills', details: err.message });
  }
});

/**
 * @swagger
 * /api/bill:
 *   post:
 *     summary: Tạo mới một hóa đơn
 *     tags: [Bills]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               borrowRequestId:
 *                 type: string
 *               type:
 *                 type: string
 *                 enum: [book, room]
 *               overdueDays:
 *                 type: number
 *               overdueFee:
 *                 type: number
 *               damageFee:
 *                 type: number
 *               totalFee:
 *                 type: number
 *               amountReceived:
 *                 type: number
 *               changeGiven:
 *                 type: number
 *               date:
 *                 type: string
 *                 format: date-time
 *     responses:
 *       201:
 *         description: Hóa đơn được tạo thành công
 *       400:
 *         description: Dữ liệu không hợp lệ hoặc lỗi khi tạo
 */
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
