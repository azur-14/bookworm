const express = require('express');
const router = express.Router();
const SystemConfig = require('../models/SystemConfig');

// lấy danh sách systemconfig
router.get('/', async (req, res) => {
  try {
    const configs = await SystemConfig.find().sort({ id: 1 });
    res.json(configs);
  } catch (err) {
    res.status(500).json({ error: 'Lỗi server: ' + err.message });
  }
});

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
