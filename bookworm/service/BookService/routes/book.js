const express = require('express');
const router = express.Router();
const Book = require('../models/Book');
const BookCopy = require('../models/BookCopy');
const Shelf = require('../models/Shelves');

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

    // 1. Lấy tất cả BookCopy cần xoá để biết kệ nào bị ảnh hưởng
    const copies = await BookCopy.find({ book_id: id });

    // 2. Xoá sách
    const deletedBook = await Book.findOneAndDelete({ id });
    if (!deletedBook) {
      return res.status(404).json({ message: 'Book not found' });
    }

    // 3. Xoá tất cả bản sao
    await BookCopy.deleteMany({ book_id: id });

    // 4. Cập nhật lại capacity của các shelf liên quan
    const shelfMap = new Map();

    // Đếm số bản sao bị xóa trên mỗi shelf
    copies.forEach(copy => {
      if (copy.shelf_id != null) {
        const sid = copy.shelf_id;
        shelfMap.set(sid, (shelfMap.get(sid) || 0) + 1);
      }
    });

    // Trừ capacity tương ứng trên từng shelf
    for (const [shelfId, reduceCount] of shelfMap.entries()) {
      await Shelf.updateOne({ id: shelfId }, {
        $inc: { capacity: -reduceCount }
      });
    }

    res.json({ message: 'Book, copies deleted & shelf capacity updated' });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi khi xoá sách', error: err.message });
  }
});

module.exports = router;
