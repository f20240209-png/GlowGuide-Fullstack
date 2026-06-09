const { PrismaClient } = require('../../prisma/generated/prisma/index.js');
const { generateSkincareRecommendation } = require('../services/aiService');

const prisma = new PrismaClient();

const getRecommendation = async (req, res) => {
  try {
    const userId = req.userId;

    const profile = await prisma.profile.findUnique({
      where: { userId },
      include: { user: true }
    });

    if (!profile) {
      return res.status(404).json({
        message: 'Profile not found. Please create your profile first.'
      });
    }

    const existingRec = await prisma.recommendation.findUnique({
      where: { profileId: profile.id }
    });

    if (existingRec) {
      return res.json({
        message: 'Recommendation retrieved successfully',
        recommendation: {
          ...existingRec,
          routine: JSON.parse(existingRec.routine),
          products: JSON.parse(existingRec.products),
          productAnalysis: existingRec.productAnalysis
            ? JSON.parse(existingRec.productAnalysis)
            : null,
          isEffective: existingRec.isEffective,
          hasCurrentProducts: existingRec.hasCurrentProducts,
        }
      });
    }

    console.log('Generating AI recommendation for user:', userId);
    const aiRecommendation = await generateSkincareRecommendation(profile);

    const recommendation = await prisma.recommendation.create({
      data: {
        profileId: profile.id,
        routine: JSON.stringify(aiRecommendation.routine),
        products: JSON.stringify(aiRecommendation.products),
        productAnalysis: JSON.stringify(aiRecommendation.productAnalysis),
        isEffective: aiRecommendation.isEffective,
        hasCurrentProducts: aiRecommendation.hasCurrentProducts,
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
        warnings: aiRecommendation.warnings,
        productAnalysis: aiRecommendation.productAnalysis,
        isEffective: aiRecommendation.isEffective,
        hasCurrentProducts: aiRecommendation.hasCurrentProducts,
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

    const aiRecommendation = await generateSkincareRecommendation(profile);

    const recommendation = await prisma.recommendation.upsert({
      where: { profileId: profile.id },
      update: {
        routine: JSON.stringify(aiRecommendation.routine),
        products: JSON.stringify(aiRecommendation.products),
        productAnalysis: JSON.stringify(aiRecommendation.productAnalysis),
        isEffective: aiRecommendation.isEffective,
        hasCurrentProducts: aiRecommendation.hasCurrentProducts,
      },
      create: {
        profileId: profile.id,
        routine: JSON.stringify(aiRecommendation.routine),
        products: JSON.stringify(aiRecommendation.products),
        productAnalysis: JSON.stringify(aiRecommendation.productAnalysis),
        isEffective: aiRecommendation.isEffective,
        hasCurrentProducts: aiRecommendation.hasCurrentProducts,
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
        warnings: aiRecommendation.warnings,
        productAnalysis: aiRecommendation.productAnalysis,
        isEffective: aiRecommendation.isEffective,
        hasCurrentProducts: aiRecommendation.hasCurrentProducts,
      }
    });

  } catch (error) {
    console.error('Refresh error:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = { getRecommendation, refreshRecommendation };