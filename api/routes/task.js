
const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();

const Task = require('../models/Task');
const User = require('../models/User');
const authMiddleware = require('../middleware/authMiddleware');

const isValidId = (id) => mongoose.Types.ObjectId.isValid(id);

// Lay thong tin cong viec kem cac tai khoan lien quan
const populateTask = (query) => {
  return query
    .populate('createdBy', 'name email')
    .populate('assignedTo', 'name email')
    .populate('assignedUsers', 'name email')
    .populate('acceptedBy', 'name email')
    .populate('sharedWith', 'name email');
};

// Kiem tra nguoi dang dang nhap co quyen xem cong viec
const canAccessTask = (task, userId) => {
  const id = String(userId);

  return (
    String(task.createdBy) === id ||
    String(task.assignedTo) === id ||
    (task.assignedUsers || []).some(
      user => String(user) === id
    ) ||
    (task.sharedWith || []).some(
      user => String(user) === id
    )
  );
};

// =====================================================
// TIM TAI KHOAN THEO EMAIL
// GET /api/tasks/users/search
// =====================================================
router.get('/users/search', authMiddleware, async (req, res) => {
  try {
    const email = (req.query.email || '').trim().toLowerCase();

    if (!email) {
      return res.status(400).json({
        message: 'Vui long nhap email can tim'
      });
    }

    const users = await User.find({
      email: { $regex: email.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), $options: 'i' },
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

// =====================================================
// THEM CONG VIEC MOI
// POST /api/tasks
// =====================================================
router.post('/', authMiddleware, async (req, res) => {
  try {
    const {
      title,
      description,
      status,
      priority,
      startDate,
      dueDate
    } = req.body;

    if (
      !title ||
      typeof title !== 'string' ||
      !title.trim()
    ) {
      return res.status(400).json({
        message: 'Vui long nhap ten cong viec'
      });
    }

    const newTask = await Task.create({
      title: title.trim(),
      description: description || '',
      createdBy: req.userId,
      assignedTo: null,
      assignedUsers: [],
      acceptedBy: [],
      sharedWith: [],
      status: status || 'todo',
      priority: priority || 'medium',
      startDate: startDate || null,
      dueDate: dueDate || null
    });

    const result = await populateTask(
      Task.findById(newTask._id)
    );

    return res.status(201).json({
      message: 'Them cong viec thanh cong',
      task: result
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Loi them cong viec',
      error: error.message
    });
  }
});

// =====================================================
// LAY DANH SACH CONG VIEC
// GET /api/tasks
// =====================================================
router.get('/', authMiddleware, async (req, res) => {
  try {
    const tasks = await Task.find({
      $or: [
        { createdBy: req.userId },
        { assignedTo: req.userId },
        { assignedUsers: req.userId },
        { sharedWith: req.userId }
      ]
    })
      .populate('createdBy', 'name email')
      .populate('assignedTo', 'name email')
      .populate('assignedUsers', 'name email')
      .populate('acceptedBy', 'name email')
      .populate('sharedWith', 'name email')
      .sort({ createdAt: -1 });

    return res.status(200).json(tasks);
  } catch (error) {
    return res.status(500).json({
      message: 'Loi lay danh sach cong viec',
      error: error.message
    });
  }
});

// =====================================================
// LAY CHI TIET CONG VIEC
// GET /api/tasks/:id
// =====================================================
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;

    if (!isValidId(id)) {
      return res.status(400).json({
        message: 'ID cong viec khong hop le'
      });
    }

    const task = await populateTask(Task.findById(id));

    if (!task) {
      return res.status(404).json({
        message: 'Khong tim thay cong viec'
      });
    }

    if (!canAccessTask(task, req.userId)) {
      return res.status(403).json({
        message: 'Ban khong co quyen xem cong viec nay'
      });
    }

    return res.status(200).json(task);
  } catch (error) {
    return res.status(500).json({
      message: 'Loi lay chi tiet cong viec',
      error: error.message
    });
  }
});

// =====================================================
// C2 - CHI DINH NGUOI PHU TRACH CHINH
// PUT /api/tasks/:id/primary-assignee
// =====================================================
router.put('/:id/primary-assignee', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { primaryEmail } = req.body;

    if (!isValidId(id)) {
      return res.status(400).json({
        message: 'ID cong viec khong hop le'
      });
    }

    if (
      typeof primaryEmail !== 'string' ||
      !primaryEmail.trim()
    ) {
      return res.status(400).json({
        message: 'Vui long nhap email nguoi phu trach chinh'
      });
    }

    const task = await Task.findById(id);

    if (!task) {
      return res.status(404).json({
        message: 'Khong tim thay cong viec'
      });
    }

    if (String(task.createdBy) !== String(req.userId)) {
      return res.status(403).json({
        message: 'Chi nguoi tao moi duoc chi dinh nguoi phu trach chinh'
      });
    }

    const normalizedEmail = primaryEmail.trim().toLowerCase();

    const user = await User.findOne({
      email: normalizedEmail
    }).select('_id name email');

    if (!user) {
      return res.status(404).json({
        message: 'Khong tim thay tai khoan'
      });
    }

    const isAssigned = (task.assignedUsers || []).some(
      userId => String(userId) === String(user._id)
    );

    if (!isAssigned) {
      return res.status(400).json({
        message: 'Nguoi phu trach chinh phai nam trong danh sach duoc giao'
      });
    }

    task.assignedTo = user._id;

    await task.save();

    const result = await populateTask(
      Task.findById(id)
    );

    return res.status(200).json({
      message: 'Chi dinh nguoi phu trach chinh thanh cong',
      task: result
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Loi chi dinh nguoi phu trach chinh',
      error: error.message
    });
  }
});

