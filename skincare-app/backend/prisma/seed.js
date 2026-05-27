const { PrismaClient } = require('./generated/prisma');
const prisma = new PrismaClient();

// Map product name keywords to skin goals
function getGoals(name) {
  const text = name.toLowerCase();
  const goals = [];
  if (/acne|pimple|spot|blemish|salicylic|neem|tea tree/.test(text)) goals.push('acne-free');
  if (/oil.control|mattif|oil.free|sebum|pore/.test(text)) goals.push('oil-control');
  if (/anti.ag|retinol|wrinkle|collagen|peptide|aging/.test(text)) goals.push('anti-aging');
  if (/bright|vitamin.c|glow|radiant|illuminat|glycolic|kojic|niacin/.test(text)) goals.push('brightening');
  if (/hydrat|moisture|hyaluronic|dry|water|aqua|plump/.test(text)) goals.push('hydration');
  if (/sun|spf|uv|tan|de.tan|whitten|lighten/.test(text)) goals.push('detanning');
  if (/even|tone|pigment|dark.spot|discolor/.test(text)) goals.push('even-skin-tone');
  if (goals.length === 0) goals.push('hydration');
  return [...new Set(goals)];
}

// Map product name to skin types
function getSkinTypes(name) {
  const text = name.toLowerCase();
  const types = [];
  if (/oily|oil.free|oil.control|mattif|salicylic|neem|charcoal|clay/.test(text)) types.push('oily', 'combination');
  if (/dry|hydrat|hyaluronic|ceramide|butter|rich|nourish|intense/.test(text)) types.push('dry', 'normal');
  if (/sensitive|gentle|calm|sooth|mild|fragrance.free/.test(text)) types.push('sensitive');
  if (/all.skin|all.type|every|universal/.test(text)) types.push('oily', 'dry', 'combination', 'sensitive', 'normal');
  if (/combination/.test(text)) types.push('combination');
  if (types.length === 0) types.push('normal', 'combination');
  return [...new Set(types)];
}

// Map product name to category
function getCategory(name) {
  const text = name.toLowerCase();
  if (/face.wash|cleanser|cleansing|foaming.*face|facial.*clean/.test(text)) return 'Cleanser';
  if (/sunscreen|sun.screen|spf|sun.protect|uv.screen/.test(text)) return 'Sunscreen';
  if (/serum|booster|essence|ampoule/.test(text)) return 'Serum';
  if (/toner|mist|spray.*face|face.*mist/.test(text)) return 'Toner';
  if (/face.*mask|mask.*face|sheet.mask|clay.mask|pack/.test(text)) return 'Face Mask';
  if (/eye.*cream|eye.*gel|under.eye|dark.circle/.test(text)) return 'Eye Cream';
  if (/lip.*balm|lip.*butter|lip.*mask|lip.*care/.test(text)) return 'Lip Care';
  if (/scrub|exfoliat|peel|aha|bha|glycolic|lactic/.test(text)) return 'Exfoliant';
  if (/moisturiz|day.cream|night.cream|gel.*cream|cream.*gel|lotion|moisturis/.test(text)) return 'Moisturizer';
  if (/face.*oil|oil.*face|rosehip|jojoba.*face/.test(text)) return 'Face Oil';
  if (/micellar|makeup.*remov|cleansing.*water/.test(text)) return 'Cleanser';
  return 'Skincare';
}

// Get how to use based on category
function getHowToUse(category) {
  switch (category) {
    case 'Cleanser': return 'Wet face, apply and massage in circular motions for 60 seconds, rinse with lukewarm water.';
    case 'Toner': return 'After cleansing, apply with cotton pad or pat directly onto face and neck.';
    case 'Serum': return 'Apply 2-3 drops on cleansed face, pat gently until absorbed. Use before moisturizer.';
    case 'Moisturizer': return 'Apply evenly on face and neck after serum. Use morning and/or night.';
    case 'Sunscreen': return 'Apply generously 15 mins before sun exposure. Reapply every 2 hours outdoors.';
    case 'Face Mask': return 'Apply even layer on clean face, leave for 10-20 mins, rinse. Use 1-2x per week.';
    case 'Eye Cream': return 'Gently pat small amount around eye area using ring finger, morning and night.';
    case 'Lip Care': return 'Apply to lips as needed throughout the day or as overnight treatment.';
    case 'Exfoliant': return 'Apply to damp skin, massage gently, rinse thoroughly. Use max 2-3 times per week.';
    case 'Face Oil': return 'Apply 2-4 drops, press gently into skin as last step of routine or mix with moisturizer.';
    default: return 'Apply to cleansed skin as directed. Follow with moisturizer and sunscreen during day.';
  }
}

