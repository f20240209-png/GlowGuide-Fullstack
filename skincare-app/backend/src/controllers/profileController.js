const { PrismaClient } = require('../../prisma/generated/prisma/index.js');

const prisma = new PrismaClient();

// Create Profile
const createProfile = async (req, res) => {
  try {
    const { age, gender, skinType, skinGoals, budget, currentProducts, currentRoutine } = req.body;
    const userId = req.userId;

    // Check if profile already exists
    const existingProfile = await prisma.profile.findUnique({ where: { userId } });
    if (existingProfile) {
      return res.status(400).json({ message: 'Profile already exists. Use PUT to update.' });
    }

    const profile = await prisma.profile.create({
      data: {
        userId,
        age,
        gender,
        skinType,
        skinGoals: JSON.stringify(skinGoals),
        budget,
        currentProducts: currentProducts ? JSON.stringify(currentProducts) : null,
        currentRoutine: currentRoutine || null
      }
    });

    res.status(201).json({
      message: 'Profile created successfully',
      profile: {
        ...profile,
        skinGoals: JSON.parse(profile.skinGoals),
        currentProducts: profile.currentProducts ? JSON.parse(profile.currentProducts) : null
      }
    });

  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Get Profile
const getProfile = async (req, res) => {
  try {
    const userId = req.userId;

    const profile = await prisma.profile.findUnique({
      where: { userId },
      include: { recommendation: true }
    });

    if (!profile) {
      return res.status(404).json({ message: 'Profile not found' });
    }

    res.json({
      ...profile,
      skinGoals: JSON.parse(profile.skinGoals),
      currentProducts: profile.currentProducts ? JSON.parse(profile.currentProducts) : null,
      recommendation: profile.recommendation ? {
        ...profile.recommendation,
        routine: JSON.parse(profile.recommendation.routine),
        products: JSON.parse(profile.recommendation.products)
      } : null
    });

  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Update Profile
const updateProfile = async (req, res) => {
  try {
    const { age, gender, skinType, skinGoals, budget, currentProducts, currentRoutine } = req.body;
    const userId = req.userId;

    const profile = await prisma.profile.update({
      where: { userId },
      data: {
        age,
        gender,
        skinType,
        skinGoals: JSON.stringify(skinGoals),
        budget,
        currentProducts: currentProducts ? JSON.stringify(currentProducts) : null,
        currentRoutine: currentRoutine || null
      }
    });

    res.json({
      message: 'Profile updated successfully',
      profile: {
        ...profile,
        skinGoals: JSON.parse(profile.skinGoals),
        currentProducts: profile.currentProducts ? JSON.parse(profile.currentProducts) : null
      }
    });

  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Search products by name
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
          { category: { contains: query } }
        ]
      },
      select: {
        id: true,
        name: true,
        brand: true,
        category: true,
        price: true
      },
      take: 10
    });

    res.json({ products });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = { createProfile, getProfile, updateProfile, searchProducts };

