const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  avatar: { type: String, default: '' }, // URL hoặc base64 string
  email: { type: String, lowercase: true, required: true, unique: true, trim: true},
  password: { type: String, required: true },
  role: { type: String, enum: ['admin', 'librarian', 'customer'], default: 'customer'},
  status: { type: String, enum: ['active', 'block'], default: 'active' },
  name: { type: String, required: true, trim: true},
  phone: { type: String, trim: true},
  timeCreate: { type: Date, default: Date.now}
});

module.exports = mongoose.model('User', userSchema);