// =====================================================
// C1 - GIAO CONG VIEC CHO MOT HOAC NHIEU NGUOI
// PUT /api/tasks/:id/assign
// =====================================================
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

    if (String(task.createdBy) !== String(req.userId)) {
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

    if (
      userIds.some(
        userId => String(userId) === String(req.userId)
      )
    ) {
      return res.status(400).json({
        message: 'Khong the giao cong viec cho chinh minh'
      });
    }

    let primaryUser = users[0];

    if (
      primaryEmail !== undefined &&
      primaryEmail !== null &&
      primaryEmail !== ''
    ) {
      if (typeof primaryEmail !== 'string') {
        return res.status(400).json({
          message: 'Email nguoi phu trach khong hop le'
        });
      }

      const normalizedPrimaryEmail = primaryEmail.trim().toLowerCase();

      primaryUser = users.find(
        user => user.email.trim().toLowerCase() === normalizedPrimaryEmail
      );

      if (!primaryUser) {
        return res.status(400).json({
          message: 'Nguoi phu trach chinh phai nam trong danh sach C1'
        });
      }
    }

    task.assignedUsers = userIds;
    task.assignedTo = primaryUser._id;
    task.acceptedBy = [];

    await task.save();

    const result = await populateTask(
      Task.findById(id)
    );

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

// =====================================================
// NHAN / CHAP NHAN CONG VIEC
// POST /api/tasks/:id/accept
// =====================================================
router.post('/:id/accept', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = String(req.userId);

    if (!isValidId(id)) {
      return res.status(400).json({
        message: 'ID cong viec khong hop le'
      });
    }

    const task = await Task.findById(id);

    if (!task) {
      return res.status(404).json({
        message: 'Khong tim thay cong viec'
      });
    }

    const isAssigned =
      String(task.assignedTo) === userId ||
      (task.assignedUsers || []).some(
        item => String(item) === userId
      );

    if (!isAssigned) {
      return res.status(403).json({
        message: 'Ban khong duoc giao cong viec nay'
      });
    }

    if (
      !(task.acceptedBy || []).some(
        item => String(item) === userId
      )
    ) {
      task.acceptedBy.push(req.userId);
    }

    await task.save();

    const result = await populateTask(
      Task.findById(id)
    );

    return res.status(200).json({
      message: 'Nhan cong viec thanh cong',
      task: result
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Loi nhan cong viec',
      error: error.message
    });
  }
});

