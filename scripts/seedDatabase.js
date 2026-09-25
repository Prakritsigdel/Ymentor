/**
 * Baseline Seed Script for MongoDB
 * Run with: node scripts/seedDatabase.js
 *
 * Populates ONLY the 3 baseline demo accounts:
 * - Admin: admin@ymentor.com / admin123
 * - Mentor: mentor.sarah@ymentor.com / mentor123
 * - Mentee: student.jordan@ymentor.com / student123
 */

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const User = require('../models/User');
const Booking = require('../models/Booking');
const Workspace = require('../models/Workspace');
const Note = require('../models/Note');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/ymentor';

const baselineUsers = [
  {
    name: 'System Administrator',
    email: 'admin@ymentor.com',
    password: 'admin123',
    role: 'admin',
    status: 'active',
    isOnboarded: true,
    headline: 'Platform Arbiter & Admin',
    bio: 'Ymentor Lead Administrator managing verification, escrow disputes, and platform health.',
    faculty: 'System Administration',
    skillsOrInterests: ['System Administration', 'Compliance', 'Security'],
    hourlyRate: 0,
    wallet: { balance: 500.0, pendingEscrow: 0.0 },
    walletBalance: 500.0,
    isIdentityVerified: true,
    isSkillVerified: true,
  },
  {
    name: 'Sarah Connor',
    email: 'mentor.sarah@ymentor.com',
    password: 'mentor123',
    role: 'mentor',
    status: 'active',
    isOnboarded: true,
    title: 'Senior AI Engineer',
    hourlyRate: 20,
    skillsOrInterests: ['AI', 'Python', 'Flutter'],
    headline: 'Senior AI Engineer & Tech Lead',
    bio: 'Senior AI Engineer specializing in production LLMs, PyTorch pipelines, and performant Flutter interfaces.',
    faculty: 'Computer Science & AI',
    qualifications: {
      degree: 'M.S. in Computer Science',
      faculty: 'Computer Science & AI',
      skills: ['AI', 'Python', 'Flutter'],
      githubUrl: 'https://github.com/sarah-ai-ymentor',
      linkedinUrl: 'https://linkedin.com/in/sarah-connor-ymentor',
    },
    pricingTiers: { tier30m: 12.0, tier60m: 20.0, tier120m: 38.0 },
    meetingUrl: 'https://meet.google.com/ymentor-sarah-mentor',
    ratingAvg: 4.95,
    totalSessions: 38,
    wallet: { balance: 320.0, pendingEscrow: 16.0 },
    walletBalance: 320.0,
    isIdentityVerified: true,
    isSkillVerified: true,
  },
  {
    name: 'Jordan Cole',
    email: 'student.jordan@ymentor.com',
    password: 'student123',
    role: 'mentee',
    status: 'active',
    isOnboarded: true,
    faculty: 'Computer Science',
    skillsOrInterests: ['AI', 'Python'],
    headline: 'Aspiring Mobile & AI Software Engineer',
    bio: 'Computer Science undergrad passionate about machine learning systems and cross-platform Flutter development.',
    qualifications: {
      degree: 'B.S. in Computer Science (Candidate)',
      faculty: 'Computer Science',
      skills: ['AI', 'Python'],
      githubUrl: 'https://github.com/jordan-cole-student',
      linkedinUrl: 'https://linkedin.com/in/jordan-cole',
    },
    pricingTiers: { tier30m: 12.0, tier60m: 20.0, tier120m: 38.0 },
    meetingUrl: 'https://meet.google.com/abc-defg-hij',
    ratingAvg: 5.0,
    totalSessions: 2,
    wallet: { balance: 140.0, pendingEscrow: 0.0 },
    walletBalance: 140.0,
    isIdentityVerified: true,
    isSkillVerified: false,
  },
];

async function run() {
  console.log(`Connecting to ${MONGODB_URI} ...`);
  await mongoose.connect(MONGODB_URI, { serverSelectionTimeoutMS: 5000 });
  console.log('Connected.');

  for (const u of baselineUsers) {
    const existing = await User.findOne({ email: u.email.toLowerCase() });
    if (existing) {
      console.log(`  - ${u.email} already exists, skipping.`);
    } else {
      const hashedPassword = await bcrypt.hash(u.password, 10);
      const user = new User({
        ...u,
        email: u.email.toLowerCase(),
        password: hashedPassword,
      });
      user.calculateLeaderboardScore();
      await user.save();
      console.log(`  + Created ${u.role}: ${u.email}`);
    }
  }

  const sarah = await User.findOne({ email: 'mentor.sarah@ymentor.com' });
  const jordan = await User.findOne({ email: 'student.jordan@ymentor.com' });

  if (sarah && jordan) {
    let ws = await Workspace.findOne({ mentorId: sarah._id, menteeId: jordan._id });
    if (!ws) {
      ws = await Workspace.create({
        mentorId: sarah._id,
        menteeId: jordan._id,
        topic: 'AI Systems Architecture & Flutter Mentorship',
      });
      console.log('  + Created baseline workspace');
    }
  }

  console.log('\n✅ Auto-seed baseline complete.');
  console.log('Baseline accounts:');
  console.log('  1. Admin:  admin@ymentor.com / admin123');
  console.log('  2. Mentor: mentor.sarah@ymentor.com / mentor123');
  console.log('  3. Mentee: student.jordan@ymentor.com / student123');
  await mongoose.disconnect();
  process.exit(0);
}

run().catch((err) => {
  console.error('Seed error:', err);
  process.exit(1);
});
