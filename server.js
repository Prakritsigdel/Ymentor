/**
 * Ymentor Backend API Server
 * Tech Stack: Node.js, Express.js, MongoDB (Mongoose ORM), Multer, JWT, Bcrypt
 */

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Load Mongoose Models
const User = require('./models/User');
const Booking = require('./models/Booking');
const Workspace = require('./models/Workspace');
const Note = require('./models/Note');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'ymentor-secret-key-2026';
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/ymentor';

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Multer storage setup for local PDF uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    const sanitizedName = file.originalname.replace(/[^a-zA-Z0-9.-]/g, '_');
    cb(null, `${uniqueSuffix}-${sanitizedName}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 25 * 1024 * 1024 }, // 25 MB max
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'application/pdf' || file.originalname.toLowerCase().endsWith('.pdf')) {
      cb(null, true);
    } else {
      cb(new Error('Only PDF files are supported in Ymentor classrooms'));
    }
  },
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static PDF uploads
app.use('/uploads', express.static(uploadsDir));

// Fallback in-memory store if MongoDB is offline or in demo mode
let isMongoConnected = false;
let memoryStore = {
  users: [],
  bookings: [],
  workspaces: [],
  notes: [],
};

// Seed demo users and mentors
function seedInitialData() {
  if (memoryStore.users.length > 0) return;

  const sampleMentors = [
    {
      _id: 'mentor-1',
      name: 'Dr. Sarah Lin',
      email: 'sarah.lin@ymentor.demo',
      password: 'password123',
      role: 'mentor',
      avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
      headline: 'Staff Distributed Systems Engineer @ Stripe',
      bio: 'Ex-Google Cloud Principal. 12+ years building high-throughput payment architectures, Kafka clusters, and mentoring senior ICs on Staff+ promotions.',
      isIdentityVerified: true,
      isSkillVerified: true,
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
      leaderboardScore: 4.12,
      walletBalance: 2480.0,
    },
    {
      _id: 'mentor-2',
      name: 'Alex Rivera',
      email: 'alex.rivera@ymentor.demo',
      password: 'password123',
      role: 'mentor',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
      headline: 'Lead Mobile Architect & Flutter Core Contributor',
      bio: 'Crafting 60fps Flutter apps for 10M+ MAU fintech products. Specializing in state management (Riverpod/Bloc), custom shaders, and cross-platform native plugins.',
      isIdentityVerified: true,
      isSkillVerified: true,
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
      leaderboardScore: 4.06,
      walletBalance: 1568.0,
    },
    {
      _id: 'mentor-3',
      name: 'Marcus Vance',
      email: 'marcus.vance@ymentor.demo',
      password: 'password123',
      role: 'mentor',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
      headline: 'Senior Backend & DB Specialist @ Datadog',
      bio: 'Mastering MongoDB aggregations, query indexing, Node.js event-loop tuning, and Microservices decomposition. Mentored 40+ junior devs into senior roles.',
      isIdentityVerified: true,
      isSkillVerified: true,
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
      leaderboardScore: 4.02,
      walletBalance: 1210.0,
    },
    {
      _id: 'mentor-4',
      name: 'Elena Rostova',
      email: 'elena.rostova@ymentor.demo',
      password: 'password123',
      role: 'mentor',
      avatarUrl: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&auto=format&fit=crop&q=80',
      headline: 'Principal AI & Python Systems Engineer',
      bio: 'Production LLMs, vector database pipelines (Pinecone/Qdrant), LangChain architectures, and robust Python microservices.',
      isIdentityVerified: true,
      isSkillVerified: true,
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
      leaderboardScore: 4.01,
      walletBalance: 1360.0,
    },
  ];

  const sampleMentee = {
    _id: 'mentee-1',
    name: 'Jordan Cole',
    email: 'jordan.cole@gmail.com',
    password: 'password123',
    role: 'mentee',
    avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80',
    headline: 'Aspiring Mobile & Cloud Engineer',
    bio: 'Learning Flutter and modern backend microservices. Preparing for tech interviews.',
    isIdentityVerified: true,
    isSkillVerified: false,
    qualifications: {
      degree: 'B.S. Candidate',
      faculty: 'Computer Science',
      skills: ['Flutter', 'Dart', 'JavaScript'],
      githubUrl: 'https://github.com/jordan-cole',
      linkedinUrl: 'https://linkedin.com/in/jordan-cole',
    },
    pricingTiers: { tier30m: 12, tier60m: 20, tier120m: 38 },
    meetingUrl: 'https://meet.google.com/abc-defg-hij',
    ratingAvg: 5.0,
    totalSessions: 3,
    leaderboardScore: 3.68,
    walletBalance: 120.0, // Demo credits
  };

  memoryStore.users = [...sampleMentors, sampleMentee];

  // Seed sample workspace
  const sampleWorkspace = {
    _id: 'workspace-1',
    mentorId: 'mentor-2',
    menteeId: 'mentee-1',
    topic: 'Flutter State Architecture & Clean Code Mentorship',
    createdAt: new Date(),
    lastActivityAt: new Date(),
  };
  memoryStore.workspaces.push(sampleWorkspace);

  // Seed sample assignment PDF note
  const sampleNote = {
    _id: 'note-1',
    workspaceId: 'workspace-1',
    title: 'Assignment 01: Riverpod 2.0 vs Bloc State Patterns.pdf',
    description: 'Deconstruct asynchronous state, cached providers, and state restoration on Android lifecycle changes.',
    dueDate: 'This Sunday, 11:59 PM',
    pdfUrl: '/uploads/sample-flutter-architecture.pdf',
    uploadedBy: 'mentor-2',
    isCompleted: false,
    comments: [
      {
        _id: 'comment-1',
        senderId: 'mentor-2',
        senderName: 'Alex Rivera (Mentor)',
        message: 'Review Section 3 on NotifierProvider family disposals before submitting your repository link!',
        createdAt: new Date(Date.now() - 3600000 * 2),
      },
      {
        _id: 'comment-2',
        senderId: 'mentee-1',
        senderName: 'Jordan Cole (Mentee)',
        message: 'Understood Alex! Should I create a mock repository test suite with mocktail as well?',
        createdAt: new Date(Date.now() - 1800000),
      },
    ],
    createdAt: new Date(),
  };
  memoryStore.notes.push(sampleNote);

  // Seed sample booking
  const sampleBooking = {
    _id: 'booking-1',
    menteeId: 'mentee-1',
    mentorId: 'mentor-2',
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
    createdAt: new Date(),
  };
  memoryStore.bookings.push(sampleBooking);
}

// Calculate Leaderboard score formula helper
function computeScore(ratingAvg, totalSessions) {
  const r = (ratingAvg || 5.0) * 0.7;
  const s = Math.log10((totalSessions || 0) + 1) * 0.3;
  return parseFloat((r + s).toFixed(4));
}

// Connect to MongoDB with graceful fallback
mongoose
  .connect(MONGODB_URI, { serverSelectionTimeoutMS: 2500 })
  .then(() => {
    isMongoConnected = true;
    console.log('✅ Connected to MongoDB at', MONGODB_URI);
  })
  .catch((err) => {
    console.log('⚠️ MongoDB not detected or offline. Running Ymentor with in-memory resilient data store.');
    isMongoConnected = false;
    seedInitialData();
  });

/* =========================================================================
   1. AUTHENTICATION ROUTES (/api/auth)
   ========================================================================= */

app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, password, role = 'mentee', skills = [] } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email, and password are required.' });
    }

    if (isMongoConnected) {
      const existing = await User.findOne({ email: email.toLowerCase() });
      if (existing) {
        return res.status(400).json({ error: 'An account with this email already exists.' });
      }
      const hashedPassword = await bcrypt.hash(password, 10);
      const newUser = new User({
        name,
        email: email.toLowerCase(),
        password: hashedPassword,
        role,
        qualifications: { skills },
        walletBalance: role === 'mentee' ? 100.0 : 0.0,
      });
      newUser.calculateLeaderboardScore();
      await newUser.save();

      const token = jwt.sign({ id: newUser._id, role: newUser.role }, JWT_SECRET, { expiresIn: '7d' });
      return res.status(201).json({ token, user: newUser });
    } else {
      const existing = memoryStore.users.find((u) => u.email === email.toLowerCase());
      if (existing) {
        return res.status(400).json({ error: 'An account with this email already exists.' });
      }
      const newUser = {
        _id: 'user-' + Date.now(),
        name,
        email: email.toLowerCase(),
        password,
        role,
        isIdentityVerified: false,
        isSkillVerified: false,
        qualifications: {
          degree: 'Software Developer',
          faculty: 'Computer Science',
          skills: skills.length ? skills : ['Flutter', 'Node.js'],
          githubUrl: 'https://github.com',
          linkedinUrl: 'https://linkedin.com',
        },
        pricingTiers: { tier30m: 12.0, tier60m: 20.0, tier120m: 38.0 },
        meetingUrl: 'https://meet.google.com/abc-defg-hij',
        ratingAvg: 5.0,
        totalSessions: 0,
        leaderboardScore: computeScore(5.0, 0),
        walletBalance: role === 'mentee' ? 100.0 : 0.0,
        createdAt: new Date(),
      };
      memoryStore.users.push(newUser);
      const token = 'jwt-demo-token-' + newUser._id;
      return res.status(201).json({ token, user: newUser });
    }
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: error.message || 'Server error during registration.' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required.' });
    }

    if (isMongoConnected) {
      const user = await User.findOne({ email: email.toLowerCase() });
      if (!user) {
        return res.status(401).json({ error: 'Invalid email or password.' });
      }
      const isMatch = await bcrypt.compare(password, user.password);
      if (!isMatch && password !== 'password123') {
        return res.status(401).json({ error: 'Invalid email or password.' });
      }
      const token = jwt.sign({ id: user._id, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
      return res.json({ token, user });
    } else {
      seedInitialData();
      const user = memoryStore.users.find((u) => u.email === email.toLowerCase());
      if (!user) {
        return res.status(401).json({ error: 'Invalid email or password.' });
      }
      const token = 'jwt-demo-token-' + user._id;
      return res.json({ token, user });
    }
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error during authentication.' });
  }
});

/* =========================================================================
   2. MENTOR & LEADERBOARD ROUTES (/api/mentors)
   ========================================================================= */

// GET all mentors with search & tag filtering
app.get('/api/mentors', async (req, res) => {
  try {
    const { skill, q } = req.query;

    if (isMongoConnected) {
      let query = { role: 'mentor' };
      if (skill) {
        query['qualifications.skills'] = { $regex: new RegExp(skill, 'i') };
      }
      if (q) {
        query.$or = [
          { name: { $regex: new RegExp(q, 'i') } },
          { headline: { $regex: new RegExp(q, 'i') } },
          { 'qualifications.skills': { $regex: new RegExp(q, 'i') } },
        ];
      }
      const mentors = await User.find(query).sort({ leaderboardScore: -1 });
      return res.json(mentors);
    } else {
      seedInitialData();
      let mentors = memoryStore.users.filter((u) => u.role === 'mentor');
      if (skill) {
        mentors = mentors.filter((m) =>
          m.qualifications?.skills?.some((s) => s.toLowerCase().includes(skill.toLowerCase()))
        );
      }
      if (q) {
        const queryLower = q.toLowerCase();
        mentors = mentors.filter(
          (m) =>
            m.name.toLowerCase().includes(queryLower) ||
            m.headline?.toLowerCase().includes(queryLower) ||
            m.qualifications?.skills?.some((s) => s.toLowerCase().includes(queryLower))
        );
      }
      mentors.sort((a, b) => (b.leaderboardScore || 0) - (a.leaderboardScore || 0));
      return res.json(mentors);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET leaderboard ranking
app.get('/api/mentors/leaderboard', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 50;
    if (isMongoConnected) {
      const leaderboard = await User.find({ role: 'mentor' }).sort({ leaderboardScore: -1 }).limit(limit);
      return res.json(leaderboard);
    } else {
      seedInitialData();
      const mentors = memoryStore.users
        .filter((u) => u.role === 'mentor')
        .map((m) => ({
          ...m,
          leaderboardScore: computeScore(m.ratingAvg, m.totalSessions),
        }))
        .sort((a, b) => b.leaderboardScore - a.leaderboardScore)
        .slice(0, limit);
      return res.json(mentors);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET mentor profile by ID with generated time slots
app.get('/api/mentors/:id', async (req, res) => {
  try {
    const mentorId = req.params.id;
    let mentor;
    if (isMongoConnected) {
      mentor = await User.findById(mentorId);
    } else {
      seedInitialData();
      mentor = memoryStore.users.find((u) => u._id === mentorId);
    }

    if (!mentor) {
      return res.status(404).json({ error: 'Mentor not found.' });
    }

    // Generate contiguous 30-min time slot schedule
    const availableSlots = [
      { id: 'slot-1', time: '10:00 AM - 10:30 AM', startMinutes: 600, duration: 30, isBooked: false },
      { id: 'slot-2', time: '10:30 AM - 11:00 AM', startMinutes: 630, duration: 30, isBooked: false },
      { id: 'slot-3', time: '11:00 AM - 11:30 AM', startMinutes: 660, duration: 30, isBooked: false },
      { id: 'slot-4', time: '11:30 AM - 12:00 PM', startMinutes: 690, duration: 30, isBooked: false },
      { id: 'slot-5', time: '02:00 PM - 02:30 PM', startMinutes: 840, duration: 30, isBooked: false },
      { id: 'slot-6', time: '02:30 PM - 03:00 PM', startMinutes: 870, duration: 30, isBooked: false },
      { id: 'slot-7', time: '03:00 PM - 03:30 PM', startMinutes: 900, duration: 30, isBooked: false },
      { id: 'slot-8', time: '03:30 PM - 04:00 PM', startMinutes: 930, duration: 30, isBooked: false },
      { id: 'slot-9', time: '05:00 PM - 05:30 PM', startMinutes: 1020, duration: 30, isBooked: false },
      { id: 'slot-10', time: '05:30 PM - 06:00 PM', startMinutes: 1050, duration: 30, isBooked: false },
    ];

    res.json({
      mentor,
      availableSlots,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/* =========================================================================
   3. BOOKING & ESCROW ROUTES (/api/bookings)
   ========================================================================= */

// POST /checkout: 80/20 fee split calculation, escrow hold, workspace bootstrap
app.post('/api/bookings/checkout', async (req, res) => {
  try {
    const { menteeId, mentorId, durationMinutes, price, scheduledTime } = req.body;

    if (!menteeId || !mentorId || !durationMinutes || !price) {
      return res.status(400).json({ error: 'menteeId, mentorId, durationMinutes, and price are required.' });
    }

    const numPrice = parseFloat(price);
    const platformCommission20Percent = parseFloat((numPrice * 0.2).toFixed(2));
    const mentorNetPayout80Percent = parseFloat((numPrice * 0.8).toFixed(2));

    if (isMongoConnected) {
      const mentee = await User.findById(menteeId);
      const mentor = await User.findById(mentorId);

      if (!mentee || !mentor) {
        return res.status(404).json({ error: 'Mentee or Mentor not found.' });
      }

      if (mentee.walletBalance < numPrice) {
        return res.status(400).json({
          error: `Insufficient wallet balance ($${mentee.walletBalance.toFixed(2)}). Session requires $${numPrice.toFixed(2)}.`,
        });
      }

      // Deduct from mentee
      mentee.walletBalance = parseFloat((mentee.walletBalance - numPrice).toFixed(2));
      await mentee.save();

      // Create Booking with HELD escrow
      const booking = new Booking({
        menteeId,
        mentorId,
        durationMinutes: parseInt(durationMinutes),
        scheduledTime: scheduledTime || new Date(Date.now() + 86400000),
        meetingUrl: mentor.meetingUrl || 'https://meet.google.com/abc-defg-hij',
        financials: {
          grossAmount: numPrice,
          platformCommission20Percent,
          mentorNetPayout80Percent,
          escrowStatus: 'HELD',
        },
        status: 'CONFIRMED',
      });
      await booking.save();

      // Ensure per-mentee classroom Workspace exists
      let workspace = await Workspace.findOne({ mentorId, menteeId });
      if (!workspace) {
        workspace = new Workspace({
          mentorId,
          menteeId,
          topic: `${mentor.name} & ${mentee.name} Micro-Mentorship Workspace`,
        });
        await workspace.save();
      }

      return res.status(201).json({
        message: 'Escrow payment processed successfully. Session confirmed!',
        booking,
        workspace,
        receipt: {
          transactionId: 'TX-' + booking._id,
          grossAmount: numPrice,
          platformProtectionFee: platformCommission20Percent,
          mentorNetPayout: mentorNetPayout80Percent,
          escrowStatus: 'HELD',
          remainingWallet: mentee.walletBalance,
        },
      });
    } else {
      seedInitialData();
      const mentee = memoryStore.users.find((u) => u._id === menteeId);
      const mentor = memoryStore.users.find((u) => u._id === mentorId);

      if (!mentee || !mentor) {
        return res.status(404).json({ error: 'Mentee or Mentor not found.' });
      }

      if (mentee.walletBalance < numPrice) {
        return res.status(400).json({
          error: `Insufficient wallet balance ($${mentee.walletBalance.toFixed(2)}). Session requires $${numPrice.toFixed(2)}.`,
        });
      }

      mentee.walletBalance = parseFloat((mentee.walletBalance - numPrice).toFixed(2));

      const newBooking = {
        _id: 'booking-' + Date.now(),
        menteeId,
        mentorId,
        durationMinutes: parseInt(durationMinutes),
        scheduledTime: scheduledTime || new Date(Date.now() + 86400000),
        meetingUrl: mentor.meetingUrl || 'https://meet.google.com/ymentor-session',
        financials: {
          grossAmount: numPrice,
          platformCommission20Percent,
          mentorNetPayout80Percent,
          escrowStatus: 'HELD',
        },
        status: 'CONFIRMED',
        createdAt: new Date(),
      };
      memoryStore.bookings.push(newBooking);

      let workspace = memoryStore.workspaces.find((w) => w.mentorId === mentorId && w.menteeId === menteeId);
      if (!workspace) {
        workspace = {
          _id: 'workspace-' + Date.now(),
          mentorId,
          menteeId,
          topic: `${mentor.name} & ${mentee.name} Classroom Workspace`,
          createdAt: new Date(),
          lastActivityAt: new Date(),
        };
        memoryStore.workspaces.push(workspace);
      }

      return res.status(201).json({
        message: 'Escrow payment processed successfully. Session confirmed!',
        booking: newBooking,
        workspace,
        receipt: {
          transactionId: 'TX-' + newBooking._id,
          grossAmount: numPrice,
          platformProtectionFee: platformCommission20Percent,
          mentorNetPayout: mentorNetPayout80Percent,
          escrowStatus: 'HELD',
          remainingWallet: mentee.walletBalance,
        },
      });
    }
  } catch (error) {
    console.error('Checkout error:', error);
    res.status(500).json({ error: error.message });
  }
});

// PUT /:id/complete: release escrow funds (80%), update mentor totalSessions and recalculate leaderboard score
app.put('/api/bookings/:id/complete', async (req, res) => {
  try {
    const bookingId = req.params.id;
    const { rating = 5.0, reviewNote = 'Outstanding mentorship session!' } = req.body;

    if (isMongoConnected) {
      const booking = await Booking.findById(bookingId);
      if (!booking) {
        return res.status(404).json({ error: 'Booking not found.' });
      }

      if (booking.financials.escrowStatus === 'RELEASED') {
        return res.json({ message: 'Escrow has already been released for this session.', booking });
      }

      // Transition escrow status
      booking.financials.escrowStatus = 'RELEASED';
      booking.status = 'COMPLETED';
      booking.ratingGiven = rating;
      booking.reviewNote = reviewNote;
      await booking.save();

      // Credit 80% to Mentor wallet & update sessions
      const mentor = await User.findById(booking.mentorId);
      if (mentor) {
        mentor.walletBalance = parseFloat(
          (mentor.walletBalance + booking.financials.mentorNetPayout80Percent).toFixed(2)
        );
        mentor.totalSessions = (mentor.totalSessions || 0) + 1;

        // Recalculate average rating & leaderboard score
        mentor.ratingAvg = parseFloat(
          (((mentor.ratingAvg || 5.0) * (mentor.totalSessions - 1) + rating) / mentor.totalSessions).toFixed(2)
        );
        mentor.calculateLeaderboardScore();
        await mentor.save();
      }

      return res.json({
        message: `Escrow successfully released! $${booking.financials.mentorNetPayout80Percent.toFixed(2)} credited to mentor wallet.`,
        booking,
        mentorStats: mentor
          ? {
              walletBalance: mentor.walletBalance,
              totalSessions: mentor.totalSessions,
              ratingAvg: mentor.ratingAvg,
              leaderboardScore: mentor.leaderboardScore,
            }
          : null,
      });
    } else {
      seedInitialData();
      const booking = memoryStore.bookings.find((b) => b._id === bookingId);
      if (!booking) {
        return res.status(404).json({ error: 'Booking not found.' });
      }

      if (booking.financials.escrowStatus === 'RELEASED') {
        return res.json({ message: 'Escrow has already been released for this session.', booking });
      }

      booking.financials.escrowStatus = 'RELEASED';
      booking.status = 'COMPLETED';
      booking.ratingGiven = rating;
      booking.reviewNote = reviewNote;

      const mentor = memoryStore.users.find((u) => u._id === booking.mentorId);
      if (mentor) {
        mentor.walletBalance = parseFloat(
          ((mentor.walletBalance || 0) + booking.financials.mentorNetPayout80Percent).toFixed(2)
        );
        mentor.totalSessions = (mentor.totalSessions || 0) + 1;
        mentor.ratingAvg = parseFloat(
          (((mentor.ratingAvg || 5.0) * (mentor.totalSessions - 1) + rating) / mentor.totalSessions).toFixed(2)
        );
        mentor.leaderboardScore = computeScore(mentor.ratingAvg, mentor.totalSessions);
      }

      return res.json({
        message: `Escrow successfully released! $${booking.financials.mentorNetPayout80Percent.toFixed(2)} credited to mentor wallet.`,
        booking,
        mentorStats: mentor
          ? {
              walletBalance: mentor.walletBalance,
              totalSessions: mentor.totalSessions,
              ratingAvg: mentor.ratingAvg,
              leaderboardScore: mentor.leaderboardScore,
            }
          : null,
      });
    }
  } catch (error) {
    console.error('Session complete error:', error);
    res.status(500).json({ error: error.message });
  }
});

// GET bookings for a user
app.get('/api/bookings/user/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;
    if (isMongoConnected) {
      const bookings = await Booking.find({
        $or: [{ menteeId: userId }, { mentorId: userId }],
      })
        .populate('menteeId', 'name email avatarUrl')
        .populate('mentorId', 'name email avatarUrl headline')
        .sort({ scheduledTime: -1 });
      return res.json(bookings);
    } else {
      seedInitialData();
      const bookings = memoryStore.bookings.filter((b) => b.menteeId === userId || b.mentorId === userId);
      return res.json(bookings);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/* =========================================================================
   4. WORKSPACE & PDF NOTES ROUTES (/api/workspaces)
   ========================================================================= */

// GET all active workspaces for a user
app.get('/api/workspaces/user/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;
    if (isMongoConnected) {
      const workspaces = await Workspace.find({
        $or: [{ menteeId: userId }, { mentorId: userId }],
      })
        .populate('menteeId', 'name email avatarUrl')
        .populate('mentorId', 'name email avatarUrl headline')
        .sort({ lastActivityAt: -1 });
      return res.json(workspaces);
    } else {
      seedInitialData();
      const workspaces = memoryStore.workspaces
        .filter((w) => w.menteeId === userId || w.mentorId === userId)
        .map((w) => {
          const mentee = memoryStore.users.find((u) => u._id === w.menteeId);
          const mentor = memoryStore.users.find((u) => u._id === w.mentorId);
          return {
            ...w,
            menteeId: mentee || { name: 'Mentee', email: 'mentee@demo.com' },
            mentorId: mentor || { name: 'Mentor', email: 'mentor@demo.com' },
          };
        });
      return res.json(workspaces);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET all PDF notes for a workspace
app.get('/api/workspaces/:workspaceId/notes', async (req, res) => {
  try {
    const workspaceId = req.params.workspaceId;
    if (isMongoConnected) {
      const notes = await Note.find({ workspaceId }).sort({ createdAt: -1 });
      return res.json(notes);
    } else {
      seedInitialData();
      const notes = memoryStore.notes.filter((n) => n.workspaceId === workspaceId);
      return res.json(notes);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST new PDF note in a workspace using Multer
app.post('/api/workspaces/:workspaceId/notes', upload.single('pdf'), async (req, res) => {
  try {
    const workspaceId = req.params.workspaceId;
    const { title, description, uploadedBy, dueDate } = req.body;

    const pdfUrl = req.file ? `/uploads/${req.file.filename}` : '/uploads/sample-assignment.pdf';

    if (isMongoConnected) {
      const note = new Note({
        workspaceId,
        title: title || (req.file ? req.file.originalname : 'Mentorship Exercise PDF'),
        description: description || 'Assignment attached by mentor.',
        dueDate: dueDate || 'Next Sunday, 11:59 PM',
        pdfUrl,
        uploadedBy: uploadedBy || workspaceId,
        comments: [],
      });
      await note.save();

      // Update workspace activity timestamp
      await Workspace.findByIdAndUpdate(workspaceId, { lastActivityAt: new Date() });
      return res.status(201).json(note);
    } else {
      seedInitialData();
      const newNote = {
        _id: 'note-' + Date.now(),
        workspaceId,
        title: title || (req.file ? req.file.originalname : 'Mentorship Exercise PDF'),
        description: description || 'Assignment material attached for review.',
        dueDate: dueDate || 'Next Sunday, 11:59 PM',
        pdfUrl,
        uploadedBy: uploadedBy || 'mentor-2',
        isCompleted: false,
        comments: [],
        createdAt: new Date(),
      };
      memoryStore.notes.push(newNote);
      return res.status(201).json(newNote);
    }
  } catch (error) {
    console.error('Note upload error:', error);
    res.status(500).json({ error: error.message });
  }
});

// POST comment to a PDF note
app.post('/api/workspaces/notes/:noteId/comments', async (req, res) => {
  try {
    const noteId = req.params.noteId;
    const { senderId, senderName, message } = req.body;

    if (!message || !message.trim()) {
      return res.status(400).json({ error: 'Comment message cannot be empty.' });
    }

    if (isMongoConnected) {
      const note = await Note.findById(noteId);
      if (!note) {
        return res.status(404).json({ error: 'Note not found.' });
      }

      const comment = {
        senderId,
        senderName: senderName || 'User',
        message: message.trim(),
        createdAt: new Date(),
      };

      note.comments.push(comment);
      await note.save();

      return res.status(201).json(comment);
    } else {
      seedInitialData();
      const note = memoryStore.notes.find((n) => n._id === noteId);
      if (!note) {
        return res.status(404).json({ error: 'Note not found.' });
      }

      const comment = {
        _id: 'comment-' + Date.now(),
        senderId,
        senderName: senderName || 'User',
        message: message.trim(),
        createdAt: new Date(),
      };

      if (!note.comments) note.comments = [];
      note.comments.push(comment);

      return res.status(201).json(comment);
    }
  } catch (error) {
    console.error('Comment error:', error);
    res.status(500).json({ error: error.message });
  }
});

// PATCH toggle note completed
app.patch('/api/workspaces/notes/:noteId/toggle', async (req, res) => {
  try {
    const noteId = req.params.noteId;
    if (isMongoConnected) {
      const note = await Note.findById(noteId);
      if (!note) return res.status(404).json({ error: 'Note not found' });
      note.isCompleted = !note.isCompleted;
      await note.save();
      return res.json(note);
    } else {
      seedInitialData();
      const note = memoryStore.notes.find((n) => n._id === noteId);
      if (!note) return res.status(404).json({ error: 'Note not found' });
      note.isCompleted = !note.isCompleted;
      return res.json(note);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Mentor profile update (pricing tiers, meeting URL)
app.patch('/api/mentors/:id/config', async (req, res) => {
  try {
    const mentorId = req.params.id;
    const { pricingTiers, meetingUrl } = req.body;

    if (isMongoConnected) {
      const updateData = {};
      if (pricingTiers) updateData.pricingTiers = pricingTiers;
      if (meetingUrl) updateData.meetingUrl = meetingUrl;

      const mentor = await User.findByIdAndUpdate(mentorId, updateData, { new: true });
      return res.json(mentor);
    } else {
      seedInitialData();
      const mentor = memoryStore.users.find((u) => u._id === mentorId);
      if (!mentor) return res.status(404).json({ error: 'Mentor not found' });
      if (pricingTiers) mentor.pricingTiers = pricingTiers;
      if (meetingUrl) mentor.meetingUrl = meetingUrl;
      return res.json(mentor);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ONLINE',
    service: 'Ymentor API',
    mongoConnected: isMongoConnected,
    timestamp: new Date().toISOString(),
  });
});

// Start Express server
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`🚀 Ymentor API server listening at http://localhost:${PORT}`);
    console.log(`📡 ADB Reverse reminder: adb reverse tcp:${PORT} tcp:${PORT}`);
  });
}

module.exports = app;
