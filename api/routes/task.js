
const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();

const Task = require('../models/Task');
const User = require('../models/User');
const authMiddleware = require('../middleware/authMiddleware');
const isValidId = (id) => mongoose.Types.ObjectId.isValid(id);


// C1 - Tìm tài khoản theo email
router.get('/users/search', authMiddleware, async (req, res) => {
  try {
    const email = (req.query.email || '').trim().toLowerCase();

    if (!email) {
      return res.status(400).json({
        message: 'Vui long nhap email can tim'
      });
    }

    const users = await User.find({
      email: { $regex: email, $options: 'i' },
      _id: { $ne: req.userId }
    }).select('name email');

    return res.status(200).json({
      message: 'Tim tai khoan thanh cong',
      users
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Loi tim tai khoan',
      error: error.message
    });
  }
});
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

    if (!title || !createdBy) {
      return res.status(400).json({
        message: 'Vui long nhap tieu de cong viec'
      });
    }

    if (!isValidId(createdBy)) {
      return res.status(400).json({
        message: 'ID nguoi tao khong hop le'
      });
    }

    if (assignedTo && !isValidId(assignedTo)) {
      return res.status(400).json({
        message: 'ID nguoi duoc giao khong hop le'
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

// C1 - Giao cong viec cho mot hoac nhieu nguoi
router.put('/:id/assign', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { emails, primaryEmail } = req.body;

    if (!isValidId(id)) {
      return res.status(400).json({
        message: 'ID cong viec khong hop le'
      });
    }

    if (!Array.isArray(emails) || emails.length === 0) {
      return res.status(400).json({
        message: 'Vui long chon it nhat mot nguoi duoc giao'
      });
    }

    const task = await Task.findById(id);

    if (!task) {
      return res.status(404).json({
        message: 'Khong tim thay cong viec'
      });
    }

    // Chi nguoi tao cong viec moi duoc giao viec
    if (task.createdBy.toString() !== req.userId) {
      return res.status(403).json({
        message: 'Chi nguoi tao moi duoc giao cong viec'
      });
    }

    const normalizedEmails = [
      ...new Set(
        emails
          .filter(email => typeof email === 'string')
          .map(email => email.trim().toLowerCase())
          .filter(Boolean)
      )
    ];

    if (normalizedEmails.length === 0) {
      return res.status(400).json({
        message: 'Danh sach email khong hop le'
      });
    }

    const users = await User.find({
      email: { $in: normalizedEmails }
    }).select('_id name email');

    if (users.length !== normalizedEmails.length) {
      return res.status(404).json({
        message: 'Mot hoac nhieu email khong ton tai'
      });
    }

    const userIds = users.map(user => user._id);

    // Khong cho nguoi tao tu giao viec cho chinh minh
    if (userIds.some(userId => userId.toString() === req.userId)) {
      return res.status(400).json({
        message: 'Khong the giao cong viec cho chinh minh'
      });
    }

    let primaryUser = users[0];

    if (primaryEmail) {
      const normalizedPrimaryEmail = primaryEmail.trim().toLowerCase();

      primaryUser = users.find(
        user => user.email === normalizedPrimaryEmail
      );

      if (!primaryUser) {
        return res.status(400).json({
          message: 'Nguoi giao chinh phai nam trong danh sach duoc giao'
        });
      }
    }

    task.assignedUsers = userIds;
    task.assignedTo = primaryUser._id;

    // Xoa cac xac nhan cu neu thay doi danh sach nguoi duoc giao
    task.acceptedBy = [];

    await task.save();

    const result = await Task.findById(id)
      .populate('createdBy', 'name email')
      .populate('assignedTo', 'name email')
      .populate('assignedUsers', 'name email')
      .populate('acceptedBy', 'name email')
      .populate('sharedWith', 'name email');

    return res.status(200).json({
      message: 'Giao cong viec thanh cong',
      task: result
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Loi giao cong viec',
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
    if (
      updateData.assignedTo !== undefined &&
      updateData.assignedTo !== null &&
      !isValidId(updateData.assignedTo)
    ) {
      return res.status(400).json({
        message: 'ID nguoi duoc giao khong hop le'
      });
    }

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
