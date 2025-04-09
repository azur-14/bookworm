const mongoose = require('mongoose');

const roomBookingRequestSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  room_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Room', required: true },
  start_time: { type: Date, required: true },
  end_time: { type: Date, required: true },
  status: { type: String, enum: ['pending', 'approved', 'rejected', 'cancelled'], default: 'pending' }
});

module.exports = mongoose.model('RoomBookingRequest', roomBookingRequestSchema);
