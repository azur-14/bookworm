const mongoose = require('mongoose');

const roomBookingRequestSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  user_id: { type: String, required: true },
  room_id: { type: String, required: true },
  start_time: { type: Date, required: true },
  end_time: { type: Date, required: true },
  status: {
    type: String,
    enum: ['pending', 'approved', 'paid', 'using', 'finished', 'rejected', 'cancelled'],
    default: 'pending'
  },
  purpose: { type: String, required: true },
  request_time: { type: Date, required: true },
  price_per_hour: { type: Number, required: true }  // thêm trường này
});

module.exports = mongoose.model('RoomBookingRequest', roomBookingRequestSchema);
