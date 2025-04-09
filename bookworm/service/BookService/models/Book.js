const mongoose = require('mongoose');

const bookSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  title: { type: String, required: true },
  author: { type: String },
  publisher: { type: String },
  publish_year: { type: Number },
  category: { type: String },
  status: { type: String, enum: ['available', 'borrowed', 'damaged', 'lost'], default: 'available' },
  quantity: { type: Number, default: 1 },
  timeCreate: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Book', bookSchema);
