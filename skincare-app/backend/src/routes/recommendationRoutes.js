const express = require('express');
const router = express.Router();
const { getRecommendation, refreshRecommendation } = require('../controllers/recommendationController');
const { protect } = require('../middleware/authMiddleware');

router.get('/', protect, getRecommendation);
router.post('/refresh', protect, refreshRecommendation);

module.exports = router;