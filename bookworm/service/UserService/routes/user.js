const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const User = require('../models/User'); // đường dẫn tới userSchema của bạn
const router = express.Router();

// Đăng ký
router.post('/signup', async (req, res) => {
    try {
      const { password, role, name, email, phone, avatar } = req.body;
  
      const existingUser = await User.findOne({ email });
      if (existingUser) return res.status(400).json({ message: 'Email already exists' });
  
      const hashedPassword = await bcrypt.hash(password, 10);
  
      const newUser = new User({
        password: hashedPassword,
        role,
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
    const { email, password } = req.body;

    // Tìm người dùng
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'Tài khoản không tồn tại' });
    }

    // So sánh mật khẩu
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Mật khẩu không chính xác' });
    }

    // Tạo JWT
    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET || 'admin123',
      { expiresIn: '1d' } // Token hết hạn sau 1 ngày
    );

    // Thành công – trả thông tin người dùng (hoặc token sau này)
    res.status(200).json({
      message: 'Đăng nhập thành công ' + token,
      token,  // 👈 trả token
      user: {
        id: user._id,
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

// Gửi mã OTP về email
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;

  try {
    // Kiểm tra email có tồn tại không
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'Email không tồn tại' });
    }

    // Tạo mã OTP ngẫu nhiên 6 chữ số
    const otpCode = Math.floor(100000 + Math.random() * 900000).toString();

    // Lưu OTP và thời gian tạo (tuỳ cách bạn muốn lưu - tạm thời response cho đơn giản)
    user.otpCode = otpCode;
    user.otpExpires = Date.now() + 5 * 60 * 1000; // hết hạn sau 5 phút
    await user.save();

    // Gửi email qua Nodemailer
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: 'nhomcnpm1@gmail.com',
        pass: 'abfk znlx ggfn ycpk',
      },
    });

    const mailOptions = {
      from: 'SOA@gmail.com',
      to: email,
      subject: 'OTP Reset Password',
      text: `Mã OTP đặt lại mật khẩu của bạn là: ${otpCode}`,
    };

    await transporter.sendMail(mailOptions);

    res.json({ message: 'OTP đã được gửi đến email của bạn', otp: otpCode});
  } catch (error) {
    res.status(500).json({ message: 'Lỗi server', error: error.message });
  }
});

// đổi mật khẩu
router.post('/reset-password', async (req, res) => {
  const { email, newPassword } = req.body;

  try {
    const user = await User.findOne({ email });

    if (!user) return res.status(404).json({ message: 'Không tìm thấy người dùng' });

    // Mã hóa mật khẩu mới
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Cập nhật mật khẩu và xoá OTP
    user.password = hashedPassword;

    await user.save();

    res.json({ message: 'Đặt lại mật khẩu thành công' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
});

// Lấy danh sách người dùng KHÔNG phải admin hoặc librarian
router.get('/', async (req, res) => {
  try {
    const role = req.query.role;

    // Nếu có truyền role, lọc theo role đó
    const filter = role ? { role } : {};

    const users = await User.find(filter).sort({ timeCreate: -1 });
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: 'Lỗi khi truy vấn người dùng.' });
  }
});

// update thông tin người dùng hiện tại
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Check if the provided id is a valid MongoDB ObjectId
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ error: 'Invalid user ID' });
    }

    const updated = await User.findByIdAndUpdate(
      id,
      { $set: req.body },
      { new: true, runValidators: true }
    );

    if (!updated) return res.status(404).json({ error: 'User not found' });

    res.json({
      message: 'User updated successfully',
      user: updated,
    });
  } catch (err) {
    console.error('Error updating user:', err);
    res.status(500).json({ error: 'Update failed' });
  }
});

// lấy thông tin người dùng
const mongoose = require('mongoose');

router.get('/:id', async (req, res) => {
  try {
    // Kiểm tra định dạng ObjectId hợp lệ
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: 'Invalid user ID' });
    }

    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    res.json(user);
  } catch (err) {
    res.status(500).json({ error: 'Fetch failed' });
  }
});

// delete user
router.delete('/:id', async (req, res) => {
  try {
    const objectId = new mongoose.Types.ObjectId(req.params.id);

    const deleted = await User.findByIdAndDelete(objectId);
    if (!deleted) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ message: 'User deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi khi xoá user', error: err.message });
  }
});

router.post('/emails', async (req, res) => {
  const { userIds } = req.body;
  if (!Array.isArray(userIds)) {
    return res.status(400).json({ error: 'userIds phải là mảng' });
  }

  try {
    const users = await User.find({ _id: { $in: userIds } });
    const map = {};
    users.forEach(u => {
      map[u._id.toString()] = u.email;
    });
    res.json(map);
  } catch (err) {
    res.status(500).json({ error: 'Lỗi server', detail: err.message });
  }
});

module.exports = router;
