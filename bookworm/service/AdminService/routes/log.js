const express = require('express');
const router = express.Router();
const ActivityLog = require('../models/ActivityLog');

/**
 * @swagger
 * /api/logs:
 *   post:
 *     summary: Ghi lại một log hoạt động
 *     tags: [ActivityLogs]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               adminId:
 *                 type: string
 *               actionType:
 *                 type: string
 *               targetType:
 *                 type: string
 *               targetId:
 *                 type: string
 *               description:
 *                 type: string
 *     responses:
 *       201:
 *         description: Ghi log thành công
 *       400:
 *         description: Lỗi dữ liệu
 */
router.post('/', async (req, res) => {
  try {
    const newLog = new ActivityLog(req.body);
    await newLog.save();
    res.status(201).json(newLog);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

/**
 * @swagger
 * /api/logs:
 *   get:
 *     summary: Lấy danh sách toàn bộ hoạt động
 *     tags: [ActivityLogs]
 *     responses:
 *       200:
 *         description: Danh sách hoạt động được trả về
 *       500:
 *         description: Lỗi khi lấy dữ liệu
 */
router.get('/', async (req, res) => {
  try {
    const logs = await ActivityLog.find().sort({ timestamp: -1 });
    res.json(logs);
  } catch (err) {
    console.error('Error fetching activity logs:', err);
    res.status(500).json({ error: 'Failed to fetch activity logs' });
  }
});


module.exports = router;
