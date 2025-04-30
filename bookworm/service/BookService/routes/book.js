const express = require('express');
const router = express.Router();
const Book = require('../models/Book');
const BookCopy = require('../models/BookCopy');

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
      image, title, author, publisher,
      publish_year, price, category_id,
      total_quantity, description
    } = req.body;

    const newBook = new Book({
      id: nextId,
      image,
      title,
      author,
      publisher,
      publish_year,
      price,
      category_id,
      total_quantity,
      available_quantity: total_quantity,
      description,
      timeCreate: new Date()
    });

    await newBook.save();

    const copies = [];
    const timestamp = Date.now();
    for (let i = 0; i < newBook.total_quantity; i++) {
      copies.push(new BookCopy({
        id: nextId + "-BC" + i,
        book_id: newBook.id,
        status: 'available',
        timeCreate: new Date()
      }));
    }
    await BookCopy.insertMany(copies);

    res.status(201).json({ message: 'Tạo sách và bản sao thành công', newBook, copies });
  } catch (err) {
    res.status(400).json({ message: 'Lỗi khi thêm sách', error: err.message });
  }
});

// update book
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updated = await Book.findOneAndUpdate(
      { id },
      req.body,
      { new: true }
    );
    if (!updated) {
      return res.status(404).json({ message: 'Book not found' });
    }
    res.json({ message: 'Book updated', book: updated });
  } catch (err) {
    res.status(400).json({ message: 'Lỗi khi cập nhật sách', error: err.message });
  }
});

// xóa book
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Xoá sách
    const deletedBook = await Book.findOneAndDelete({ id });
    if (!deletedBook) {
      return res.status(404).json({ message: 'Book not found' });
    }

    // Xoá tất cả BookCopy liên quan
    await BookCopy.deleteMany({ book_id: id });

    res.json({ message: 'Book and all related copies deleted successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi khi xoá sách', error: err.message });
  }
});

module.exports = router;
