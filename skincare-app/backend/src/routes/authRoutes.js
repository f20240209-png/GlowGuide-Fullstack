const express = require('express');
const router = express.Router();
const { register, login, googleLogin, firebaseLogin, phoneLogin } = require('../controllers/authController');

router.post('/register', register);
router.post('/login', login);
router.post('/google', googleLogin);
router.post('/firebase-login', firebaseLogin);
router.post('/phone-login', phoneLogin);

module.exports = router;