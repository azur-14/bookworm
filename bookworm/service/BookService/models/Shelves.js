const mongoose = require('mongoose');

const shelfSchema = new mongoose.Schema({
  id: { type: Number, unique: true },
  name: { type: String, required: true },
  description: { type: String },
  capacitylimit: { type: Number, default: 0 }, // sức chứa tối đa
  capacity: { type: Number, default: 0 },      // số lượng sách hiện tại
  timeCreate: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Shelf', shelfSchema);
