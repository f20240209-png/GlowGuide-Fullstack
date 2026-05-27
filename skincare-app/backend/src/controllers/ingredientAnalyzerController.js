const { PrismaClient } = require('../../prisma/generated/prisma/index.js');
const prisma = new PrismaClient();

const analyzeRoutine = async (req, res) => {
  try {
    const { ingredients } = req.body;

    if (!ingredients || !Array.isArray(ingredients) || ingredients.length === 0) {
      return res.status(400).json({ message: 'Please provide an array of ingredients' });
    }

    // Normalize ingredients to lowercase
    const normalizedIngredients = ingredients.map(i => i.toLowerCase().trim());

    // Fetch all conflicts from database
    const allConflicts = await prisma.ingredient_Conflict.findMany();

    const foundConflicts = [];

    // Check every pair of submitted ingredients against conflict table
    for (const conflict of allConflicts) {
      const a = conflict.ingredientA.toLowerCase();
      const b = conflict.ingredientB.toLowerCase();

      // Check if both conflicting ingredients are present
      const hasA = normalizedIngredients.some(i =>
        i.includes(a) || a.includes(i)
      );
      const hasB = normalizedIngredients.some(i =>
        i.includes(b) || b.includes(i)
      );

      if (hasA && hasB) {
        // Avoid duplicate conflicts
        const alreadyAdded = foundConflicts.some(
          c => c.ingredientA === conflict.ingredientA &&
               c.ingredientB === conflict.ingredientB
        );
        if (!alreadyAdded) {
          foundConflicts.push({
            id: conflict.id,
            ingredientA: conflict.ingredientA,
            ingredientB: conflict.ingredientB,
            severityLevel: conflict.severityLevel,
            warningMessage: conflict.warningMessage,
          });
        }
      }
    }

    // Sort by severity — High first
    foundConflicts.sort((a, b) =>
      a.severityLevel === 'High' ? -1 : 1
    );

    res.json({
      totalIngredients: normalizedIngredients.length,
      totalConflicts: foundConflicts.length,
      conflicts: foundConflicts,
      safe: foundConflicts.length === 0,
    });

  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = { analyzeRoutine };