const mongoose = require('mongoose');

const BillSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  borrowRequestId: { type: String, required: true },
  type: { type: String, enum: ['book', 'room'], required: true },
  overdueDays: { type: Number, required: false },
  overdueFee: { type: Number, required: false },
  damageFee: { type: Number, required: false },
  totalFee: { type: Number, required: true },
  amountReceived: { type: Number, required: true },
  changeGiven: { type: Number, required: true },
  date: { type: Date, required: true }
}, {
  timestamps: true // tự động thêm createdAt và updatedAt
});

module.exports = mongoose.model('Bill', BillSchema);