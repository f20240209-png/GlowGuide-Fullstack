const { PrismaClient } = require('../../prisma/generated/prisma/index.js');
const prisma = new PrismaClient();

// ─── Check if username is available ───────────────────────────────────────
// GET /api/profile/check-username?username=xxx
const checkUsername = async (req, res) => {
  try {
    const { username } = req.query;

    if (!username || username.trim().length < 3) {
      return res.status(400).json({
        available: false,
        message: 'Username must be at least 3 characters.',
      });
    }

    const clean = username.trim().toLowerCase().replace(/[^a-z0-9_.]/g, '');
    if (clean !== username.trim().toLowerCase()) {
      return res.status(400).json({
        available: false,
        message: 'Only letters, numbers, underscores and dots allowed.',
      });
    }

    const existing = await prisma.user.findUnique({
      where: { username: clean },
    });

    res.json({
      available: !existing,
      username:  clean,
      message:   existing ? 'Username already taken.' : 'Username available!',
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// ─── Set username ─────────────────────────────────────────────────────────
// POST /api/profile/username
const setUsername = async (req, res) => {
  try {
    const myId    = req.userId;
    const { username } = req.body;

    if (!username || username.trim().length < 3) {
      return res.status(400).json({
        message: 'Username must be at least 3 characters.',
      });
    }

    const clean = username.trim().toLowerCase().replace(/[^a-z0-9_.]/g, '');

    // Check if already changed once
    const me = await prisma.user.findUnique({ where: { id: myId } });
    if (me?.usernameChangedAt !== null && me?.username !== null) {
      return res.status(400).json({
        message: 'Username can only be changed once.',
      });
    }

    // Check availability
    const existing = await prisma.user.findFirst({
      where: { username: clean, id: { not: myId } },
    });
    if (existing) {
      return res.status(400).json({ message: 'Username already taken.' });
    }

    const updated = await prisma.user.update({
      where: { id: myId },
      data: {
        username: clean,
        // Only set usernameChangedAt if they are CHANGING an existing username
        ...(me?.username !== null ? { usernameChangedAt: new Date() } : {}),
      },
    });

    res.json({
      message:  'Username set successfully!',
      username: updated.username,
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = { checkUsername, setUsername };