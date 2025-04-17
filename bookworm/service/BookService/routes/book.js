const express = require('express');
const router = express.Router();
const Book = require('../models/Book');

// GET /api/books — lấy toàn bộ sách
router.get('/', async (req, res) => {
  try {
    const books = await Book.find();
    res.json(books);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
});

// POST /api/books — thêm sách mới
router.post('/', async (req, res) => {
  try {
    // Đếm số sách hiện có để sinh id dạng b001, b002…
    const count = await Book.countDocuments();
    const nextId = 'b' + String(count + 1).padStart(3, '0');

    const {
      image = '',
      title,
      author,
      publisher,
      publish_year,
      category_id,
      total_quantity,
      available_quantity,
      description = null
    } = req.body;

    const newBook = new Book({
      id: nextId,
      image,
      title,
      author,
      publisher,
      publish_year,
      category_id,
      total_quantity,
      available_quantity: available_quantity ?? total_quantity,
      description,
      timeCreate: new Date()
    });

    await newBook.save();
    res.status(201).json({ message: 'Book added successfully', book: newBook });
  } catch (err) {
    res.status(400).json({ message: 'Lỗi khi thêm sách', error: err.message });
  }
});

module.exports = router;
