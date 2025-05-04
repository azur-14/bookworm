const express = require('express');
const router = express.Router();
const ActivityLog = require('../models/ActivityLog');

router.post('/', async (req, res) => {
  try {
    const newLog = new ActivityLog(req.body);
    await newLog.save();
    res.status(201).json(newLog);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
