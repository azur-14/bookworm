const mongoose = require('mongoose');

const RequestStatusHistorySchema = new mongoose.Schema({
  requestId: { type: String, required: true },
  requestType: { type: String, enum: ['borrow', 'room', 'return'], required: true },
  oldStatus: { type: String, required: true },
  newStatus: { type: String, required: true },
  changeTime: { type: Date, default: Date.now },
  changedBy: { type: String, required: true }, //id
  reason: { type: String, default: '' }
});

module.exports = mongoose.model('RequestStatusHistory', RequestStatusHistorySchema);
