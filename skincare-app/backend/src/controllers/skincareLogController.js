const { PrismaClient } = require('../../prisma/generated/prisma/index.js');
const prisma = new PrismaClient();

// ─── Existing: Create Log ───────────────────────────────────────────────────
const createLog = async (req, res) => {
  try {
    const userId = req.userId;
    const { timeOfDay, productsUsed, notes, photo } = req.body;

    const log = await prisma.skincareLog.create({
      data: {
        userId,
        timeOfDay,
        productsUsed: JSON.stringify(productsUsed),
        notes: notes || null,
        photo: photo || null,
      },
    });

    res.status(201).json({
      message: 'Skincare log saved!',
      log: { ...log, productsUsed: JSON.parse(log.productsUsed) },
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// ─── Existing: Get All Logs ─────────────────────────────────────────────────
const getLogs = async (req, res) => {
  try {
    const userId = req.userId;
    const logs = await prisma.skincareLog.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    res.json({
      logs: logs.map((log) => ({
        ...log,
        productsUsed: JSON.parse(log.productsUsed),
      })),
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// ─── NEW: Monthly Heatmap ───────────────────────────────────────────────────
// GET /api/logs/heatmap?year=YYYY&month=MM
//
// Returns one entry per calendar day in the requested month.
// Status logic (based on timeOfDay string values in your DB):
//   0 = no logs that day
//   1 = only Morning OR only Evening/Night logged
//   2 = both a Morning AND an Evening/Night session logged
//
// Also returns currentStreak: consecutive days (back from today) with >= 1 log.
const getMonthlyHeatmap = async (req, res) => {
  try {
    const userId = req.userId;
    const year  = parseInt(req.query.year,  10);
    const month = parseInt(req.query.month, 10); // 1-based (1 = January)

    if (!year || !month || month < 1 || month > 12) {
      return res.status(400).json({
        message: 'Valid query params required: year (YYYY) and month (1–12).',
      });
    }

    // ── Date range for the requested month ──────────────────────────────────
    const startDate    = new Date(year, month - 1, 1);      // e.g. 2026-05-01 00:00:00
    const endDate      = new Date(year, month, 1);           // e.g. 2026-06-01 00:00:00
    const daysInMonth  = new Date(year, month, 0).getDate(); // e.g. 31 for May

    // ── Fetch only the fields we need for this month ─────────────────────────
    const logs = await prisma.skincareLog.findMany({
      where: {
        userId,
        createdAt: { gte: startDate, lt: endDate },
      },
      select: {
        createdAt: true,
        timeOfDay: true,
      },
    });

    // ── Group sessions by "YYYY-MM-DD" date string ───────────────────────────
    // Using a Map of Sets so we can track which session types occurred per day
    const sessionsByDate = new Map();

    for (const log of logs) {
      // toISOString() is UTC — adjust to local midnight using the offset
      const localDate = new Date(log.createdAt);
      const dateStr = `${localDate.getFullYear()}-`
        + `${String(localDate.getMonth() + 1).padStart(2, '0')}-`
        + `${String(localDate.getDate()).padStart(2, '0')}`;

      if (!sessionsByDate.has(dateStr)) sessionsByDate.set(dateStr, new Set());
      sessionsByDate.get(dateStr).add(log.timeOfDay.toLowerCase());
    }

    // ── Build heatmap: one entry per calendar day ────────────────────────────
    const heatmapData = [];
    for (let day = 1; day <= daysInMonth; day++) {
      const mm     = String(month).padStart(2, '0');
      const dd     = String(day).padStart(2, '0');
      const dateStr = `${year}-${mm}-${dd}`;

      const sessions = sessionsByDate.get(dateStr);
      let status = 0;

      if (sessions && sessions.size > 0) {
        const hasMorning = sessions.has('morning');
        // Count Evening OR Night as the "second" session
        const hasEvening = sessions.has('evening') || sessions.has('night');

        if (hasMorning && hasEvening) {
          status = 2; // Both sessions done — deep pink
        } else {
          status = 1; // At least one session — light pink
        }
      }

      heatmapData.push({ date: dateStr, dayNumber: day, status });
    }

    // ── Current streak (scanned across all time, not just this month) ────────
    // Fetch all log dates for this user, most recent first
    const allLogs = await prisma.skincareLog.findMany({
      where: { userId },
      select: { createdAt: true },
      orderBy: { createdAt: 'desc' },
    });

    // Build a Set of all dates that have at least one log
    const allLogDates = new Set(
      allLogs.map((l) => {
        const d = new Date(l.createdAt);
        return `${d.getFullYear()}-`
          + `${String(d.getMonth() + 1).padStart(2, '0')}-`
          + `${String(d.getDate()).padStart(2, '0')}`;
      })
    );

    // Walk backwards from today counting consecutive logged days
    let currentStreak = 0;
    const cursor = new Date();
    cursor.setHours(0, 0, 0, 0);

    while (true) {
      const ds = `${cursor.getFullYear()}-`
        + `${String(cursor.getMonth() + 1).padStart(2, '0')}-`
        + `${String(cursor.getDate()).padStart(2, '0')}`;

      if (allLogDates.has(ds)) {
        currentStreak++;
        cursor.setDate(cursor.getDate() - 1);
      } else {
        break; // Streak ends
      }
    }

    return res.json({ heatmapData, currentStreak });
  } catch (error) {
    console.error('Heatmap error:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = { createLog, getLogs, getMonthlyHeatmap };