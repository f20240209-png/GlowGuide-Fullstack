const express = require('express');
const router  = express.Router();
const { getPosts, getPostById, getMyPosts, createPost, answerPost, likePost, markHelpful } = require('../controllers/communityController');
const { protect } = require('../middleware/authMiddleware');

router.get('/',                     protect, getPosts);
router.get('/my-posts',             protect, getMyPosts);
router.get('/:id',                  protect, getPostById);
router.post('/',                    protect, createPost);
router.post('/:id/answer',          protect, answerPost);
router.post('/:id/like',            protect, likePost);
router.post('/answers/:id/helpful', protect, markHelpful);

module.exports = router;