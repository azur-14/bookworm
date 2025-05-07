const express = require('express');
const router = express.Router();
const Book = require('../models/Book');
const BookCopy = require('../models/BookCopy');
const Shelf = require('../models/Shelves');

/**
 * @swagger
 * /api/books:
 *   get:
 *     summary: Lấy danh sách toàn bộ sách
 *     tags: [Books]
 *     responses:
 *       200:
 *         description: Thành công
 *       500:
 *         description: Lỗi server
 */
// GET /api/books — lấy toàn bộ sách
router.get('/', async (req, res) => {
  try {
    const books = await Book.find();
    res.json(books);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
});

/**
 * @swagger
 * /api/books:
 *   post:
 *     summary: Thêm sách mới và tạo bản sao tương ứng
 *     tags: [Books]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               image:
 *                 type: string
 *               title:
 *                 type: string
 *               author:
 *                 type: string
 *               publisher:
 *                 type: string
 *               publish_year:
 *                 type: number
 *               price:
 *                 type: number
 *               category_id:
 *                 type: string
 *               total_quantity:
 *                 type: number
 *               description:
 *                 type: string
 *     responses:
 *       201:
 *         description: Thêm sách thành công
 *       400:
 *         description: Lỗi khi thêm sách
 */
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

/**
 * @swagger
 * /api/books/{id}:
 *   put:
 *     summary: Cập nhật thông tin sách và số lượng bản sao
 *     tags: [Books]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *     responses:
 *       200:
 *         description: Cập nhật thành công
 *       400:
 *         description: Lỗi khi cập nhật
 *       404:
 *         description: Không tìm thấy sách
 */
// update book
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const newTotal = req.body.total_quantity;

    const existing = await Book.findOne({ id });
    if (!existing) return res.status(404).json({ message: 'Book not found' });

    const quantityDiff = newTotal - existing.total_quantity;

    // Tạo thêm BookCopy nếu tăng số lượng
    if (quantityDiff > 0) {
      const newCopies = [];
      const currentCount = await BookCopy.countDocuments({ book_id: id });

      for (let i = 0; i < quantityDiff; i++) {
        newCopies.push(new BookCopy({
          id: `${id}-BC${currentCount + i}`,
          book_id: id,
          status: 'available',
          timeCreate: new Date(),
        }));
      }
      await BookCopy.insertMany(newCopies);

      // Cập nhật available_quantity thêm số lượng mới
      req.body.available_quantity = existing.available_quantity + quantityDiff;
    }

    // Cập nhật sách
    const updated = await Book.findOneAndUpdate({ id }, req.body, { new: true });
    res.json({ message: 'Book updated', book: updated });

  } catch (err) {
    res.status(400).json({ message: 'Lỗi khi cập nhật sách', error: err.message });
  }
});

/**
 * @swagger
 * /api/books/{id}:
 *   delete:
 *     summary: Xoá sách và tất cả bản sao liên quan, cập nhật lại kệ
 *     tags: [Books]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Xoá thành công
 *       404:
 *         description: Không tìm thấy sách
 *       500:
 *         description: Lỗi khi xoá
 */
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

/**
 * @swagger
 * /api/books/titles:
 *   post:
 *     summary: Lấy tiêu đề sách theo danh sách bookIds
 *     tags: [Books]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               bookIds:
 *                 type: array
 *                 items:
 *                   type: string
 *     responses:
 *       200:
 *         description: Trả về map bookId → title
 *       500:
 *         description: Lỗi khi truy vấn
 */
router.post('/titles', async (req, res) => {
  const { bookIds } = req.body;
  try {
    const books = await Book.find({ id: { $in: bookIds } });
    const map = {};
    books.forEach(b => map[b.id] = b.title);
    res.json(map);
  } catch (err) {
    res.status(500).json({ error: 'Lỗi khi lấy tiêu đề sách', detail: err.message });
  }
});

/**
 * @swagger
 * /api/books/{id}:
 *   get:
 *     summary: Lấy thông tin sách theo ID
 *     tags: [Books]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Trả về thông tin sách
 *       404:
 *         description: Không tìm thấy sách
 */
// Lấy thông tin sách theo ID
router.get('/:id', async (req, res) => {
  try {
    const book = await Book.findOne({ id: req.params.id });
    if (!book) return res.status(404).json({ message: 'Book not found' });
    res.json(book);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
});

module.exports = router;
