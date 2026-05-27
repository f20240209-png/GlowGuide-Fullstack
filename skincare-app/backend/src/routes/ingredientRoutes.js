const express = require('express');
const router = express.Router();
const { analyzeRoutine } = require('../controllers/ingredientAnalyzerController');
const { protect } = require('../middleware/authMiddleware');

router.post('/analyze-routine', protect, analyzeRoutine);

module.exports = router;