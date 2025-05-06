const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const BookCopy = require('../models/BookCopy');
const Shelf = require('../models/Shelves');

/**
 * @swagger
 * /api/bookcopies/available-count/{bookId}:
 *   get:
 *     summary: Đếm số lượng BookCopy có sẵn theo bookId
 *     tags: [BookCopies]
 *     parameters:
 *       - in: path
 *         name: bookId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Trả về số lượng có sẵn
 *       500:
 *         description: Lỗi server
 */
// đếm số lượng sách có sẵn
router.get('/available-count/:bookId', async (req, res) => {
  try {
    const count = await BookCopy.countDocuments({
      book_id: req.params.bookId,
      status: 'available'
    });
    res.json({ availableCount: count });
  } catch (err) {
    res.status(500).json({ error: 'Lỗi khi đếm BookCopy có sẵn.' });
  }
});


/**
 * @swagger
 * /api/bookcopies/borrow/{bookId}:
 *   put:
 *     summary: Đánh dấu một bản sao của sách là đang được mượn
 *     tags: [BookCopies]
 *     parameters:
 *       - in: path
 *         name: bookId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Mượn thành công
 *       404:
 *         description: Không còn bản sao khả dụng
 *       500:
 *         description: Lỗi server
 */
// gửi yêu cầu mượn (borrowRequest)
router.put('/borrow/:bookId', async (req, res) => {
    try {
      const { bookId } = req.params;
  
      const copy = await BookCopy.findOneAndUpdate(
        { book_id: bookId, status: 'available' },
        { $set: { status: 'borrowed' } },
        { new: true }
      );
  
      if (!copy) return res.status(404).json({ error: 'No available copy found.' });
  
      res.json({ success: true, copy: {
        id: copy.id,
        book_id: copy.book_id,
        shelf_id: copy.shelf_id,
        status: copy.status
      }});
    } catch (err) {
      res.status(500).json({ error: 'Failed to update BookCopy.' });
    }
});

/**
 * @swagger
 * /api/bookcopies:
 *   get:
 *     summary: Lấy danh sách tất cả BookCopy
 *     tags: [BookCopies]
 *     responses:
 *       200:
 *         description: Danh sách BookCopy
 *       500:
 *         description: Lỗi server
 */
// lấy danh sách tất cả BookItem
router.get('/', async (req, res) => {
  try {
    const items = await BookCopy.find();
    res.json(items);
  } catch (err) {
    console.error('❌ Error fetching BookItems:', err);
    res.status(500).json({ error: 'Failed to fetch book items' });
  }
});

/**
 * @swagger
 * /api/bookcopies/{id}:
 *   get:
 *     summary: Lấy thông tin BookCopy theo ID
 *     tags: [BookCopies]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Trả về bản sao sách
 *       404:
 *         description: Không tìm thấy
 */
// lấy BookItem theo id
router.get('/:id', async (req, res) => {
  try {
    const item = await BookCopy.findOne({ id: req.params.id });
    if (!item) return res.status(404).json({ error: 'BookItem not found' });
    res.json(item);
  } catch (err) {
    console.error('❌ Error fetching BookItem by ID:', err);
    res.status(500).json({ error: 'Failed to fetch book item' });
  }
});

/**
 * @swagger
 * /api/bookcopies/by-book/{bookId}:
 *   get:
 *     summary: Lấy danh sách BookCopy theo bookId
 *     tags: [BookCopies]
 *     parameters:
 *       - in: path
 *         name: bookId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Danh sách bản sao
 *       500:
 *         description: Lỗi server
 */
// lấy danh sách bookCopy theo book_id
router.get('/by-book/:bookId', async (req, res) => {
  try {
    const bookId = req.params.bookId;
    const copies = await BookCopy.find({ book_id: bookId });
    res.json(copies);
  } catch (err) {
    res.status(500).json({ message: 'Lỗi khi lấy danh sách bản sao', error: err.message });
  }
});

/**
 * @swagger
 * /api/bookcopies/bulk-update-shelf:
 *   put:
 *     summary: Gán đồng loạt shelf_id cho nhiều BookCopy và cập nhật capacity
 *     tags: [BookCopies]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               ids:
 *                 type: array
 *                 items:
 *                   type: string
 *               shelf_id:
 *                 type: number
 *     responses:
 *       200:
 *         description: Gán kệ thành công
 *       400:
 *         description: Dữ liệu không hợp lệ
 *       500:
 *         description: Lỗi server
 */
