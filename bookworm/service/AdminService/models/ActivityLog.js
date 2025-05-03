const mongoose = require('mongoose');

const activityLogSchema = new mongoose.Schema({
  adminId: { type: String, required: true }, //người thực hiện hđ
  actionType: { type: String, enum: ['CREATE', 'UPDATE', 'DELETE', 'APPROVE', 'REJECT', 'LOGIN', 'LOGOUT'], required: true },
  targetType: { type: String, required: true },
  targetId: { type: String, required: true }, //người bị tác động
  description: { type: String, default: '' }, //Mô tả chi tiết hành động (VD: "Updated user email from A to B").
  timestamp: { type: Date, default: Date.now },
});

module.exports = mongoose.model('ActivityLog', activityLogSchema);
