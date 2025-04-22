const mongoose = require('mongoose');

const borrowRequestSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  user_id: { type: String, required: true },
  book_id: { type: String, required: true },
  book_copy_id: { type: Number },
  status: { type: String, enum: ['pending', 'approved', 'rejected', 'cancelled'], default: 'pending' },
  request_date: { type: Date, default: Date.now },
  receive_date: { type: Date },
  due_date: { type: Date },
  return_date: { type: Date }
});

module.exports = mongoose.model('BorrowRequest', borrowRequestSchema);
