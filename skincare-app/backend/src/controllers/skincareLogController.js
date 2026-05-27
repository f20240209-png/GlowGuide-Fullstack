const { PrismaClient } = require('../../prisma/generated/prisma/index.js');
const prisma = new PrismaClient();

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
        photo: photo || null  // store base64 directly
      }
    });

    res.status(201).json({
      message: 'Skincare log saved!',
      log: { ...log, productsUsed: JSON.parse(log.productsUsed) }
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const getLogs = async (req, res) => {
  try {
    const userId = req.userId;
    const logs = await prisma.skincareLog.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' }
    });

    res.json({
      logs: logs.map(log => ({
        ...log,
        productsUsed: JSON.parse(log.productsUsed)
      }))
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = { createLog, getLogs };