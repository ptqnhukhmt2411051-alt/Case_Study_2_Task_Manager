
const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();

const Task = require('../models/Task');

const isValidId = (id) => mongoose.Types.ObjectId.isValid(id);

// Lấy danh sách công việc
router.get('/', async (req, res) => {
  try {
    const tasks = await Task.find()
      .populate('createdBy', 'name email')
      .populate('assignedTo', 'name email')
      .populate('acceptedBy', 'name email')
      .populate('sharedWith', 'name email')
      .sort({ createdAt: -1 });

    res.status(200).json(tasks);
  } catch (error) {
    res.status(500).json({
      message: 'Loi lay danh sach cong viec',
      error: error.message
    });
  }
});

// Lấy chi tiết một công việc
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    if (!isValidId(id)) {
      return res.status(400).json({
        message: 'ID cong viec khong hop le'
      });
    }

    const task = await Task.findById(id)
      .populate('createdBy', 'name email')
      .populate('assignedTo', 'name email')
      .populate('acceptedBy', 'name email')
      .populate('sharedWith', 'name email');

    if (!task) {
      return res.status(404).json({
        message: 'Khong tim thay cong viec'
      });
    }

    res.status(200).json(task);
  } catch (error) {
    res.status(500).json({
      message: 'Loi lay chi tiet cong viec',
      error: error.message
    });
  }
});

// Tạo công việc
router.post('/', async (req, res) => {
  try {
    const {
      title,
      description,
      createdBy,
      assignedTo,
      status,
      priority,
      startDate,
      dueDate
    } = req.body;

    if (!title || !createdBy || !assignedTo) {
      return res.status(400).json({
        message: 'Vui long nhap day du thong tin'
      });
    }

    if (!isValidId(createdBy) || !isValidId(assignedTo)) {
      return res.status(400).json({
        message: 'ID nguoi dung khong hop le'
      });
    }

    const task = await Task.create({
      title,
      description,
      createdBy,
      assignedTo,
      acceptedBy: [],
      sharedWith: [],
      status,
      priority,
      startDate: startDate || null,
      dueDate: dueDate || null
    });

    const result = await Task.findById(task._id)
      .populate('createdBy', 'name email')
      .populate('assignedTo', 'name email')
      .populate('acceptedBy', 'name email')
      .populate('sharedWith', 'name email');

    res.status(201).json({
      message: 'Tao cong viec thanh cong',
      task: result
    });
  } catch (error) {
    res.status(500).json({
      message: 'Loi tao cong viec',
      error: error.message
    });
  }
});

// Nhận công việc
router.post('/:id/accept', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.body;

    if (!isValidId(id) || !isValidId(userId)) {
      return res.status(400).json({
        message: 'ID khong hop le'
      });
    }

    const task = await Task.findById(id);

    if (!task) {
      return res.status(404).json({
        message: 'Khong tim thay cong viec'
      });
    }

    if (task.assignedTo.toString() !== userId) {
      return res.status(403).json({
        message: 'Ban khong duoc giao cong viec nay'
      });
    }

    if (!task.acceptedBy.some(
      (item) => item.toString() === userId
    )) {
      task.acceptedBy.push(userId);
    }

    await task.save();

    const result = await Task.findById(id)
      .populate('createdBy', 'name email')
      .populate('assignedTo', 'name email')
      .populate('acceptedBy', 'name email')
      .populate('sharedWith', 'name email');

    res.status(200).json({
      message: 'Nhan cong viec thanh cong',
      task: result
    });
  } catch (error) {
    res.status(500).json({
      message: 'Loi nhan cong viec',
      error: error.message
    });
  }
});

// Chia sẻ công việc
router.post('/:id/share', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId, recipientId } = req.body;

    if (
      !isValidId(id) ||
      !isValidId(userId) ||
      !isValidId(recipientId)
    ) {
      return res.status(400).json({
        message: 'ID khong hop le'
      });
    }

    const task = await Task.findById(id);

    if (!task) {
      return res.status(404).json({
        message: 'Khong tim thay cong viec'
      });
    }

    if (task.createdBy.toString() !== userId) {
      return res.status(403).json({
        message: 'Chi nguoi tao moi duoc chia se cong viec'
      });
    }

    if (!task.sharedWith.some(
      (item) => item.toString() === recipientId
    )) {
      task.sharedWith.push(recipientId);
    }

    await task.save();

    const result = await Task.findById(id)
      .populate('createdBy', 'name email')
      .populate('assignedTo', 'name email')
      .populate('acceptedBy', 'name email')
      .populate('sharedWith', 'name email');

    res.status(200).json({
      message: 'Chia se cong viec thanh cong',
      task: result
    });
  } catch (error) {
    res.status(500).json({
      message: 'Loi chia se cong viec',
      error: error.message
    });
  }
});

// Cập nhật công việc
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    if (!isValidId(id)) {
      return res.status(400).json({
        message: 'ID cong viec khong hop le'
      });
    }

    const allowedFields = [
      'title',
      'description',
      'assignedTo',
      'status',
      'priority',
      'startDate',
      'dueDate'
    ];

    const updateData = {};

    allowedFields.forEach((field) => {
      if (req.body[field] !== undefined) {
        updateData[field] = req.body[field];
      }
    });

    const task = await Task.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    )
      .populate('createdBy', 'name email')
      .populate('assignedTo', 'name email')
      .populate('acceptedBy', 'name email')
      .populate('sharedWith', 'name email');

    if (!task) {
      return res.status(404).json({
        message: 'Khong tim thay cong viec'
      });
    }

    res.status(200).json({
      message: 'Cap nhat cong viec thanh cong',
      task
    });
  } catch (error) {
    res.status(500).json({
      message: 'Loi cap nhat cong viec',
      error: error.message
    });
  }
});

// Xóa công việc
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    if (!isValidId(id)) {
      return res.status(400).json({
        message: 'ID cong viec khong hop le'
      });
    }

    const task = await Task.findByIdAndDelete(id);

    if (!task) {
      return res.status(404).json({
        message: 'Khong tim thay cong viec'
      });
    }

    res.status(200).json({
      message: 'Xoa cong viec thanh cong'
    });
  } catch (error) {
    res.status(500).json({
      message: 'Loi xoa cong viec',
      error: error.message
    });
  }
});

module.exports = router;
