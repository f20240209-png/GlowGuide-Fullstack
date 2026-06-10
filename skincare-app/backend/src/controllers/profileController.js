const { PrismaClient } = require('../../prisma/generated/prisma/index.js');
const prisma = new PrismaClient();

// ─── Create / Update Profile (upsert) ─────────────────────────────────────
const createProfile = async (req, res) => {
  try {
    const { age, gender, skinType, skinGoals, budget, currentProducts, currentRoutine } = req.body;
    const userId = req.userId;

    const profile = await prisma.profile.upsert({
      where: { userId },
      update: {
        age, gender, skinType,
        skinGoals:       JSON.stringify(skinGoals),
        budget,
        currentProducts: currentProducts ? JSON.stringify(currentProducts) : '[]',
        currentRoutine:  currentRoutine || null,
      },
      create: {
        userId, age, gender, skinType,
        skinGoals:       JSON.stringify(skinGoals),
        budget,
        currentProducts: currentProducts ? JSON.stringify(currentProducts) : '[]',
        currentRoutine:  currentRoutine || null,
      },
    });

    res.status(201).json({
      message: 'Profile saved successfully',
      profile: {
        ...profile,
        skinGoals:       JSON.parse(profile.skinGoals),
        currentProducts: profile.currentProducts ? JSON.parse(profile.currentProducts) : [],
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// ─── Get Profile ───────────────────────────────────────────────────────────
const getProfile = async (req, res) => {
  try {
    const userId = req.userId;

    // DO NOT include recommendation here — it has new fields that may not
    // be migrated on production DB yet. Recommendation is fetched separately.
    const profile = await prisma.profile.findUnique({
      where: { userId },
    });

    if (!profile) {
      return res.status(404).json({ message: 'Profile not found' });
    }

    res.json({
      ...profile,
      skinGoals:       JSON.parse(profile.skinGoals),
      currentProducts: profile.currentProducts
          ? JSON.parse(profile.currentProducts)
          : [],
    });
  } catch (error) {
    console.error('getProfile error:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// ─── Update Profile ────────────────────────────────────────────────────────
const updateProfile = async (req, res) => {
  try {
    const { age, gender, skinType, skinGoals, budget, currentProducts, currentRoutine } = req.body;
    const userId = req.userId;

    const profile = await prisma.profile.upsert({
      where: { userId },
      update: {
        age, gender, skinType,
        skinGoals:       JSON.stringify(skinGoals),
        budget,
        currentProducts: currentProducts ? JSON.stringify(currentProducts) : '[]',
        currentRoutine:  currentRoutine || null,
      },
      create: {
        userId, age, gender, skinType,
        skinGoals:       JSON.stringify(skinGoals),
        budget,
        currentProducts: currentProducts ? JSON.stringify(currentProducts) : '[]',
        currentRoutine:  currentRoutine || null,
      },
    });

    res.json({
      message: 'Profile updated successfully',
      profile: {
        ...profile,
        skinGoals:       JSON.parse(profile.skinGoals),
        currentProducts: profile.currentProducts
            ? JSON.parse(profile.currentProducts)
            : [],
      },
    });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// ─── Search Products ───────────────────────────────────────────────────────
const searchProducts = async (req, res) => {
  try {
    const { query } = req.query;
    if (!query || query.length < 2) {
      return res.json({ products: [] });
    }

    const products = await prisma.product.findMany({
      where: {
        OR: [
          { name: { contains: query } },
          { brand: { contains: query } },
          { category: { contains: query } },
        ],
      },
      select: { id: true, name: true, brand: true, category: true, price: true },
      take: 10,
    });

    res.json({ products });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = { createProfile, getProfile, updateProfile, searchProducts };