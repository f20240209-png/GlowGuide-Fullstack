const Groq = require('groq-sdk');
const { PrismaClient } = require('../../prisma/generated/prisma/index.js');

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
const prisma = new PrismaClient();

const generateSkincareRecommendation = async (profile) => {
  const skinGoals = JSON.parse(profile.skinGoals);
  const skinType = profile.skinType;
  const budget = profile.budget;
  const currentProducts = profile.currentProducts
    ? JSON.parse(profile.currentProducts)
    : [];
  const currentRoutine = profile.currentRoutine || '';

  // ── STEP 1: Fetch matching products from DB ──────────────────
  const allProducts = await prisma.product.findMany();

  const matchingProducts = allProducts.filter(product => {
    const productSkinTypes = JSON.parse(product.skinTypes);
    const productGoals = JSON.parse(product.skinGoals);
    const withinBudget = product.price <= budget;
    const skinTypeMatch = productSkinTypes.includes(skinType);
    const goalMatch = productGoals.some(g => skinGoals.includes(g));
    return withinBudget && (skinTypeMatch || goalMatch);
  });

  // [RESTORED FROM OLD CODE]: Take top 15 by rating to stay within token limits!
  const limitedProducts = matchingProducts
    .sort((a, b) => b.rating - a.rating)
    .slice(0, 15);

  // [RESTORED FROM OLD CODE]: Strip heavy fields — AI doesn't need descriptions for selection
  const productList = limitedProducts.map(p => ({
    id:            p.id,
    name:          p.name,
    brand:         p.brand,
    category:      p.category,
    price:         p.price,
    originalPrice: p.originalPrice,
    discount:      p.discount,
    rating:        p.rating,
    reviewCount:   p.reviewCount,
  }));

  // ── STEP 2: Analyze current products first (Claude's Logic) ──
  const hasCurrentProducts = currentProducts.length > 0;

  const analysisPrompt = hasCurrentProducts ? `
    You are an expert dermatologist. Analyze if these current skincare products are effective for the user's goals.

    USER PROFILE:
    - Skin Type: ${skinType}
    - Skin Goals: ${skinGoals.join(', ')}
    - Budget: ₹${budget}/month
    - Current Products: ${currentProducts.join(', ')}
    - Current Routine: ${currentRoutine || 'None described'}

    Analyze each current product and determine:
    1. Is it suitable for ${skinType} skin?
    2. Does it help achieve: ${skinGoals.join(', ')}?
    3. Overall — are these products EFFECTIVE or NOT_EFFECTIVE for the goals?

    Respond ONLY with this JSON, no extra text:
    {
      "verdict": "EFFECTIVE" or "NOT_EFFECTIVE",
      "analysis": [
        {
          "product": "product name",
          "suitable": true/false,
          "reason": "brief reason why it helps or doesn't help the goal"
        }
      ],
      "summary": "One sentence summary of the analysis"
    }
  ` : null;

  let productAnalysis = null;
  let isEffective = false;

  if (hasCurrentProducts) {
    try {
      const analysisCompletion = await groq.chat.completions.create({
        messages: [{ role: 'user', content: analysisPrompt }],
        model: 'llama-3.3-70b-versatile',
        temperature: 0.3,
        max_tokens: 1000,
      });

      let analysisText = analysisCompletion.choices[0].message.content;
      analysisText = analysisText.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
      productAnalysis = JSON.parse(analysisText);
      isEffective = productAnalysis.verdict === 'EFFECTIVE';
    } catch (e) {
      console.log('Analysis error:', e.message);
      isEffective = false; // Fallback to generating new routine if analysis fails
    }
  }

  // ── STEP 3: Generate routine based on analysis ───────────────
  const routinePrompt = `
    You are an expert dermatologist. Generate a personalized skincare routine.

    USER PROFILE:
    - Age: ${profile.age || 'Not specified'}
    - Gender: ${profile.gender || 'Not specified'}
    - Skin Type: ${skinType}
    - Skin Goals: ${skinGoals.join(', ')}
    - Budget: ₹${budget}/month
    - Current Products: ${hasCurrentProducts ? currentProducts.join(', ') : 'None'}
    - Products Effective: ${isEffective ? 'YES - keep current products and supplement with recommended' : 'NO - recommend new products'}

    ${isEffective ? `
    INSTRUCTION: The user's current products ARE effective. 
    - Keep their current products in the routine
    - Add a few RECOMMENDED products from the database list below (mark them as recommended_to_buy: true)
    - Stay within ₹${budget} budget for recommended products
    ` : `
    INSTRUCTION: The user's current products are NOT effective (or they have none).
    - Recommend entirely new products from the database list below
    - Stay within ₹${budget} total budget
    `}

    AVAILABLE PRODUCTS FROM DATABASE (use ONLY from this list):
    ${JSON.stringify(productList)}

    Respond ONLY with this JSON, no extra text, no markdown:
    {
      "routine": {
        "morning": [
          {
            "step": 1,
            "action": "Cleanser",
            "instruction": "detailed instruction",
            "duration": "60 seconds",
            "product": "product name if applicable",
            "isCurrentProduct": true
          }
        ],
        "evening": [
          {
            "step": 1,
            "action": "Cleanser",
            "instruction": "detailed instruction",
            "duration": "60 seconds",
            "product": "product name if applicable",
            "isCurrentProduct": true
          }
        ],
        "weekly": [
          {
            "step": 1,
            "action": "Exfoliation",
            "instruction": "detailed instruction",
            "frequency": "2x per week",
            "product": "product name if applicable",
            "isCurrentProduct": false
          }
        ]
      },
      "products": [
        {
          "id": 1,
          "category": "Cleanser",
          "name": "exact product name from list",
          "brand": "exact brand from list",
          "price": 299,
          "originalPrice": 399,
          "discount": "25%",
          "reason": "why this product suits this user",
          "howToUse": "how to use",
          "availableAt": "Nykaa, Amazon",
          "rating": 4.5,
          "reviewCount": 15000,
          "recommended_to_buy": true,
          "isCurrentProduct": false
        }
      ],
      "tips": [
        "Tip 1",
        "Tip 2",
        "Tip 3"
      ],
      "dietAdvice": "diet advice for skin goals",
      "warnings": "ingredients or practices to avoid",
"goodFoods": [
  {"name": "Food name", "benefit": "why good for their skin goals"}
],
"avoidFoods": [
  {"name": "Food name", "reason": "why bad for their skin goals"}
]
    }
  `;

  const completion = await groq.chat.completions.create({
    messages: [{ role: 'user', content: routinePrompt }],
    model: 'llama-3.3-70b-versatile',
    temperature: 0.7,
    max_tokens: 3000,
  });

  let text = completion.choices[0].message.content;
  text = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

  const recommendation = JSON.parse(text);

  // Attach analysis payload so your Flutter frontend can show the transition screen results!
  recommendation.productAnalysis = productAnalysis;
  recommendation.isEffective = isEffective;
  recommendation.hasCurrentProducts = hasCurrentProducts;

  return recommendation;
};

module.exports = { generateSkincareRecommendation };