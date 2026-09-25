/**
 * One-time seed script for real MongoDB.
 * Run with: node scripts/seedDatabase.js
 *
 * Populates the same demo mentors / mentee / workspace / note / booking
 * that server.js used to create automatically in its in-memory fallback.
 * Safe to re-run: it skips any user whose email already exists.
 */

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const User = require('../models/User');
const Booking = require('../models/Booking');
const Workspace = require('../models/Workspace');
const Note = require('../models/Note');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/ymentor';
const DEMO_PASSWORD = 'password123';

const mentorsData = [
  {
    name: 'Dr. Sarah Lin',
    email: 'sarah.lin@ymentor.demo',
    headline: 'Staff Distributed Systems Engineer @ Stripe',
    bio: 'Ex-Google Cloud Principal. 12+ years building high-throughput payment architectures, Kafka clusters, and mentoring senior ICs on Staff+ promotions.',
    avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
    qualifications: {
      degree: 'Ph.D. in Distributed Systems',
      faculty: 'MIT Computer Science & AI Lab',
      skills: ['System Design', 'Go', 'Kubernetes', 'High Concurrency', 'Architecture'],
      githubUrl: 'https://github.com/sarah-lin-dist',
      linkedinUrl: 'https://linkedin.com/in/sarah-lin',
    },
    pricingTiers: { tier30m: 14.0, tier60m: 24.0, tier120m: 45.0 },
    meetingUrl: 'https://meet.google.com/ymentor-sarah-lin',
    ratingAvg: 4.98,
    totalSessions: 142,
    walletBalance: 2480.0,
  },
  {
    name: 'Alex Rivera',
    email: 'alex.rivera@ymentor.demo',
    headline: 'Lead Mobile Architect & Flutter Core Contributor',
    bio: 'Crafting 60fps Flutter apps for 10M+ MAU fintech products. Specializing in state management (Riverpod/Bloc), custom shaders, and cross-platform native plugins.',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    qualifications: {
      degree: 'B.S. in Software Engineering',
      faculty: 'Stanford University',
      skills: ['Flutter', 'Dart', 'Mobile Architecture', 'iOS/Android', 'Performance'],
      githubUrl: 'https://github.com/alex-rivera-dart',
      linkedinUrl: 'https://linkedin.com/in/alex-rivera',
    },
    pricingTiers: { tier30m: 12.0, tier60m: 20.0, tier120m: 38.0 },
    meetingUrl: 'https://meet.google.com/ymentor-alex-rivera',
    ratingAvg: 4.95,
    totalSessions: 98,
    walletBalance: 1568.0,
  },
  {
    name: 'Marcus Vance',
    email: 'marcus.vance@ymentor.demo',
    headline: 'Senior Backend & DB Specialist @ Datadog',
    bio: 'Mastering MongoDB aggregations, query indexing, Node.js event-loop tuning, and Microservices decomposition. Mentored 40+ junior devs into senior roles.',
    avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    qualifications: {
      degree: 'M.S. in Information Systems',
      faculty: 'Carnegie Mellon University',
      skills: ['Node.js', 'MongoDB', 'Express', 'Redis', 'Database Tuning'],
      githubUrl: 'https://github.com/marcus-vance-io',
      linkedinUrl: 'https://linkedin.com/in/marcus-vance',
    },
    pricingTiers: { tier30m: 10.0, tier60m: 18.0, tier120m: 34.0 },
    meetingUrl: 'https://meet.google.com/ymentor-marcus-vance',
    ratingAvg: 4.92,
    totalSessions: 84,
    walletBalance: 1210.0,
  },
  {
    name: 'Elena Rostova',
    email: 'elena.rostova@ymentor.demo',
    headline: 'Principal AI & Python Systems Engineer',
    bio: 'Production LLMs, vector database pipelines (Pinecone/Qdrant), LangChain architectures, and robust Python microservices.',
    avatarUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80',
    qualifications: {
      degree: 'M.S. in Artificial Intelligence',
      faculty: 'ETH Zurich',
      skills: ['Python', 'System Design', 'FastAPI', 'MLOps', 'PyTorch'],
      githubUrl: 'https://github.com/elena-ai',
      linkedinUrl: 'https://linkedin.com/in/elena-rostova',
    },
    pricingTiers: { tier30m: 15.0, tier60m: 28.0, tier120m: 52.0 },
    meetingUrl: 'https://meet.google.com/ymentor-elena-rostova',
    ratingAvg: 4.96,
    totalSessions: 61,
    walletBalance: 1360.0,
  },
];

