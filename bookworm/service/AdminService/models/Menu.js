const mongoose = require('mongoose');

const menuSchema = new mongoose.Schema({
  id: { type: Number, required: true, unique: true },
  name: { type: String, required: true },
  icon: { type: String },
  route: { type: String },
  parent_id: { type: Number, default: null },
  sort_order: { type: Number, default: 0 },
  is_active: { type: Boolean, default: true }
});

module.exports = mongoose.model('Menu', menuSchema);
