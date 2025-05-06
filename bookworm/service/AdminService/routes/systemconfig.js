const express = require('express');
const router = express.Router();
const SystemConfig = require('../models/SystemConfig');

/**
 * @swagger
 * /api/systemconfig:
 *   get:
 *     summary: Lấy danh sách toàn bộ cấu hình hệ thống
 *     tags: [SystemConfig]
 *     responses:
 *       200:
 *         description: Danh sách cấu hình được trả về
 *       500:
 *         description: Lỗi server
 */
// lấy danh sách systemconfig
router.get('/', async (req, res) => {
  try {
    const configs = await SystemConfig.find().sort({ id: 1 });
    res.json(configs);
  } catch (err) {
    res.status(500).json({ error: 'Lỗi server: ' + err.message });
  }
});

/**
 * @swagger
 * /api/systemconfig/{id}:
 *   get:
 *     summary: Lấy cấu hình hệ thống theo ID
 *     tags: [SystemConfig]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Trả về cấu hình tương ứng
 *       404:
 *         description: Không tìm thấy cấu hình
 *       500:
 *         description: Lỗi server
 */
// cập nhật cấu hình
router.put('/:id', async (req, res) => {
  try {
    const { config_value } = req.body;
    const config = await SystemConfig.findOneAndUpdate(
      { id: parseInt(req.params.id) },
      { config_value },
      { new: true }
    );
    if (!config) return res.status(404).json({ message: 'Config not found' });
    res.json(config);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

/**
 * @swagger
 * /api/systemconfig/{id}:
 *   put:
 *     summary: Cập nhật giá trị cấu hình theo ID
 *     tags: [SystemConfig]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               config_value:
 *                 type: string
 *     responses:
 *       200:
 *         description: Cấu hình đã được cập nhật
 *       404:
 *         description: Không tìm thấy cấu hình
 *       500:
 *         description: Lỗi server
 */
router.get('/:id', async (req, res) => {
    try {
      const config = await SystemConfig.findOne({ id: parseInt(req.params.id) });
      if (!config) return res.status(404).json({ message: 'Config not found' });
      res.json(config);
    } catch (err) {
      res.status(500).json({ message: 'Server error', error: err.message });
    }
});

module.exports = router;
