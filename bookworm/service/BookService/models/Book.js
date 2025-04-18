const mongoose = require('mongoose');

const bookSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  image: { type: String, default: '' }, // URL hoặc base64 string
  title: { type: String, required: true },
  author: { type: String, required: true },
  publisher: { type: String, required: true },
  publish_year: { type: Number, required: true },
  price: { type: Number, required: true },
  category_id: { type: String, required: true },
  total_quantity: { type: Number, required: true },
  available_quantity: { type: Number, default: 1 },
  description: { type: String, default: null },
  timeCreate: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Book', bookSchema);