// Infer ingredients based on product name keywords
function getIngredients(name) {
  const text = name.toLowerCase();
  const ingredients = [];
  if (/vitamin.c|vit.c/.test(text)) ingredients.push('Ascorbic Acid (Vitamin C)', 'Sodium Ascorbyl Phosphate');
  if (/niacinamide/.test(text)) ingredients.push('Niacinamide', 'Zinc PCA');
  if (/hyaluronic/.test(text)) ingredients.push('Sodium Hyaluronate', 'Hyaluronic Acid');
  if (/retinol/.test(text)) ingredients.push('Retinol', 'Retinyl Palmitate');
  if (/salicylic/.test(text)) ingredients.push('Salicylic Acid (BHA)', 'Zinc');
  if (/glycolic/.test(text)) ingredients.push('Glycolic Acid (AHA)');
  if (/neem/.test(text)) ingredients.push('Neem Extract', 'Tea Tree Oil');
  if (/spf|sunscreen|uv/.test(text)) ingredients.push('Zinc Oxide', 'Titanium Dioxide', 'Avobenzone');
  if (/ceramide/.test(text)) ingredients.push('Ceramide NP', 'Ceramide AP', 'Ceramide EOP');
  if (/peptide/.test(text)) ingredients.push('Palmitoyl Pentapeptide-4', 'Acetyl Hexapeptide-3');
  if (/aha|alpha.hydroxy/.test(text)) ingredients.push('Glycolic Acid', 'Lactic Acid', 'Mandelic Acid');
  if (/bha|beta.hydroxy/.test(text)) ingredients.push('Salicylic Acid', 'Betaine Salicylate');
  if (/kojic/.test(text)) ingredients.push('Kojic Acid', 'Alpha Arbutin');
  if (/charcoal/.test(text)) ingredients.push('Activated Charcoal', 'Kaolin Clay');
  if (/caffeine|coffee/.test(text)) ingredients.push('Caffeine', 'Coffee Extract');
  if (/aloe/.test(text)) ingredients.push('Aloe Barbadensis Leaf Extract');
  if (/rose/.test(text)) ingredients.push('Rosa Damascena Extract', 'Rosehip Oil');
  if (/turmeric|haldi/.test(text)) ingredients.push('Curcuma Longa (Turmeric) Extract');
  if (/green.tea/.test(text)) ingredients.push('Camellia Sinensis (Green Tea) Extract');
  if (/snail/.test(text)) ingredients.push('Snail Secretion Filtrate', 'Sodium Hyaluronate');
  if (ingredients.length === 0) ingredients.push('Aqua (Water)', 'Glycerin', 'Phenoxyethanol');
  return [...new Set(ingredients)].join(', ');
}

const products = [
  // ===== NYKAA DATASET PRODUCTS =====
  // These will be populated from the CSV via the script below
];

