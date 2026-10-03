const mongoose = require('mongoose');
const User = require('../models/User');
const Booking = require('../models/Booking');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/ymentor';

async function migrate() {
  console.log(`Connecting to ${MONGODB_URI} ...`);
  await mongoose.connect(MONGODB_URI);
  console.log('Connected.');

  // 1. Fix all mentors in MongoDB
  const mentors = await User.find({ role: 'mentor' });
  console.log(`Found ${mentors.length} mentors.`);
  for (const mentor of mentors) {
    let hourly = Number(mentor.hourlyRate) || 0;
    if (hourly < 500) {
      // Fix unrealistic low test rates like 20
      hourly = 1500;
      mentor.hourlyRate = hourly;
    }
    const monthly = Math.max(Number(mentor.mentorProfile?.monthlyRate) || 0, hourly * 10);
    mentor.pricing = { hourly, monthly };
    mentor.mentorProfile = mentor.mentorProfile || {};
    mentor.mentorProfile.monthlyRate = monthly;
    mentor.pricingTiers = {
      tier30m: Math.round(hourly * 0.5),
      tier60m: hourly,
      tier120m: Math.round(hourly * 1.8),
    };
    await mentor.save();
    console.log(`Updated mentor: ${mentor.name} (${mentor.email}) -> hourlyRate: ${hourly}, tiers:`, mentor.pricingTiers);
  }

  // 2. Fix all bookings in MongoDB
  const bookings = await Booking.find({});
  console.log(`Found ${bookings.length} bookings.`);
  for (const b of bookings) {
    const mentor = await User.findById(b.mentorId);
    const hourly = mentor && mentor.hourlyRate >= 500 ? mentor.hourlyRate : 1500;
    const duration = b.durationMinutes && b.durationMinutes > 0 ? b.durationMinutes : 60;
    const gross = Math.round(hourly * (duration / 60));
    const fee = Math.round(gross * 0.20);
    const payout = Math.round(gross * 0.80);

    b.platformFee = fee;
    b.totalAmount = gross;
    b.mentorNetPayout = payout;
    b.financials = {
      currency: 'NPR',
      grossAmount: gross,
      platformCommission20Percent: fee,
      mentorNetPayout80Percent: payout,
      escrowStatus: b.escrowStatus || 'held_in_escrow',
    };
    await b.save();
    console.log(`Updated booking ${b._id}: mentor ${mentor?.name || b.mentorId}, duration ${duration}m -> gross: ${gross}, fee: ${fee}, payout: ${payout}`);
  }

  console.log('Migration completed successfully.');
  await mongoose.disconnect();
}

migrate().catch(async (err) => {
  console.error('Migration error:', err);
  await mongoose.disconnect();
  process.exit(1);
});
