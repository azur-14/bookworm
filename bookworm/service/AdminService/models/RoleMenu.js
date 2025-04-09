const mongoose = require('mongoose');

const roleMenuSchema = new mongoose.Schema({
  role_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Role',
    required: true
  },
  menu_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Menu',
    required: true
  }
}, {
  timestamps: true
});

roleMenuSchema.index({ role_id: 1, menu_id: 1 }, { unique: true }); // PRIMARY KEY (role_id, menu_id)

module.exports = mongoose.model('RoleMenu', roleMenuSchema);