// Gán đồng loạt shelf_id cho nhiều BookCopy
router.put('/bulk-update-shelf', async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();
  
  try {
    const { ids, shelf_id } = req.body;

    if (!Array.isArray(ids) || typeof shelf_id !== 'number') {
      return res.status(400).json({ message: 'Dữ liệu không hợp lệ' });
    }

    // Cập nhật bookcopies
    const result = await BookCopy.updateMany(
      { id: { $in: ids }, shelf_id: { $in: [null, 0] } }, // chỉ update những cái chưa gán
      { $set: { shelf_id: shelf_id } },
      { session }
    );

    const modifiedCount = result.modifiedCount || 0;

    if (modifiedCount > 0) {
      // Cập nhật capacity của Shelf (+ số lượng bản sao được gán)
      await Shelf.updateOne(
        { id: shelf_id },
        { $inc: { capacity: modifiedCount } }, // cộng thêm modifiedCount
        { session }
      );
    }

    await session.commitTransaction();
    session.endSession();

    res.json({ message: `Đã cập nhật ${modifiedCount} bản sao và tăng capacity kệ`, modified: modifiedCount });
  } catch (err) {
    await session.abortTransaction();
    session.endSession();
    res.status(500).json({ message: 'Lỗi khi cập nhật bản sao', error: err.message });
  }
});

/**
 * @swagger
 * /api/bookcopies/{id}:
 *   put:
 *     summary: Cập nhật thông tin BookCopy (kệ, trạng thái, ảnh hư hỏng)
 *     tags: [BookCopies]
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
 *             properties:
 *               shelf_id:
 *                 type: number
 *               status:
 *                 type: string
 *               damage_image:
 *                 type: string
 *     responses:
 *       200:
 *         description: Cập nhật thành công
 *       500:
 *         description: Lỗi server
 */
// update bookCopy
router.put('/:id', async (req, res) => {
  try {
    const id = req.params.id;
    const { shelf_id, status, damage_image } = req.body;

    // 1. Tìm bookCopy hiện tại để biết shelf cũ
    const copy = await BookCopy.findOne({ id });
    if (!copy) {
      return res.status(404).json({ message: 'BookCopy không tồn tại' });
    }

    const oldShelfId = copy.shelf_id;
    const newShelfId = shelf_id;

    // 2. Cập nhật BookCopy
    const updateFields = {};
    if (shelf_id !== undefined) updateFields.shelf_id = shelf_id;
    if (status !== undefined) updateFields.status = status;
    if (damage_image !== undefined) updateFields.damage_image = damage_image;

    const result = await BookCopy.updateOne({ id: id }, { $set: updateFields });

    if (result.modifiedCount === 0) {
      return res.status(200).json({ message: 'Không có thay đổi gì để cập nhật' });
    }

    // 3. Nếu shelf thay đổi, cập nhật capacity tương ứng
    if (oldShelfId !== newShelfId) {
      if (oldShelfId != null) {
        await Shelf.updateOne({ id: oldShelfId }, { $inc: { capacity: -1 } });
      }
      if (newShelfId != null) {
        await Shelf.updateOne({ id: newShelfId }, { $inc: { capacity: 1 } });
      }
    }

    res.json({ message: 'Cập nhật thành công', updated: result.modifiedCount });
  } catch (err) {
    res.status(500).json({ message: 'Lỗi server', error: err.message });
  }
});

/**
 * @swagger
 * /api/bookcopies/{copyId}/status:
 *   put:
 *     summary: Cập nhật trạng thái của BookCopy cụ thể
 *     tags: [BookCopies]
 *     parameters:
 *       - in: path
 *         name: copyId
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               newStatus:
 *                 type: string
 *     responses:
 *       200:
 *         description: Trạng thái được cập nhật
 *       404:
 *         description: Không tìm thấy bản sao
 *       500:
 *         description: Lỗi server
 */
// cập nhật trạng thái BookCopy
router.put('/:copyId/status', async (req, res) => {
  const { newStatus } = req.body;
  try {
    const copy = await BookCopy.findOne({ id: req.params.copyId });
    if (!copy) return res.status(404).json({ message: 'BookCopy not found' });

    copy.status = newStatus;
    await copy.save();
    res.json({ message: 'BookCopy status updated', copy });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error updating book copy status' });
  }
});


module.exports = router;