const express = require('express');
const router = express.Router();
const { createProfile, getProfile, updateProfile, searchProducts } = require('../controllers/profileController');
const { protect } = require('../middleware/authMiddleware');

router.post('/', protect, createProfile);
router.get('/', protect, getProfile);
router.put('/', protect, updateProfile);
router.get('/search-products', searchProducts);

module.exports = router;