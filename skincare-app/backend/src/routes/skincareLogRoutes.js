const express = require('express');
const router = express.Router();
const { createLog, getLogs } = require('../controllers/skincareLogController');
const { protect } = require('../middleware/authMiddleware');
const upload = require('../middleware/uploadMiddleware');

router.post('/', protect, upload.single('photo'), createLog);
router.get('/', protect, getLogs);

module.exports = router;