const mongoose = require('mongoose');

const systemConfigSchema = new mongoose.Schema({
  id: { type: Number, unique: true },
  config_name: { type: String, required: true },
  config_value: { type: String, required: true }
});

module.exports = mongoose.model('SystemConfig', systemConfigSchema);