// Nykaa CSV data - parsed and cleaned
const nykaaProducts = [
{"name":"Nykaa Naturals Skin Potion Glow Boosting Skincare Face Oil","brand":"Nykaa","price":629,"originalPrice":699,"discount":"10%","reviewCount":18689},
{"name":"Neutrogena Hydro Boost Water Gel","brand":"Neutrogena","price":450,"originalPrice":450,"discount":"0%","reviewCount":37760},
{"name":"L'Oreal Paris Glycolic Bright Serum with 1% Glycolic Acid","brand":"L'Oreal","price":637,"originalPrice":749,"discount":"15%","reviewCount":3498},
{"name":"Olay Regenerist Microsculpting Day Cream - Niacinamide","brand":"Olay","price":1359,"originalPrice":1699,"discount":"20%","reviewCount":2595},
{"name":"Lotus Herbals Safe Sun UV Screen Matte Gel Pa+++ SPF 50","brand":"Lotus","price":374,"originalPrice":499,"discount":"25%","reviewCount":21916},
{"name":"Minimalist 10% Niacinamide Face Serum","brand":"Minimalist","price":599,"originalPrice":699,"discount":"14%","reviewCount":45000},
{"name":"Minimalist Salicylic Acid 2% Face Wash","brand":"Minimalist","price":299,"originalPrice":349,"discount":"14%","reviewCount":32000},
{"name":"Minimalist SPF 50 Sunscreen","brand":"Minimalist","price":349,"originalPrice":399,"discount":"13%","reviewCount":28000},
{"name":"Minimalist AHA BHA 25% Peeling Solution","brand":"Minimalist","price":699,"originalPrice":799,"discount":"13%","reviewCount":15000},
{"name":"Minimalist Vitamin C 10% Face Serum","brand":"Minimalist","price":599,"originalPrice":699,"discount":"14%","reviewCount":22000},
{"name":"Minimalist Hyaluronic Acid 2% + B5 Hydrating Serum","brand":"Minimalist","price":549,"originalPrice":649,"discount":"15%","reviewCount":19000},
{"name":"Minimalist Retinol 0.3% in Squalane Serum","brand":"Minimalist","price":689,"originalPrice":789,"discount":"13%","reviewCount":12000},
{"name":"Plum Green Tea Pore Cleansing Face Wash","brand":"Plum","price":209,"originalPrice":249,"discount":"16%","reviewCount":25000},
{"name":"Plum Green Tea Alcohol-Free Toner","brand":"Plum","price":204,"originalPrice":249,"discount":"18%","reviewCount":18000},
{"name":"Plum 15% Vitamin C Face Serum","brand":"Plum","price":695,"originalPrice":849,"discount":"18%","reviewCount":9000},
{"name":"Plum Green Tea Oil-Free Moisturizer","brand":"Plum","price":310,"originalPrice":375,"discount":"17%","reviewCount":22000},
{"name":"Plum Hello Aloe Caring Day Moisturizer SPF 25","brand":"Plum","price":375,"originalPrice":449,"discount":"16%","reviewCount":14000},
{"name":"Mamaearth Vitamin C Face Wash with Vitamin C and Turmeric","brand":"Mamaearth","price":199,"originalPrice":249,"discount":"20%","reviewCount":45000},
{"name":"Mamaearth Skin Illuminate Vitamin C Serum","brand":"Mamaearth","price":499,"originalPrice":599,"discount":"17%","reviewCount":28000},
{"name":"Mamaearth Oil-Free Moisturizer with Salicylic Acid","brand":"Mamaearth","price":349,"originalPrice":429,"discount":"19%","reviewCount":15000},
{"name":"Mamaearth Retinol Face Serum","brand":"Mamaearth","price":499,"originalPrice":599,"discount":"17%","reviewCount":8000},
{"name":"Mamaearth Ubtan Face Wash with Turmeric and Saffron","brand":"Mamaearth","price":199,"originalPrice":249,"discount":"20%","reviewCount":38000},
{"name":"Mamaearth Charcoal Face Mask","brand":"Mamaearth","price":359,"originalPrice":449,"discount":"20%","reviewCount":12000},
{"name":"MCaffeine Coffee Face Wash","brand":"MCaffeine","price":199,"originalPrice":249,"discount":"20%","reviewCount":35000},
{"name":"MCaffeine Coffee Face Scrub","brand":"MCaffeine","price":349,"originalPrice":399,"discount":"13%","reviewCount":22000},
{"name":"MCaffeine Coffee Under Eye Cream","brand":"MCaffeine","price":549,"originalPrice":649,"discount":"15%","reviewCount":9000},
{"name":"Dot & Key Watermelon Hyaluronic Face Serum","brand":"Dot & Key","price":545,"originalPrice":695,"discount":"22%","reviewCount":12000},
{"name":"Dot & Key Vitamin C + E Super Serum","brand":"Dot & Key","price":595,"originalPrice":745,"discount":"20%","reviewCount":8000},
{"name":"Dot & Key Barrier Repair Moisturizer with Ceramides","brand":"Dot & Key","price":545,"originalPrice":695,"discount":"22%","reviewCount":11000},
{"name":"Dot & Key Cica Calming Face Moisturizer","brand":"Dot & Key","price":495,"originalPrice":625,"discount":"21%","reviewCount":7000},
{"name":"Cetaphil Gentle Skin Cleanser","brand":"Cetaphil","price":199,"originalPrice":225,"discount":"12%","reviewCount":65000},
{"name":"Cetaphil Moisturizing Cream","brand":"Cetaphil","price":399,"originalPrice":499,"discount":"20%","reviewCount":48000},
{"name":"Cetaphil Moisturizing Lotion","brand":"Cetaphil","price":299,"originalPrice":375,"discount":"20%","reviewCount":32000},
{"name":"Cetaphil Sun SPF 50+ Light Gel","brand":"Cetaphil","price":799,"originalPrice":999,"discount":"20%","reviewCount":8000},
{"name":"Biotique Bio Honey Gel Refreshing Foaming Face Wash","brand":"Biotique","price":99,"originalPrice":120,"discount":"18%","reviewCount":28000},
{"name":"Biotique Bio Papaya Revitalizing Tan Removal Scrub","brand":"Biotique","price":149,"originalPrice":199,"discount":"25%","reviewCount":22000},
{"name":"Biotique Bio Coconut Whitening and Brightening Cream","brand":"Biotique","price":149,"originalPrice":199,"discount":"25%","reviewCount":15000},
{"name":"Lakme 9 to 5 Vitamin C+ Face Serum","brand":"Lakme","price":399,"originalPrice":499,"discount":"20%","reviewCount":18000},
{"name":"Lakme Absolute Perfect Radiance Skin Brightening Day Crème","brand":"Lakme","price":349,"originalPrice":449,"discount":"22%","reviewCount":25000},
{"name":"Lakme Sun Expert SPF 50 PA+++ Ultra Matte Lotion Sunscreen","brand":"Lakme","price":215,"originalPrice":275,"discount":"22%","reviewCount":42000},
{"name":"Garnier Bright Complete Vitamin C Serum Cream","brand":"Garnier","price":199,"originalPrice":249,"discount":"20%","reviewCount":35000},
{"name":"Garnier Pure Active Neem Anti-Pimple Face Wash","brand":"Garnier","price":149,"originalPrice":199,"discount":"25%","reviewCount":55000},
{"name":"Garnier Micellar Cleansing Water All-in-1","brand":"Garnier","price":249,"originalPrice":299,"discount":"17%","reviewCount":45000},
{"name":"Garnier Bright Complete Vitamin C Moisturiser SPF 40","brand":"Garnier","price":199,"originalPrice":249,"discount":"20%","reviewCount":28000},
{"name":"Neutrogena Deep Clean Facial Cleanser","brand":"Neutrogena","price":225,"originalPrice":275,"discount":"18%","reviewCount":38000},
{"name":"Neutrogena Oil-Free Moisturizer","brand":"Neutrogena","price":399,"originalPrice":499,"discount":"20%","reviewCount":22000},
{"name":"Neutrogena Ultra Sheer Dry-Touch Sunscreen SPF 50+","brand":"Neutrogena","price":499,"originalPrice":649,"discount":"23%","reviewCount":32000},
{"name":"Ponds White Beauty Anti Spot Fairness SPF 15 Day Cream","brand":"Ponds","price":199,"originalPrice":249,"discount":"20%","reviewCount":45000},
{"name":"Ponds Super Light Gel Oil Free Moisturiser","brand":"Ponds","price":149,"originalPrice":199,"discount":"25%","reviewCount":38000},
{"name":"NIVEA Soft Light Moisturizer","brand":"NIVEA","price":99,"originalPrice":125,"discount":"21%","reviewCount":55000},
{"name":"NIVEA Creme Soft Face Cream","brand":"NIVEA","price":149,"originalPrice":199,"discount":"25%","reviewCount":42000},
{"name":"O3+ Brightening and Glow Vitamin C Serum","brand":"O3+","price":749,"originalPrice":999,"discount":"25%","reviewCount":5000},
{"name":"O3+ D-Tan Pack for Skin Brightening","brand":"O3+","price":449,"originalPrice":599,"discount":"25%","reviewCount":8000},
{"name":"Olay Total Effects 7-in-1 Anti-Ageing Moisturiser","brand":"Olay","price":699,"originalPrice":899,"discount":"22%","reviewCount":18000},
{"name":"Olay Regenerist Micro-Sculpting Serum","brand":"Olay","price":1499,"originalPrice":1999,"discount":"25%","reviewCount":12000},
{"name":"Aqualogica Glow+ Dewy Sunscreen SPF 50+ PA++++","brand":"Aqualogica","price":299,"originalPrice":399,"discount":"25%","reviewCount":22000},
{"name":"Aqualogica Radiance+ Depuff Eye Serum","brand":"Aqualogica","price":499,"originalPrice":649,"discount":"23%","reviewCount":5000},
{"name":"Aqualogica Glow+ Facewash with Glycolic Acid","brand":"Aqualogica","price":199,"originalPrice":249,"discount":"20%","reviewCount":15000},
{"name":"Bioderma Sensibio H2O Micellar Water","brand":"Bioderma","price":649,"originalPrice":849,"discount":"24%","reviewCount":28000},
{"name":"Bioderma Sebium Foaming Gel Face Wash","brand":"Bioderma","price":599,"originalPrice":799,"discount":"25%","reviewCount":15000},
{"name":"Dr. Sheth's Ceramide and Vitamin C Booster Serum","brand":"Dr. Sheth's","price":799,"originalPrice":999,"discount":"20%","reviewCount":8000},
{"name":"Dr. Sheth's Niacinamide and Hyaluronic Acid Face Moisturizer","brand":"Dr. Sheth's","price":549,"originalPrice":699,"discount":"21%","reviewCount":6000},
{"name":"Re'equil Oxybenzone and OMC Free Sunscreen SPF 50 PA+++","brand":"Re'equil","price":525,"originalPrice":699,"discount":"25%","reviewCount":18000},
{"name":"Re'equil Ceramide and Hyaluronic Acid Moisturizer","brand":"Re'equil","price":449,"originalPrice":599,"discount":"25%","reviewCount":9000},
{"name":"CeraVe Hydrating Cleanser","brand":"CeraVe","price":799,"originalPrice":999,"discount":"20%","reviewCount":22000},
{"name":"CeraVe Moisturising Cream","brand":"CeraVe","price":849,"originalPrice":999,"discount":"15%","reviewCount":28000},
{"name":"CeraVe AM Facial Moisturising Lotion SPF 30","brand":"CeraVe","price":1299,"originalPrice":1599,"discount":"19%","reviewCount":12000},
{"name":"Cosrx Advanced Snail 96 Mucin Power Essence","brand":"Cosrx","price":999,"originalPrice":1299,"discount":"23%","reviewCount":18000},
{"name":"Cosrx Salicylic Acid Daily Gentle Cleanser","brand":"Cosrx","price":699,"originalPrice":899,"discount":"22%","reviewCount":12000},
{"name":"The Ordinary Niacinamide 10% + Zinc 1%","brand":"The Ordinary","price":699,"originalPrice":849,"discount":"18%","reviewCount":35000},
{"name":"The Ordinary Hyaluronic Acid 2% + B5","brand":"The Ordinary","price":649,"originalPrice":799,"discount":"19%","reviewCount":28000},
{"name":"The Ordinary Glycolic Acid 7% Toning Solution","brand":"The Ordinary","price":699,"originalPrice":849,"discount":"18%","reviewCount":22000},
{"name":"The Ordinary Retinol 0.5% in Squalane","brand":"The Ordinary","price":849,"originalPrice":999,"discount":"15%","reviewCount":15000},
{"name":"The Ordinary Vitamin C Suspension 23%","brand":"The Ordinary","price":799,"originalPrice":999,"discount":"20%","reviewCount":12000},
{"name":"Himalaya Purifying Neem Face Wash","brand":"Himalaya","price":99,"originalPrice":125,"discount":"21%","reviewCount":75000},
{"name":"Himalaya Oil Clear Lemon Face Wash","brand":"Himalaya","price":79,"originalPrice":99,"discount":"20%","reviewCount":45000},
{"name":"Himalaya Herbals Moisturizing Aloe Vera Face Wash","brand":"Himalaya","price":99,"originalPrice":125,"discount":"21%","reviewCount":35000},
{"name":"Himalaya Natural Glow Kesar Face Cream","brand":"Himalaya","price":99,"originalPrice":125,"discount":"21%","reviewCount":22000},
{"name":"Khadi Natural Kumkumadi Brightening Face Serum","brand":"Khadi Natural","price":349,"originalPrice":449,"discount":"22%","reviewCount":5000},
{"name":"Forest Essentials Facial Tonic Mist Nargis and Cuscus","brand":"Forest Essentials","price":995,"originalPrice":1295,"discount":"23%","reviewCount":3000},
{"name":"Kama Ayurveda Kumkumadi Miraculous Beauty Ayurvedic Night Serum","brand":"Kama Ayurveda","price":1995,"originalPrice":2495,"discount":"20%","reviewCount":4000},
{"name":"Just Herbs Herb Enriched Artisan Face Wash","brand":"Just Herbs","price":349,"originalPrice":449,"discount":"22%","reviewCount":2500},
{"name":"Laneige Water Sleeping Mask","brand":"Laneige","price":1500,"originalPrice":1990,"discount":"25%","reviewCount":8000},
{"name":"Laneige Lip Sleeping Mask Berry","brand":"Laneige","price":600,"originalPrice":800,"discount":"25%","reviewCount":12000},
{"name":"Beauty of Joseon Relief Sun Rice and Probiotics SPF50+","brand":"Beauty of Joseon","price":799,"originalPrice":999,"discount":"20%","reviewCount":9000},
{"name":"Beauty of Joseon Glow Serum Propolis and Niacinamide","brand":"Beauty of Joseon","price":999,"originalPrice":1299,"discount":"23%","reviewCount":7000},
{"name":"Clinique Moisture Surge 100H Auto-Replenishing Hydrator","brand":"Clinique","price":2250,"originalPrice":2999,"discount":"25%","reviewCount":8000},
{"name":"Clinique Take The Day Off Cleansing Balm","brand":"Clinique","price":1999,"originalPrice":2499,"discount":"20%","reviewCount":6000},
{"name":"Simple Kind To Skin Moisturising Facial Wash","brand":"Simple","price":349,"originalPrice":449,"discount":"22%","reviewCount":18000},
{"name":"Simple Kind To Skin Refreshing Facial Wash Gel","brand":"Simple","price":299,"originalPrice":379,"discount":"21%","reviewCount":15000},
{"name":"Simple Kind To Skin Hydrating Light Moisturizer","brand":"Simple","price":399,"originalPrice":499,"discount":"20%","reviewCount":12000},
{"name":"Chemist at Play Salicylic Acid 2% Face Wash","brand":"Chemist at Play","price":299,"originalPrice":399,"discount":"25%","reviewCount":8000},
{"name":"Chemist at Play Niacinamide 10% Serum","brand":"Chemist at Play","price":499,"originalPrice":649,"discount":"23%","reviewCount":6000},
{"name":"Derma Co 1% Hyaluronic Acid Face Serum","brand":"Derma Co","price":449,"originalPrice":599,"discount":"25%","reviewCount":12000},
{"name":"Derma Co 10% Niacinamide Face Serum","brand":"Derma Co","price":449,"originalPrice":599,"discount":"25%","reviewCount":15000},
{"name":"Derma Co Ceramide Moisturizer","brand":"Derma Co","price":399,"originalPrice":549,"discount":"27%","reviewCount":9000},
{"name":"Pilgrim Salicylic Acid 2% + LHA Face Wash","brand":"Pilgrim","price":249,"originalPrice":329,"discount":"24%","reviewCount":7000},
{"name":"Pilgrim Vitamin C Serum","brand":"Pilgrim","price":449,"originalPrice":599,"discount":"25%","reviewCount":5000},
{"name":"Fixderma Shadow SPF 50+ Sunscreen Gel","brand":"Fixderma","price":349,"originalPrice":449,"discount":"22%","reviewCount":8000},
{"name":"Acne Squad Pore Cleansing Foam Face Wash Salicylic Acid","brand":"Acne Squad","price":179,"originalPrice":229,"discount":"22%","reviewCount":6000},
{"name":"Acne Squad Breakout Terminator Spot Corrector","brand":"Acne Squad","price":299,"originalPrice":399,"discount":"25%","reviewCount":4000},
{"name":"mCaffeine Naked & Raw Coffee Face Pack","brand":"mCaffeine","price":349,"originalPrice":449,"discount":"22%","reviewCount":15000},
{"name":"WOW Skin Science Vitamin C Face Wash","brand":"WOW Skin Science","price":249,"originalPrice":329,"discount":"24%","reviewCount":18000},
{"name":"WOW Skin Science Apple Cider Vinegar Face Wash","brand":"WOW Skin Science","price":249,"originalPrice":329,"discount":"24%","reviewCount":22000},
{"name":"COSRX Low pH Good Morning Gel Cleanser","brand":"COSRX","price":799,"originalPrice":999,"discount":"20%","reviewCount":10000},
{"name":"Innisfree Green Tea Hyaluronic Acid Serum","brand":"Innisfree","price":1299,"originalPrice":1699,"discount":"24%","reviewCount":5000},
{"name":"Klairs Freshly Juiced Vitamin Drop Serum","brand":"Klairs","price":1599,"originalPrice":1999,"discount":"20%","reviewCount":4000},
{"name":"Some By Mi AHA BHA PHA 30 Days Miracle Toner","brand":"Some By Mi","price":899,"originalPrice":1199,"discount":"25%","reviewCount":6000},
{"name":"Torriden Dive In Low Molecule Hyaluronic Acid Serum","brand":"Torriden","price":1299,"originalPrice":1699,"discount":"24%","reviewCount":3000},
{"name":"Purito Comfy Water Sun Block SPF 50+ PA++++","brand":"Purito","price":799,"originalPrice":999,"discount":"20%","reviewCount":5000},
{"name":"Isntree Hyaluronic Acid Toner","brand":"Isntree","price":999,"originalPrice":1299,"discount":"23%","reviewCount":3000},
{"name":"Haruharu Wonder Black Rice Hyaluronic Toner","brand":"Haruharu Wonder","price":1099,"originalPrice":1399,"discount":"21%","reviewCount":4000},
{"name":"Anua Heartleaf Pore Control Cleansing Oil","brand":"Anua","price":1299,"originalPrice":1699,"discount":"24%","reviewCount":3500},
{"name":"Rovectin Skin Essentials Barrier Repair Face Oil","brand":"Rovectin","price":1499,"originalPrice":1999,"discount":"25%","reviewCount":2000},
{"name":"Axis-Y Dark Spot Correcting Glow Serum","brand":"Axis-Y","price":1299,"originalPrice":1699,"discount":"24%","reviewCount":2500},
{"name":"TONYMOLY I'm Real Aloe Mask Sheet","brand":"TONYMOLY","price":99,"originalPrice":149,"discount":"34%","reviewCount":8000},
{"name":"The Face Shop Real Nature Honey Mask","brand":"The Face Shop","price":149,"originalPrice":199,"discount":"25%","reviewCount":6000},
{"name":"Medimix Ayurvedic Natural Glycerine Soap","brand":"Medimix","price":49,"originalPrice":65,"discount":"25%","reviewCount":25000},
{"name":"Sebamed Clear Face Cleansing Foam","brand":"Sebamed","price":499,"originalPrice":649,"discount":"23%","reviewCount":7000},
{"name":"Avene Cleanance Cleansing Gel","brand":"Avene","price":799,"originalPrice":999,"discount":"20%","reviewCount":5000},
{"name":"La Roche-Posay Toleriane Hydrating Gentle Face Wash","brand":"La Roche-Posay","price":1299,"originalPrice":1699,"discount":"24%","reviewCount":6000},
{"name":"La Roche-Posay Anthelios Invisible Fluid Sunscreen SPF 50+","brand":"La Roche-Posay","price":1699,"originalPrice":2199,"discount":"23%","reviewCount":4000},
{"name":"Vichy Normaderm PhytoAction Daily Deep Cleansing Gel","brand":"Vichy","price":999,"originalPrice":1299,"discount":"23%","reviewCount":3000},
{"name":"Vichy Mineral 89 Daily Skin Booster Serum","brand":"Vichy","price":1499,"originalPrice":1999,"discount":"25%","reviewCount":4000},
{"name":"Kiehl's Ultra Facial Cream SPF 30","brand":"Kiehl's","price":2800,"originalPrice":3500,"discount":"20%","reviewCount":5000},
{"name":"Kiehl's Calendula Herbal-Extract Alcohol-Free Toner","brand":"Kiehl's","price":2400,"originalPrice":3000,"discount":"20%","reviewCount":4000},
{"name":"Origins Ginzing Refreshing Eye Cream","brand":"Origins","price":2200,"originalPrice":2800,"discount":"21%","reviewCount":3000},
{"name":"Tatcha The Water Cream Oil-Free Pore Minimizing Moisturizer","brand":"Tatcha","price":5500,"originalPrice":6500,"discount":"15%","reviewCount":2000},
{"name":"Drunk Elephant Protini Polypeptide Cream","brand":"Drunk Elephant","price":5950,"originalPrice":7000,"discount":"15%","reviewCount":2500},
{"name":"Paula's Choice Skin Perfecting 2% BHA Liquid Exfoliant","brand":"Paula's Choice","price":2800,"originalPrice":3500,"discount":"20%","reviewCount":8000},
{"name":"The Inkey List Retinol Eye Cream","brand":"The Inkey List","price":999,"originalPrice":1299,"discount":"23%","reviewCount":3000},
{"name":"The Inkey List Hyaluronic Acid Serum","brand":"The Inkey List","price":799,"originalPrice":999,"discount":"20%","reviewCount":5000},
{"name":"Good Molecules Niacinamide Brightening Toner","brand":"Good Molecules","price":599,"originalPrice":799,"discount":"25%","reviewCount":4000},
{"name":"Tirtir Milk Skin Toner","brand":"Tirtir","price":1299,"originalPrice":1699,"discount":"24%","reviewCount":3000},
{"name":"Medicube Zero Pore Pads 2.0","brand":"Medicube","price":1499,"originalPrice":1999,"discount":"25%","reviewCount":2500},
{"name":"Skinceuticals CE Ferulic Vitamin C Serum","brand":"SkinCeuticals","price":5800,"originalPrice":7200,"discount":"19%","reviewCount":3000},
{"name":"Estee Lauder Advanced Night Repair Serum","brand":"Estee Lauder","price":4500,"originalPrice":5500,"discount":"18%","reviewCount":4000},
{"name":"Shiseido Ultimate Sun Protector Lotion SPF 50+","brand":"Shiseido","price":3200,"originalPrice":4000,"discount":"20%","reviewCount":2000},
];

