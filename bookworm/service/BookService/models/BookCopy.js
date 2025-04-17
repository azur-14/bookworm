const mongoose = require('mongoose');

const bookCopySchema = new mongoose.Schema({
  id: { type: Number, unique: true },
  book_id: { type: String, required: true },
  shelf: { type: String, required: true },
  status: {
    type: String,
    enum: ['available', 'borrowed', 'damaged', 'lost'],
    default: 'available'
  },
  image: { type: String, default: '' },
  timeCreate: { type: Date, default: Date.now }
});

module.exports = mongoose.model('BookCopy', bookCopySchema);
