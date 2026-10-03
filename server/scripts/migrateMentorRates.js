require('dotenv').config({ path: require('path').join(__dirname, '..', '..', '.env') });

const mongoose = require('mongoose');
const User = require('../../models/User');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/ymentor';
const HOURLY_FLOOR = 500;
const MONTHLY_FLOOR = 5000;

function averageFromRange(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return Math.round(value);
  const matches = String(value || '').match(/\d[\d,]*/g);
  if (!matches || matches.length === 0) return null;
  const values = matches.map((item) => Number(item.replace(/,/g, ''))).filter(Number.isFinite);
  if (values.length === 1) return Math.round(values[0]);
  return Math.round((values[0] + values[1]) / 2);
}

function surveyValue(user, keys) {
  const sources = [user.onboardingSurvey, user.onboarding, user.mentorProfile, user.pricing];
  for (const source of sources) {
    if (!source) continue;
    for (const key of keys) {
      const value = averageFromRange(source[key]);
      if (value !== null) return value;
    }
  }
  return null;
}

async function migrate() {
  await mongoose.connect(MONGODB_URI);
  const mentors = await User.find({ role: 'mentor' });
  let changed = 0;
  for (const mentor of mentors) {
    const hourly = Math.max(
      HOURLY_FLOOR,
      surveyValue(mentor, ['hourlyRange', 'hourlyRateRange', 'hourlyRate', 'hourly']) || 0,
    );
    const monthly = Math.max(
      MONTHLY_FLOOR,
      surveyValue(mentor, ['monthlyRange', 'monthlyRateRange', 'monthlyRate', 'monthly']) || 0,
    );
    mentor.hourlyRate = hourly;
    mentor.pricing = { ...(mentor.pricing?.toObject?.() || mentor.pricing || {}), hourly, monthly };
    mentor.pricingTiers = {
      tier30m: Math.round(hourly * 0.5),
      tier60m: hourly,
      tier120m: Math.round(hourly * 1.8),
    };
    mentor.mentorProfile.monthlyRate = monthly;
    await mentor.save();
    changed += 1;
  }
  console.log(`Migrated rates for ${changed} mentor(s).`);
}

migrate()
  .catch((error) => {
    console.error('Mentor rate migration failed:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.disconnect();
  });
