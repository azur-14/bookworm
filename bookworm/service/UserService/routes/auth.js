const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // "Bearer <token>"

  if (!token) return res.status(401).json({ message: 'Không có token' });

  jwt.verify(token, process.env.JWT_SECRET || 'admin123', (err, user) => {
    if (err) return res.status(403).json({ message: 'Token không hợp lệ' });
    req.user = user; // { userId, role }
    next();
  });
};

const requireAdminOrLibrarian = (req, res, next) => {
  if (req.user.role === 'admin' || req.user.role === 'librarian') {
    next();
  } else {
    res.status(403).json({ message: 'Không có quyền truy cập' });
  }
};

module.exports = { verifyToken, requireAdminOrLibrarian };
