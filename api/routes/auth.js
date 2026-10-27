
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();

// API dang ky tai khoan
router.post('/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({
        message: 'Vui long nhap day du thong tin',
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        message: 'Mat khau phai co it nhat 6 ky tu',
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    const existingUser = await User.findOne({
      email: normalizedEmail,
    });

    if (existingUser) {
      return res.status(409).json({
        message: 'Email da duoc dang ky',
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await User.create({
      name: name.trim(),
      email: normalizedEmail,
      password: hashedPassword,
    });

    res.status(201).json({
      message: 'Dang ky tai khoan thanh cong',
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
      },
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({
        message: 'Email da duoc dang ky',
      });
    }

    console.error('Loi dang ky:', error.message);
    res.status(500).json({
      message: 'Loi may chu khi dang ky',
    });
  }
});

// API dang nhap
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        message: 'Vui long nhap email va mat khau',
      });
    }

    const user = await User.findOne({
      email: email.trim().toLowerCase(),
    });

    if (!user) {
      return res.status(401).json({
        message: 'Email hoac mat khau khong dung',
      });
    }

    const passwordMatch = await bcrypt.compare(
      password,
      user.password
    );

    if (!passwordMatch) {
      return res.status(401).json({
        message: 'Email hoac mat khau khong dung',
      });
    }

    if (!process.env.JWT_SECRET) {
      throw new Error('Chua cau hinh JWT_SECRET trong .env');
    }

    const token = jwt.sign(
      { userId: user._id.toString() },
      process.env.JWT_SECRET,
      { expiresIn: '1d' }
    );

    res.json({
      message: 'Dang nhap thanh cong',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
      },
    });
  } catch (error) {
    console.error('Loi dang nhap:', error.message);
    res.status(500).json({
      message: 'Loi may chu khi dang nhap',
    });
  }
});

module.exports = router;
