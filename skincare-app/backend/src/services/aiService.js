const Groq = require('groq-sdk');
const { PrismaClient } = require('../../prisma/generated/prisma/index.js');

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
const prisma = new PrismaClient();

const generateSkincareRecommendation = async (profile) => {
  const skinGoals = JSON.parse(profile.skinGoals);
  const skinType = profile.skinType;
  const budget = profile.budget;

  // Fetch relevant products from database
  const allProducts = await prisma.product.findMany();

  // Filter products that match skin type and are within budget
  const matchingProducts = allProducts.filter(product => {
    const productSkinTypes = JSON.parse(product.skinTypes);
    const productGoals = JSON.parse(product.skinGoals);
    const withinBudget = product.price <= budget;
    const skinTypeMatch = productSkinTypes.includes(skinType);
    const goalMatch = productGoals.some(g => skinGoals.includes(g));
    return withinBudget && (skinTypeMatch || goalMatch);
  });

  // Format products for AI
 const productList = matchingProducts.map(p => ({
    id: p.id,
    name: p.name,
    brand: p.brand,
    category: p.category,
    price: p.price,
    originalPrice: p.originalPrice,
    discount: p.discount,
    description: p.description,
    howToUse: p.howToUse,
    availableAt: p.availableAt,
    rating: p.rating,
    reviewCount: p.reviewCount,
    ingredients: p.ingredients
  }));

  const prompt = `
    You are an expert dermatologist and skincare specialist. Analyze this user's profile and provide personalized skincare recommendations using ONLY the products provided below.

    USER PROFILE:
    - Age: ${profile.age}
    - Gender: ${profile.gender}
    - Skin Type: ${skinType}
    - Skin Goals: ${skinGoals.join(', ')}
    - Budget: ₹${budget} per month
    - Current Products: ${profile.currentProducts ? JSON.parse(profile.currentProducts).join(', ') : 'None'}
    - Current Routine: ${profile.currentRoutine || 'No routine currently'}

    AVAILABLE PRODUCTS FROM OUR DATABASE (recommend ONLY from this list):
    ${JSON.stringify(productList, null, 2)}

    Based on the user's profile, select the BEST products from the list above and create a personalized routine.
    Make sure total product cost stays within ₹${budget} budget.
    
    Respond ONLY with a JSON object, no extra text, no markdown:
    {
      "routine": {
        "morning": [
          {
            "step": 1,
            "action": "Cleanser",
            "instruction": "detailed instruction here",
            "duration": "60 seconds"
          }
        ],
        "evening": [
          {
            "step": 1,
            "action": "Cleanser",
            "instruction": "detailed instruction here",
            "duration": "60 seconds"
          }
        ],
        "weekly": [
          {
            "step": 1,
            "action": "Exfoliation",
            "instruction": "detailed instruction here",
            "frequency": "2x per week"
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
          "reason": "Why this specific product suits this user",
          "howToUse": "How to use instruction",
          "availableAt": "where to buy"
        }
      ],
      "tips": [
        "Tip 1 specific to user's skin type and goals",
        "Tip 2",
        "Tip 3"
      ],
      "dietAdvice": "Specific diet advice for their skin goals",
      "warnings": "Any ingredients or practices to avoid for their skin type"
    }
  `;

  const completion = await groq.chat.completions.create({
    messages: [{ role: 'user', content: prompt }],
    model: 'llama-3.3-70b-versatile',
    temperature: 0.7,
    max_tokens: 2000,
  });

  let text = completion.choices[0].message.content;
  text = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

  const recommendation = JSON.parse(text);
  return recommendation;
};

module.exports = { generateSkincareRecommendation };