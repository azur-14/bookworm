const mongoose = require('mongoose');

const returnRequestSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  borrow_request_id: { type: mongoose.Schema.Types.ObjectId, ref: 'BorrowRequest', required: true },
  return_date: { type: Date, default: Date.now },
  status: { type: String, enum: ['processing', 'completed', 'overdue'], default: 'processing' },
  return_image: { type: String, default: '' }, // URL hoặc base64 string
});

module.exports = mongoose.model('ReturnRequest', returnRequestSchema);
