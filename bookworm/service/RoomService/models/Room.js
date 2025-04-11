const mongoose = require('mongoose');

const roomSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  floor: { type: String, required: true },
  capacity: { type: Number, required: true },
  fee: { type: Number, required: true }
});

module.exports = mongoose.model('Room', roomSchema);
