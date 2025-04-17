const mongoose = require('mongoose');

const borrowRequestSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  book_copy_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Book', required: true },
  status: { type: String, enum: ['pending', 'approved', 'rejected', 'cancelled'], default: 'pending' },
  request_date: { type: Date, default: Date.now },
  due_date: { type: Date },
  return_date: { type: Date }
});

module.exports = mongoose.model('BorrowRequest', borrowRequestSchema);
