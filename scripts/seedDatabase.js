/**
 * Create or migrate the two baseline Ymentor accounts in MongoDB.
 * Run with: node scripts/seedDatabase.js
 */

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const User = require('../models/User');
const Workspace = require('../models/Workspace');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/ymentor';
const adminEmail = process.env.YMENTOR_ADMIN_EMAIL?.trim().toLowerCase();
const adminPassword = process.env.YMENTOR_ADMIN_PASSWORD;

if (Boolean(adminEmail) !== Boolean(adminPassword)) {
  throw new Error('Set both YMENTOR_ADMIN_EMAIL and YMENTOR_ADMIN_PASSWORD to provision an administrator.');
}

const baselineUsers = [
  {
    legacyEmail: 'mentor.sarah@ymentor.com',
    name: 'Alex Morgan',
    email: 'alex.morgan@ymentor.com',
    password: 'AlexMentor!Ymentor2026',
    role: 'mentor',
    status: 'active',
    isOnboarded: true,
    title: 'Senior Engineer',
    hourlyRate: 2000,
    pricing: { hourly: 2000, monthly: 20000 },
    skillsOrInterests: ['AI', 'Python', 'Flutter'],
    headline: 'Senior Engineer & Technical Mentor',
    bio: 'Senior software engineer helping teams design reliable AI and mobile applications.',
    faculty: 'Software Engineering',
    qualifications: {
      degree: 'M.S. in Software Engineering',
      faculty: 'Software Engineering',
      skills: ['AI', 'Python', 'Flutter'],
    },
    pricingTiers: { tier30m: 1200, tier60m: 2000, tier120m: 3800 },
    mentorProfile: { monthlyRate: 20000, maxMentees: 5, primaryDomain: 'Software Engineering' },
    meetingUrl: 'https://meet.google.com/ymentor-alex-mentor',
    ratingAvg: 4.95,
    totalSessions: 38,
    wallet: { balance: 3200, pendingEscrow: 400 },
    walletBalance: 3200,
    isIdentityVerified: true,
    isSkillVerified: true,
  },
  {
    legacyEmail: 'student.jordan@ymentor.com',
    name: 'Sarah Chen',
    email: 'sarah.chen@ymentor.com',
    password: 'SarahStudent!Ymentor2026',
    role: 'mentee',
    status: 'active',
    isOnboarded: true,
    faculty: 'Computer Science',
    skillsOrInterests: ['AI', 'Python'],
    headline: 'Computer Science Student',
    bio: 'Computer science student building skills in software engineering and applied AI.',
    qualifications: {
      degree: 'B.S. in Computer Science',
      faculty: 'Computer Science',
      skills: ['AI', 'Python'],
    },
    pricingTiers: { tier30m: 1200, tier60m: 2000, tier120m: 3800 },
    meetingUrl: 'https://meet.google.com/abc-defg-hij',
    ratingAvg: 5.0,
    totalSessions: 2,
    wallet: { balance: 140.0, pendingEscrow: 0.0 },
    walletBalance: 140.0,
    isIdentityVerified: true,
    isSkillVerified: false,
  },
];

if (adminEmail && adminPassword) {
  baselineUsers.push({
    name: 'YMentor Administrator',
    email: adminEmail,
    password: adminPassword,
    role: 'admin',
    status: 'active',
    isOnboarded: true,
  });
}

async function run() {
  console.log(`Connecting to ${MONGODB_URI} ...`);
  await mongoose.connect(MONGODB_URI, { serverSelectionTimeoutMS: 5000 });
  console.log('Connected.');

  for (const profile of baselineUsers) {
    const { legacyEmail, ...userData } = profile;
    let user = await User.findOne({ email: userData.email.toLowerCase() });
    if (!user && legacyEmail) {
      user = await User.findOne({ email: legacyEmail.toLowerCase() });
    }

    if (!user) {
      const hashedPassword = await bcrypt.hash(userData.password, 10);
      user = new User({
        ...userData,
        email: userData.email.toLowerCase(),
        password: hashedPassword,
      });
      user.calculateLeaderboardScore();
      await user.save();
      console.log(`  + Created ${userData.role}: ${userData.email}`);
    } else if (user.email.toLowerCase() !== userData.email.toLowerCase()) {
      user.name = userData.name;
      user.email = userData.email.toLowerCase();
      user.password = await bcrypt.hash(userData.password, 10);
      user.title = userData.title || user.title;
      user.headline = userData.headline;
      user.bio = userData.bio;
      user.faculty = userData.faculty;
      user.skillsOrInterests = userData.skillsOrInterests;
      user.qualifications = userData.qualifications;
      await user.save();
      console.log(`  + Updated ${userData.role}: ${userData.email}`);
    } else {
      user.hourlyRate = userData.hourlyRate || user.hourlyRate;
      user.pricing = userData.pricing || user.pricing;
      user.mentorProfile = {
        ...(user.mentorProfile?.toObject?.() || user.mentorProfile || {}),
        ...(userData.mentorProfile || {}),
      };
      await user.save();
      console.log(`  - ${userData.email} already exists, skipping.`);
    }
  }

  const mentor = await User.findOne({ email: 'alex.morgan@ymentor.com' });
  const mentee = await User.findOne({ email: 'sarah.chen@ymentor.com' });

  if (mentor && mentee) {
    const workspace = await Workspace.findOne({
      mentorId: mentor._id,
      menteeId: mentee._id,
    });
    if (!workspace) {
      await Workspace.create({
        mentorId: mentor._id,
        menteeId: mentee._id,
        topic: 'AI Systems Architecture & Flutter Mentorship',
      });
      console.log('  + Created baseline workspace');
    }
  }

  console.log('\nBaseline account setup complete.');
  console.log('  Mentor: Alex Morgan (alex.morgan@ymentor.com)');
  console.log('  Mentee: Sarah Chen (sarah.chen@ymentor.com)');
  await mongoose.disconnect();
}

run().catch(async (err) => {
  console.error('Seed setup failed:', err);
  await mongoose.disconnect();
  process.exitCode = 1;
});
