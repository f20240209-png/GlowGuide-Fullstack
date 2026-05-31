const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('../../prisma/generated/prisma/index.js');
const admin = require('../services/firebaseAdmin');

const prisma = new PrismaClient();

// ── REGISTER (email/password) ────────────────────────────────
const register = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: { name, email, password: hashedPassword }
    });

    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({
      message: 'User registered successfully',
      token,
      user: { id: user.id, name: user.name, email: user.email }
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// ── LOGIN (email/password) ───────────────────────────────────
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || !user.password) {
      return res.status(400).json({ message: 'Invalid email or password' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid email or password' });
    }

    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Login successful',
      token,
      user: { id: user.id, name: user.name, email: user.email }
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// ── GOOGLE LOGIN ─────────────────────────────────────────────
const googleLogin = async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ message: 'No token provided' });
    }

    let decodedToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(idToken);
      console.log('Google token verified! Email:', decodedToken.email);
    } catch (verifyError) {
      console.log('Google verify error:', verifyError.code, verifyError.message);
      return res.status(401).json({
        message: 'Invalid Google token',
        error: verifyError.message,
        code: verifyError.code
      });
    }

    const { uid: googleId, email, name } = decodedToken;

    let user = await prisma.user.findFirst({
      where: { OR: [{ googleId }, { email }] }
    });

    if (user) {
      if (!user.googleId) {
        user = await prisma.user.update({
          where: { id: user.id },
          data: { googleId }
        });
      }
    } else {
      user = await prisma.user.create({
        data: {
          name: name || email.split('@')[0],
          email,
          googleId,
          password: null
        }
      });
    }

    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Google login successful',
      token,
      user: { id: user.id, name: user.name, email: user.email }
    });

  } catch (error) {
    console.log('Google login server error:', error.message);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// ── FIREBASE EMAIL LOGIN ─────────────────────────────────────
const firebaseLogin = async (req, res) => {
  try {
    const { idToken, email, name } = req.body;

    if (!idToken) {
      return res.status(400).json({ message: 'No token provided' });
    }

    let decodedToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(idToken);
    } catch (verifyError) {
      return res.status(401).json({
        message: 'Invalid token',
        error: verifyError.message
      });
    }

    if (!decodedToken.email_verified) {
      return res.status(401).json({
        message: 'Email not verified. Please check your inbox.'
      });
    }

    let user = await prisma.user.findUnique({
      where: { email: decodedToken.email }
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          name: name || decodedToken.name || decodedToken.email.split('@')[0],
          email: decodedToken.email,
          password: null,
          googleId: decodedToken.uid,
        }
      });
    }

    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Login successful',
      token,
      user: { id: user.id, name: user.name, email: user.email }
    });

  } catch (error) {
    console.log('Firebase login server error:', error.message);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// ── PHONE LOGIN ──────────────────────────────────────────────
const phoneLogin = async (req, res) => {
  try {
    const { idToken, name } = req.body;

    if (!idToken) {
      return res.status(400).json({ message: 'No token provided' });
    }

    let decodedToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(idToken);
    } catch (verifyError) {
      console.log('Phone verify error:', verifyError.code, verifyError.message);
      return res.status(401).json({
        message: 'Invalid token',
        error: verifyError.message
      });
    }

    const phoneNumber = decodedToken.phone_number;
    if (!phoneNumber) {
      return res.status(400).json({ message: 'No phone number in token' });
    }

    let user = await prisma.user.findUnique({ where: { phoneNumber } });
    const isNewUser = !user;

    if (!user) {
      if (!name || name.trim() === '') {
        return res.status(200).json({
          requiresName: true,
          message: 'Please provide your name to complete registration',
          phoneNumber
        });
      }
      user = await prisma.user.create({
        data: {
          name: name.trim(),
          phoneNumber,
          isNewUser: true,
        }
      });
    } else {
      if (user.isNewUser) {
        user = await prisma.user.update({
          where: { id: user.id },
          data: { isNewUser: false }
        });
      }
    }

    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: isNewUser ? 'Account created successfully' : 'Login successful',
      token,
      isNewUser,
      user: {
        id: user.id,
        name: user.name,
        phoneNumber: user.phoneNumber
      }
    });

  } catch (error) {
    console.log('Phone login server error:', error.message);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = { register, login, googleLogin, firebaseLogin, phoneLogin };