const menteeData = {
  name: 'Jordan Cole',
  email: 'jordan.cole@gmail.com',
  headline: 'Aspiring Mobile & Cloud Engineer',
  bio: 'Learning Flutter and modern backend microservices. Preparing for tech interviews.',
  avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80',
  qualifications: {
    degree: 'B.S. Candidate',
    faculty: 'Computer Science',
    skills: ['Flutter', 'Dart', 'JavaScript'],
    githubUrl: 'https://github.com/jordan-cole',
    linkedinUrl: 'https://linkedin.com/in/jordan-cole',
  },
  pricingTiers: { tier30m: 12, tier60m: 20, tier120m: 38 },
  ratingAvg: 5.0,
  totalSessions: 3,
  walletBalance: 120.0,
};

async function upsertUser(data, role) {
  const existing = await User.findOne({ email: data.email.toLowerCase() });
  if (existing) {
    console.log(`  - ${data.email} already exists, skipping.`);
    return existing;
  }
  const hashedPassword = await bcrypt.hash(DEMO_PASSWORD, 10);
  const user = new User({
    ...data,
    email: data.email.toLowerCase(),
    password: hashedPassword,
    role,
    isIdentityVerified: true,
    isSkillVerified: role === 'mentor',
  });
  user.calculateLeaderboardScore();
  await user.save();
  console.log(`  - created ${role}: ${data.email}`);
  return user;
}

async function run() {
  console.log(`Connecting to ${MONGODB_URI} ...`);
  await mongoose.connect(MONGODB_URI, { serverSelectionTimeoutMS: 5000 });
  console.log('Connected.\n');

  console.log('Seeding mentors...');
  const mentors = [];
  for (const m of mentorsData) {
    mentors.push(await upsertUser(m, 'mentor'));
  }

  console.log('\nSeeding mentee...');
  const mentee = await upsertUser(menteeData, 'mentee');

  const alex = mentors.find((m) => m.email === 'alex.rivera@ymentor.demo');

  console.log('\nSeeding sample workspace + note + booking (Jordan <-> Alex)...');
  let workspace = await Workspace.findOne({ mentorId: alex._id, menteeId: mentee._id });
  if (!workspace) {
    workspace = await Workspace.create({
      mentorId: alex._id,
      menteeId: mentee._id,
      topic: 'Flutter State Architecture & Clean Code Mentorship',
    });
    console.log('  - workspace created');
  } else {
    console.log('  - workspace already exists, skipping');
  }

  const existingNote = await Note.findOne({ workspaceId: workspace._id });
  if (!existingNote) {
    await Note.create({
      workspaceId: workspace._id,
      title: 'Assignment 01: Riverpod 2.0 vs Bloc State Patterns.pdf',
      description: 'Deconstruct asynchronous state, cached providers, and state restoration on Android lifecycle changes.',
      dueDate: 'This Sunday, 11:59 PM',
      pdfUrl: '/uploads/sample-flutter-architecture.pdf',
      uploadedBy: alex._id,
      isCompleted: false,
      comments: [
        {
          senderId: alex._id,
          senderName: 'Alex Rivera (Mentor)',
          message: 'Review Section 3 on NotifierProvider family disposals before submitting your repository link!',
        },
        {
          senderId: mentee._id,
          senderName: 'Jordan Cole (Mentee)',
          message: 'Understood Alex! Should I create a mock repository test suite with mocktail as well?',
        },
      ],
    });
    console.log('  - note + comments created');
  } else {
    console.log('  - note already exists, skipping');
  }

  const existingBooking = await Booking.findOne({ mentorId: alex._id, menteeId: mentee._id });
  if (!existingBooking) {
    await Booking.create({
      menteeId: mentee._id,
      mentorId: alex._id,
      durationMinutes: 60,
      scheduledTime: new Date(Date.now() + 3600000 * 18),
      meetingUrl: 'https://meet.google.com/ymentor-alex-rivera',
      financials: {
        grossAmount: 20.0,
        platformCommission20Percent: 4.0,
        mentorNetPayout80Percent: 16.0,
        escrowStatus: 'HELD',
      },
      status: 'CONFIRMED',
    });
    console.log('  - booking created');
  } else {
    console.log('  - booking already exists, skipping');
  }

  console.log('\nDone. Demo login: jordan.cole@gmail.com / password123');
  await mongoose.disconnect();
  process.exit(0);
}

run().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