// =====================================================
// =====================================================
// C - CHIA SE CONG VIEC CHO NHIEU NGUOI
// POST /api/tasks/:id/share
// Body: { emails: ["user1@gmail.com", "user2@gmail.com"] }
// =====================================================
router.post('/:id/share', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { emails } = req.body;

    // Kiem tra ID cong viec
    if (!isValidId(id)) {
      return res.status(400).json({
        message: 'ID cong viec khong hop le'
      });
    }

    // Kiem tra danh sach email
    if (!Array.isArray(emails) || emails.length === 0) {
      return res.status(400).json({
        message: 'Vui long nhap email nhung nguoi can chia se'
      });
    }

    // Chuan hoa email va loai bo email trung lap
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

    // Tim cong viec
    const task = await Task.findById(id);

    if (!task) {
      return res.status(404).json({
        message: 'Khong tim thay cong viec'
      });
    }

    // Chi nguoi tao moi co quyen chia se
    if (String(task.createdBy) !== String(req.userId)) {
      return res.status(403).json({
        message: 'Chi nguoi tao moi duoc chia se cong viec'
      });
    }

    // Khong cho phep chia se cho chinh minh
    const creator = await User.findById(req.userId).select('email');

    if (!creator) {
      return res.status(404).json({
        message: 'Khong tim thay tai khoan nguoi chia se'
      });
    }

    if (
      normalizedEmails.includes(
        creator.email.trim().toLowerCase()
      )
    ) {
      return res.status(400).json({
        message: 'Khong the chia se cong viec cho chinh minh'
      });
    }

    // Tim cac tai khoan theo email
    const recipients = await User.find({
      email: { $in: normalizedEmails }
    }).select('_id name email');

    // Kiem tra email khong ton tai
    if (recipients.length !== normalizedEmails.length) {
      const foundEmails = recipients.map(
        user => user.email.trim().toLowerCase()
      );

      const notFoundEmails = normalizedEmails.filter(
        email => !foundEmails.includes(email)
      );

      return res.status(404).json({
        message: 'Mot hoac nhieu email khong ton tai',
        notFoundEmails
      });
    }

    // Them nguoi nhan vao danh sach sharedWith
    const currentSharedIds = (task.sharedWith || []).map(
      user => String(user)
    );

    let addedCount = 0;

    recipients.forEach(user => {
      const userId = String(user._id);

      if (!currentSharedIds.includes(userId)) {
        task.sharedWith.push(user._id);
        currentSharedIds.push(userId);
        addedCount++;
      }
    });

    await task.save();

    // Lay lai cong viec kem thong tin tai khoan
    const result = await populateTask(
      Task.findById(id)
    );

    return res.status(200).json({
      message: addedCount > 0
        ? 'Chia se cong viec thanh cong'
        : 'Cong viec da duoc chia se cho cac tai khoan nay',
      addedCount,
      sharedCount: result.sharedWith.length,
      task: result
    });

  } catch (error) {
    return res.status(500).json({
      message: 'Loi chia se cong viec',
      error: error.message
    });
  }
});

// =====================================================
// CAP NHAT CONG VIEC
// PUT /api/tasks/:id
// =====================================================
router.put('/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;

    if (!isValidId(id)) {
      return res.status(400).json({
        message: 'ID cong viec khong hop le'
      });
    }

    const task = await Task.findById(id);

    if (!task) {
      return res.status(404).json({
        message: 'Khong tim thay cong viec'
      });
    }

    if (String(task.createdBy) !== String(req.userId)) {
      return res.status(403).json({
        message: 'Chi nguoi tao moi duoc cap nhat cong viec'
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

    allowedFields.forEach(field => {
      if (req.body[field] !== undefined) {
        task[field] = req.body[field];
      }
    });

    if (
      task.assignedTo &&
      !isValidId(task.assignedTo)
    ) {
      return res.status(400).json({
        message: 'ID nguoi duoc giao khong hop le'
      });
    }

    await task.save();

    const result = await populateTask(
      Task.findById(id)
    );

    return res.status(200).json({
      message: 'Cap nhat cong viec thanh cong',
      task: result
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Loi cap nhat cong viec',
      error: error.message
    });
  }
});

// =====================================================
// XOA CONG VIEC
// DELETE /api/tasks/:id
// =====================================================
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;

    if (!isValidId(id)) {
      return res.status(400).json({
        message: 'ID cong viec khong hop le'
      });
    }

    const task = await Task.findById(id);

    if (!task) {
      return res.status(404).json({
        message: 'Khong tim thay cong viec'
      });
    }

    if (String(task.createdBy) !== String(req.userId)) {
      return res.status(403).json({
        message: 'Ban khong co quyen xoa cong viec nay'
      });
    }

    await Task.findByIdAndDelete(id);

    return res.status(200).json({
      message: 'Xoa cong viec thanh cong'
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Loi xoa cong viec',
      error: error.message
    });
  }
});

module.exports = router;
