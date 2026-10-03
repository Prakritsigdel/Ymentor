const User = require('../models/User');

const demoMentors = [
  ['Alex Rivera', 2500, 25000, 'alex.rivera@ymentor.com'],
  ['Alex Morgan', 2000, 20000, 'mentor@ymentor.com'],
  ['Dipesh Sunar', 1200, 12000, 'dipesh.sunar@ymentor.com'],
  ['Nirhang Limbu', 1000, 10000, 'nirhang.limbu@ymentor.com'],
];

async function seedMentor() {
  const seeded = [];
  for (const [name, hourly, monthly, email] of demoMentors) {
    seeded.push(await User.findOneAndUpdate(
      { email },
      {
        $set: {
          name,
          role: 'mentor',
          status: 'active',
          hourlyRate: hourly,
          pricing: { hourly, monthly },
          pricingTiers: {
            tier30m: Math.round(hourly * 0.5),
            tier60m: hourly,
            tier120m: Math.round(hourly * 1.8),
          },
          walletBalance: 5000,
          'wallet.balance': 5000,
          'mentorProfile.monthlyRate': monthly,
          'mentorProfile.maxMentees': 5,
          isOnboarded: true,
          currency: 'NPR',
        },
        $setOnInsert: {
          email,
          password: 'change-me-before-production',
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    ));
  }
  return seeded;
}

module.exports = { seedMentor, demoMentors };
