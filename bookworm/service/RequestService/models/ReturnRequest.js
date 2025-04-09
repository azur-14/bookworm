const mongoose = require('mongoose');

const returnRequestSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  borrow_request_id: { type: mongoose.Schema.Types.ObjectId, ref: 'BorrowRequest', required: true },
  return_date: { type: Date, default: Date.now },
  status: { type: String, enum: ['processing', 'completed'], default: 'processing' }
});

module.exports = mongoose.model('ReturnRequest', returnRequestSchema);
