const mongoose = require('mongoose');

const roomSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  status: { type: String, enum: ['available', 'occupied', 'locked'], default: 'available' }
});

module.exports = mongoose.model('Room', roomSchema);
