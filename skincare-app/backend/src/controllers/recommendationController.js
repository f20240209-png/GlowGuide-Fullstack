const { PrismaClient } = require('../../prisma/generated/prisma/index.js');
const { generateSkincareRecommendation } = require('../services/aiService');

const prisma = new PrismaClient();

const getRecommendation = async (req, res) => {
  try {
    const userId = req.userId;

    // Get user profile
    const profile = await prisma.profile.findUnique({
      where: { userId },
      include: { user: true }
    });

    if (!profile) {
      return res.status(404).json({ message: 'Profile not found. Please create your profile first.' });
    }

    // Check if recommendation already exists
    const existingRec = await prisma.recommendation.findUnique({
      where: { profileId: profile.id }
    });

    if (existingRec) {
      return res.json({
        message: 'Recommendation retrieved successfully',
        recommendation: {
          ...existingRec,
          routine: JSON.parse(existingRec.routine),
          products: JSON.parse(existingRec.products)
        }
      });
    }

    // Generate new recommendation using AI
    console.log('Generating AI recommendation for user:', userId);
    const aiRecommendation = await generateSkincareRecommendation(profile);

    // Save to database
    const recommendation = await prisma.recommendation.create({
      data: {
        profileId: profile.id,
        routine: JSON.stringify(aiRecommendation.routine),
        products: JSON.stringify(aiRecommendation.products)
      }
    });

    res.status(201).json({
      message: 'Recommendation generated successfully',
      recommendation: {
        ...recommendation,
        routine: aiRecommendation.routine,
        products: aiRecommendation.products,
        tips: aiRecommendation.tips,
        dietAdvice: aiRecommendation.dietAdvice,
        warnings: aiRecommendation.warnings
      }
    });

  } catch (error) {
    console.error('Recommendation error:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const refreshRecommendation = async (req, res) => {
  try {
    const userId = req.userId;

    const profile = await prisma.profile.findUnique({
      where: { userId },
      include: { user: true }
    });

    if (!profile) {
      return res.status(404).json({ message: 'Profile not found.' });
    }

    // Generate fresh recommendation
    const aiRecommendation = await generateSkincareRecommendation(profile);

    // Update or create
    const recommendation = await prisma.recommendation.upsert({
      where: { profileId: profile.id },
      update: {
        routine: JSON.stringify(aiRecommendation.routine),
        products: JSON.stringify(aiRecommendation.products)
      },
      create: {
        profileId: profile.id,
        routine: JSON.stringify(aiRecommendation.routine),
        products: JSON.stringify(aiRecommendation.products)
      }
    });

    res.json({
      message: 'Recommendation refreshed successfully',
      recommendation: {
        ...recommendation,
        routine: aiRecommendation.routine,
        products: aiRecommendation.products,
        tips: aiRecommendation.tips,
        dietAdvice: aiRecommendation.dietAdvice,
        warnings: aiRecommendation.warnings
      }
    });

  } catch (error) {
    console.error('Refresh error:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = { getRecommendation, refreshRecommendation };