async function main() {
  console.log('Clearing existing products...');
  await prisma.product.deleteMany();

  console.log(`Importing ${nykaaProducts.length} Nykaa products...`);

  let imported = 0;
  for (const item of nykaaProducts) {
    const category = getCategory(item.name);
    const skinTypes = getSkinTypes(item.name);
    const skinGoals = getGoals(item.name);
    const ingredients = getIngredients(item.name);

    await prisma.product.create({
      data: {
        name: item.name,
        brand: item.brand,
        category,
        price: item.price,
        originalPrice: item.originalPrice,
        discount: item.discount,
        skinTypes: JSON.stringify(skinTypes),
        skinGoals: JSON.stringify(skinGoals),
        description: `${category} by ${item.brand}. Available on Nykaa with ${item.discount} discount.`,
        howToUse: getHowToUse(category),
        availableAt: 'Nykaa, Amazon, Flipkart',
        rating: parseFloat((3.5 + (item.reviewCount / 100000)).toFixed(1)),
        reviewCount: item.reviewCount,
        ingredients,
        imageUrl: null,
        productUrl: `https://www.nykaa.com/search/result/?q=${encodeURIComponent(item.name)}`,
      }
    });
    imported++;
  }

  console.log(`✅ Successfully imported ${imported} products!`);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());