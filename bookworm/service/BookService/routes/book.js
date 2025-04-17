const express = require('express');
const router = express.Router();
const Book = require('../models/Book');

//lấy danh sách sách (book_M)
router.get('/', async (req, res) => {
  try {
    const books = await Book.find();
    res.json(books);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
});

// POST /api/books - thêm sách mới (book_M)
router.post('/', async (req, res) => {
    try {
      // Đếm số lượng bản ghi hiện có
      const count = await Book.countDocuments();
  
      // Tạo id dạng b001, b002...
      const nextId = 'b' + (count + 1).toString().padLeft(3, '0');
  
      const newBook = new Book({
        id: nextId,
        title: req.body.title,
        author: req.body.author,
        publisher: req.body.publisher,
        publishYear: req.body.publishYear,
        categoryId: req.body.categoryId,
        status: req.body.status,
        timeCreate: new Date()
      });
  
      await newBook.save();
      res.status(201).json({ message: 'Book added successfully', book: newBook });
    } catch (err) {
      res.status(400).json({ message: 'Lỗi khi thêm sách', error: err.message });
    }
  });

module.exports = router;
