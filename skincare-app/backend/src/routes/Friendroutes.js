const express = require('express');
const router  = express.Router();
const {
  searchUsers,
  sendRequest,
  acceptRequest,
  rejectRequest,
  cancelRequest,
  getFriends,
  getPendingRequests,
  getFriendProfile,
} = require('../controllers/friendController');
const { protect } = require('../middleware/authMiddleware');

router.get('/users/search',               protect, searchUsers);
router.get('/friends/:userId/profile',    protect, getFriendProfile);
router.get('/friends',                    protect, getFriends);
router.get('/friends/requests',           protect, getPendingRequests);
router.post('/friends/request/:userId',   protect, sendRequest);
router.post('/friends/accept/:requestId', protect, acceptRequest);
router.post('/friends/reject/:requestId', protect, rejectRequest);
router.delete('/friends/request/:requestId', protect, cancelRequest);

module.exports = router;