const mongoose = require('mongoose');

const returnRequestSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  borrow_request_id: { type: String, required: true },
  return_date: { type: Date, default: Date.now },
  status: { type: String, enum: ['processing', 'completed', 'overdue'], default: 'processing' },
  return_image: { type: String, default: '' }, // URL hoặc base64 string
  condition:  { type: String, default: '' },
  create_at: { type: Date, default: Date.now }
});

module.exports = mongoose.model('ReturnRequest', returnRequestSchema);
