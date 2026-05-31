const Groq = require('groq-sdk');
const { PrismaClient } = require('../../prisma/generated/prisma/index.js');

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
const prisma = new PrismaClient();

const generateSkincareRecommendation = async (profile) => {
  const skinGoals = JSON.parse(profile.skinGoals);
  const skinType  = profile.skinType;
  const budget    = profile.budget;

  // Fetch all products from database
  const allProducts = await prisma.product.findMany();

  // Filter products matching skin type, goals, and budget
  const matchingProducts = allProducts.filter(product => {
    const productSkinTypes = JSON.parse(product.skinTypes);
    const productGoals     = JSON.parse(product.skinGoals);
    const withinBudget     = product.price <= budget;
    const skinTypeMatch    = productSkinTypes.includes(skinType);
    const goalMatch        = productGoals.some(g => skinGoals.includes(g));
    return withinBudget && (skinTypeMatch || goalMatch);
  });

  // Take top 15 by rating to stay within token limits
  const limitedProducts = matchingProducts
    .sort((a, b) => b.rating - a.rating)
    .slice(0, 15);

  // Strip heavy fields — AI doesn't need them for selection
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

  const prompt = `
You are an expert dermatologist and skincare specialist. Create a personalized skincare routine using ONLY the products listed below.

USER PROFILE:
- Age: ${profile.age}
- Gender: ${profile.gender}
- Skin Type: ${skinType}
- Skin Goals: ${skinGoals.join(', ')}
- Budget: ₹${budget}/month
- Current Products: ${profile.currentProducts ? JSON.parse(profile.currentProducts).join(', ') : 'None'}
- Current Routine: ${profile.currentRoutine || 'None'}

AVAILABLE PRODUCTS (recommend ONLY from this list, do not invent products):
${JSON.stringify(productList)}

Rules:
- Keep total product cost within ₹${budget}
- Choose products that best match the user's skin type and goals
- Respond ONLY with a valid JSON object, no markdown, no extra text

{
  "routine": {
    "morning": [
      {
        "step": 1,
        "action": "Cleanser",
        "instruction": "detailed application instruction",
        "duration": "60 seconds"
      }
    ],
    "evening": [
      {
        "step": 1,
        "action": "Cleanser",
        "instruction": "detailed application instruction",
        "duration": "60 seconds"
      }
    ],
    "weekly": [
      {
        "step": 1,
        "action": "Exfoliation",
        "instruction": "detailed application instruction",
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
      "originalPrice": 349,
      "discount": "14%",
      "rating": 4.5,
      "reviewCount": 32000,
      "reason": "why this product suits this user specifically",
      "howToUse": "step by step application instructions",
      "availableAt": "Nykaa, Amazon, Flipkart"
    }
  ],
  "tips": [
    "Specific tip 1 for this user's skin type and goals",
    "Specific tip 2",
    "Specific tip 3"
  ],
  "dietAdvice": "Specific diet advice for their skin goals",
  "warnings": "Ingredients or practices to avoid for their skin type"
}`;

  const completion = await groq.chat.completions.create({
    messages:    [{ role: 'user', content: prompt }],
    model:       'llama-3.3-70b-versatile',
    temperature: 0.7,
    max_tokens:  2000,
  });

  let text = completion.choices[0].message.content;
  text = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

  const recommendation = JSON.parse(text);
  return recommendation;
};

module.exports = { generateSkincareRecommendation };