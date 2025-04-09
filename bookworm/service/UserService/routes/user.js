const express = require('express');
const bcrypt = require('bcrypt');
const User = require('../models/User'); // đường dẫn tới userSchema của bạn
const router = express.Router();

// Đăng ký
router.post('/signup', async (req, res) => {
    try {
      const { username, password, name, email, phone, avatar } = req.body;
  
      const existingUser = await User.findOne({ username });
      if (existingUser) return res.status(400).json({ message: 'Username already exists' });
  
      const hashedPassword = await bcrypt.hash(password, 10);
  
      const newUser = new User({
        username,
        password: hashedPassword,
        name,
        email,
        phone,
        avatar  // base64 string
      });
  
      await newUser.save();
      res.status(201).json({ message: 'User registered successfully!' });
    } catch (err) {
      res.status(500).json({ message: 'Server error', error: err.message });
    }
});

// Đăng nhập
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    // Tìm người dùng
    const user = await User.findOne({ username });
    if (!user) {
      return res.status(401).json({ message: 'Tài khoản không tồn tại' });
    }

    // So sánh mật khẩu
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Mật khẩu không chính xác' });
    }

    // Thành công – trả thông tin người dùng (hoặc token sau này)
    res.status(200).json({
      message: 'Đăng nhập thành công',
      user: {
        id: user._id,
        username: user.username,
        name: user.name,
        role: user.role,
        avatar: user.avatar,
        email: user.email,
        phone: user.phone,
        status: user.status
      }
    });
  } catch (error) {
    res.status(500).json({ message: 'Lỗi server', error: error.message });
  }
});

  
module.exports = router;
