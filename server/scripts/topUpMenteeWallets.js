require('dotenv').config({ path: require('path').join(__dirname, '..', '..', '.env') });

const mongoose = require('mongoose');
const User = require('../../models/User');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/ymentor';

async function topUp() {
  await mongoose.connect(MONGODB_URI);
  const result = await User.updateMany(
    { role: 'mentee' },
    { $set: { walletBalance: 40000, 'wallet.balance': 40000 } },
  );
  console.log(`Credited NPR 40,000 to ${result.modifiedCount} mentee account(s).`);
}

topUp()
  .catch((error) => {
    console.error('Mentee wallet top-up failed:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await mongoose.disconnect();
  });
