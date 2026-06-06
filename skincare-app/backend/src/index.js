const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const authRoutes = require('./routes/authRoutes');
const profileRoutes = require('./routes/profileRoutes');
const recommendationRoutes = require('./routes/recommendationRoutes');
const skincareLogRoutes = require('./routes/skincareLogRoutes');
const ingredientRoutes = require('./routes/ingredientRoutes');
const communityRoutes = require('./routes/communityRoutes');

const app = express();

app.use(cors({
  origin: ['http://localhost:57132', 'http://localhost:3000', 'http://localhost','https://inquisitive-clafoutis-600746.netlify.app'],
  credentials: true
}));

// Add these headers for Google Sign In popup to work
app.use((req, res, next) => {
  res.setHeader('Cross-Origin-Opener-Policy', 'same-origin-allow-popups');
  res.setHeader('Cross-Origin-Embedder-Policy', 'unsafe-none');
  next();
});

app.use(express.json({ limit: '10mb' }));
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.get('/', (req, res) => {
  res.json({ message: 'Skincare App API is running!' });
});

app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/recommendations', recommendationRoutes);
app.use('/api/logs', skincareLogRoutes);
app.use('/api', ingredientRoutes);
app.use('/api/community', communityRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log('Server running on http://localhost:' + PORT);
});