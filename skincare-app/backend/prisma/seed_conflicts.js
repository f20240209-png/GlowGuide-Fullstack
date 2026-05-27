const { PrismaClient } = require('./generated/prisma');
const prisma = new PrismaClient();

const conflicts = [
  // HIGH SEVERITY
  {
    ingredientA: 'retinol',
    ingredientB: 'aha',
    severityLevel: 'High',
    warningMessage: 'Retinol + AHA (Alpha Hydroxy Acids) together causes severe irritation, redness and skin sensitivity. Use Retinol at night and AHA on alternate nights.'
  },
  {
    ingredientA: 'retinol',
    ingredientB: 'bha',
    severityLevel: 'High',
    warningMessage: 'Retinol + BHA (Salicylic Acid) causes extreme dryness and peeling. Alternate their use on different nights instead.'
  },
  {
    ingredientA: 'retinol',
    ingredientB: 'salicylic acid',
    severityLevel: 'High',
    warningMessage: 'Retinol + Salicylic Acid is too harsh for skin. Both are exfoliants and together they cause severe irritation and barrier damage.'
  },
  {
    ingredientA: 'retinol',
    ingredientB: 'glycolic acid',
    severityLevel: 'High',
    warningMessage: 'Retinol + Glycolic Acid together disrupts skin pH balance and causes excessive peeling and redness. Never use together.'
  },
  {
    ingredientA: 'retinol',
    ingredientB: 'lactic acid',
    severityLevel: 'High',
    warningMessage: 'Retinol + Lactic Acid causes over-exfoliation leading to raw, irritated skin. Alternate on different nights.'
  },
  {
    ingredientA: 'retinol',
    ingredientB: 'benzoyl peroxide',
    severityLevel: 'High',
    warningMessage: 'Retinol + Benzoyl Peroxide oxidizes retinol making it ineffective. They cancel each other out and irritate skin.'
  },
  {
    ingredientA: 'vitamin c',
    ingredientB: 'aha',
    severityLevel: 'High',
    warningMessage: 'Vitamin C + AHA together is too acidic for skin. Can cause redness, stinging and compromise skin barrier. Use Vitamin C in morning, AHA at night.'
  },
  {
    ingredientA: 'vitamin c',
    ingredientB: 'bha',
    severityLevel: 'High',
    warningMessage: 'Vitamin C + BHA (Salicylic Acid) both are acidic and together cause pH imbalance leading to irritation and reduced efficacy.'
  },
  {
    ingredientA: 'vitamin c',
    ingredientB: 'retinol',
    severityLevel: 'High',
    warningMessage: 'Vitamin C + Retinol degrade each other when used together. Use Vitamin C in morning routine and Retinol in evening routine.'
  },
  {
    ingredientA: 'benzoyl peroxide',
    ingredientB: 'aha',
    severityLevel: 'High',
    warningMessage: 'Benzoyl Peroxide + AHA causes extreme skin irritation, over-drying and redness. Never layer these together.'
  },
  {
    ingredientA: 'benzoyl peroxide',
    ingredientB: 'vitamin c',
    severityLevel: 'High',
    warningMessage: 'Benzoyl Peroxide oxidizes Vitamin C making it completely ineffective. Use them at separate times of day.'
  },
  {
    ingredientA: 'copper peptides',
    ingredientB: 'vitamin c',
    severityLevel: 'High',
    warningMessage: 'Copper Peptides + Vitamin C react together and become destabilized. Use them in separate routines or on alternate days.'
  },
  {
    ingredientA: 'copper peptides',
    ingredientB: 'aha',
    severityLevel: 'High',
    warningMessage: 'Copper Peptides + AHA acids break down the peptide bonds making both ineffective and can irritate skin.'
  },

  // MEDIUM SEVERITY
  {
    ingredientA: 'vitamin c',
    ingredientB: 'niacinamide',
    severityLevel: 'Medium',
    warningMessage: 'Vitamin C + Niacinamide may reduce effectiveness of Vitamin C and can cause skin flushing in some people. Modern stable formulas may be okay but use cautiously. Apply separately with a gap.'
  },
  {
    ingredientA: 'retinol',
    ingredientB: 'niacinamide',
    severityLevel: 'Medium',
    warningMessage: 'Retinol + Niacinamide is generally fine but Niacinamide may slightly reduce Retinol absorption. Apply Niacinamide first and wait 15-20 mins before Retinol.'
  },
  {
    ingredientA: 'spf',
    ingredientB: 'aha',
    severityLevel: 'Medium',
    warningMessage: 'SPF + AHA can reduce sunscreen effectiveness. Always apply AHA at night and use SPF in the morning only.'
  },
  {
    ingredientA: 'hyaluronic acid',
    ingredientB: 'aha',
    severityLevel: 'Medium',
    warningMessage: 'Hyaluronic Acid + AHA — AHA exfoliates while Hyaluronic Acid hydrates. Apply Hyaluronic Acid after AHA has dried (15 mins gap) to avoid diluting the acid.'
  },
  {
    ingredientA: 'hyaluronic acid',
    ingredientB: 'bha',
    severityLevel: 'Medium',
    warningMessage: 'Hyaluronic Acid + BHA — wait 15-20 minutes after applying BHA before layering Hyaluronic Acid to allow BHA to work at the right pH.'
  },
  {
    ingredientA: 'kojic acid',
    ingredientB: 'vitamin c',
    severityLevel: 'Medium',
    warningMessage: 'Kojic Acid + Vitamin C together can cause skin sensitivity and irritation in some skin types. Patch test first and use on alternate days if irritation occurs.'
  },
  {
    ingredientA: 'salicylic acid',
    ingredientB: 'niacinamide',
    severityLevel: 'Medium',
    warningMessage: 'Salicylic Acid + Niacinamide can be used together but Niacinamide may slightly reduce Salicylic Acid efficacy. Apply Salicylic Acid first, wait 15 mins, then apply Niacinamide.'
  },
  {
    ingredientA: 'glycolic acid',
    ingredientB: 'salicylic acid',
    severityLevel: 'Medium',
    warningMessage: 'Glycolic Acid + Salicylic Acid — two exfoliants together cause over-exfoliation leading to dryness and sensitivity. Use them on alternate days.'
  },
  {
    ingredientA: 'lactic acid',
    ingredientB: 'salicylic acid',
    severityLevel: 'Medium',
    warningMessage: 'Lactic Acid + Salicylic Acid together over-exfoliates skin. Use them on different days to avoid irritation.'
  },
  {
    ingredientA: 'peptides',
    ingredientB: 'aha',
    severityLevel: 'Medium',
    warningMessage: 'Peptides + AHA — acids break down peptide bonds reducing effectiveness. Apply peptides in the morning and AHA at night.'
  },
  {
    ingredientA: 'peptides',
    ingredientB: 'vitamin c',
    severityLevel: 'Medium',
    warningMessage: 'Peptides + Vitamin C — low pH of Vitamin C can deactivate peptides. Use Vitamin C serum first, wait 20-30 mins, then apply peptide products.'
  },
  {
    ingredientA: 'retinol',
    ingredientB: 'kojic acid',
    severityLevel: 'Medium',
    warningMessage: 'Retinol + Kojic Acid together increases photosensitivity and skin irritation. If using both, apply on alternate nights.'
  },
  {
    ingredientA: 'alpha arbutin',
    ingredientB: 'aha',
    severityLevel: 'Medium',
    warningMessage: 'Alpha Arbutin + AHA — high acid concentration can convert arbutin to hydroquinone which may cause issues for sensitive skin. Use with caution.'
  },
  {
    ingredientA: 'spf',
    ingredientB: 'retinol',
    severityLevel: 'Medium',
    warningMessage: 'SPF + Retinol — Retinol degrades in sunlight so always use Retinol at night only. Applying SPF over Retinol in the same routine is fine for sun protection.'
  },
];

async function main() {
  console.log('Seeding ingredient conflicts...');
  await prisma.ingredient_Conflict.deleteMany();

  for (const conflict of conflicts) {
    await prisma.ingredient_Conflict.create({ data: conflict });
  }

  console.log(`✅ Seeded ${conflicts.length} ingredient conflicts!`);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());