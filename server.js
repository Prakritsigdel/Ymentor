/**
 * Ymentor Backend API Server
 * 3-Role System Architecture: ADMIN, MENTOR, and MENTEE
 * Tech Stack: Node.js, Express.js, MongoDB (Mongoose ORM), Multer, JWT, Bcrypt
 */

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const os = require('os');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Load Mongoose Models
const User = require('./models/User');
const Booking = require('./models/Booking');
const Workspace = require('./models/Workspace');
const Note = require('./models/Note');
const AuditLog = require('./models/AuditLog');
const PlatformConfig = require('./models/PlatformConfig');
const Review = require('./models/Review');
const SearchEvent = require('./models/SearchEvent');

// Load Middleware and Utils
const { verifyAuth, verifyRole, JWT_SECRET } = require('./middleware/auth');
const { logAudit, getMemoryAuditLogs } = require('./utils/logger');
const createAuthRouter = require('./server/routes/auth');
const createMentorsRouter = require('./server/routes/mentors');
const createBookingsRouter = require('./server/routes/bookings');
const createChatRouter = require('./server/routes/chat');
const createAdminRouter = require('./server/routes/admin');
const { splitEscrow } = require('./services/escrowService');

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0';
const WIFI_HOST = process.env.WIFI_HOST || (() => {
  const interfaces = os.networkInterfaces();
  const candidates = Object.entries(interfaces)
    .flatMap(([name, addresses]) =>
      (addresses || [])
        .filter((entry) => (entry.family === 'IPv4' || entry.family === 4) && !entry.internal)
        .map((entry) => ({ name, address: entry.address })),
    )
    .sort((a, b) => {
      const score = (candidate) => {
        if (/wi[- ]?fi|wireless|wlan/i.test(candidate.name)) return 0;
        if (/virtual|vEthernet|hyper-v|docker|default switch|loopback/i.test(candidate.name)) {
          return 2;
        }
        return 1;
      };
      return score(a) - score(b);
    });

  if (candidates.length > 0) return candidates[0].address;
  return '127.0.0.1';
})();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/ymentor';
const ADMIN_EMAIL = process.env.YMENTOR_ADMIN_EMAIL?.trim().toLowerCase();
const ADMIN_PASSWORD = process.env.YMENTOR_ADMIN_PASSWORD;

if (Boolean(ADMIN_EMAIL) !== Boolean(ADMIN_PASSWORD)) {
  throw new Error('Set both YMENTOR_ADMIN_EMAIL and YMENTOR_ADMIN_PASSWORD to provision an administrator.');
}

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
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static PDF uploads
app.use('/uploads', express.static(uploadsDir));

// Fallback in-memory store for resilience
let isMongoConnected = false;
global.ymentorMemoryStore = {
  users: [],
  bookings: [],
  workspaces: [],
  notes: [],
  conversations: [],
  messages: [],
  disputes: [],
  reviews: [],
  config: { flatFee: 4, percentageFee: 0, broadcasts: [] },
};

app.use('/api', createAuthRouter({ verifyAuth, uploadsDir }));
app.use('/api/mentors', createMentorsRouter({ verifyAuth }));
app.use('/api', createBookingsRouter({ verifyAuth }));
app.use('/api/chat', createChatRouter({ verifyAuth, uploadsDir }));
app.use('/api/v1/chat', createChatRouter({ verifyAuth, uploadsDir }));
app.use('/api/admin', createAdminRouter({ verifyAuth, verifyRole, logAudit }));

// Calculate Leaderboard score formula helper
function computeScore(ratingAvg, totalSessions) {
  const r = (ratingAvg || 5.0) * 0.7;
  const s = Math.log10((totalSessions || 0) + 1) * 0.3;
  return parseFloat((r + s).toFixed(4));
}

/**
 * On boot, create or migrate the two baseline accounts used for local setup.
 * Other users must be registered through the application.
 */
async function autoSeedBaselineAccounts() {
  const seedUsers = [
    {
      _id: 'user-mentor-seed',
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
      pricingTiers: { tier30m: 1000, tier60m: 2000, tier120m: 3600 },
      meetingUrl: 'https://meet.google.com/ymentor-alex-mentor',
      ratingAvg: 4.95,
      totalSessions: 38,
      leaderboardScore: computeScore(4.95, 38),
      wallet: { balance: 5000, pendingEscrow: 0 },
      walletBalance: 5000,
      isIdentityVerified: true,
      isSkillVerified: true,
      verificationStatus: 'APPROVED',
      mentorProfile: { monthlyRate: 20000, maxMentees: 5, primaryDomain: 'Software Engineering' },
    },
    {
      _id: 'user-mentee-seed',
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
      pricingTiers: { tier30m: 1000, tier60m: 2000, tier120m: 3600 },
      meetingUrl: 'https://meet.google.com/abc-defg-hij',
      ratingAvg: 5.0,
      totalSessions: 2,
      leaderboardScore: computeScore(5.0, 2),
      wallet: { balance: 1000, pendingEscrow: 0 },
      walletBalance: 1000,
      isIdentityVerified: true,
      isSkillVerified: false,
      menteeProfile: { preferredMode: 'both', targetSkills: ['AI', 'Python'] },
    },
  ];

  if (isMongoConnected) {
    for (const data of seedUsers) {
      const { legacyEmail, ...profile } = data;
      let existing = await User.findOne({ email: profile.email.toLowerCase() });
      if (!existing && legacyEmail) {
        existing = await User.findOne({ email: legacyEmail.toLowerCase() });
      }
      if (!existing) {
        const hashedPassword = await bcrypt.hash(profile.password, 10);
        const user = new User({
          ...profile,
          _id: new mongoose.Types.ObjectId(),
          password: hashedPassword,
        });
        user.calculateLeaderboardScore();
        await user.save();
        console.log(`🌱 [Auto-Seed] Created MongoDB baseline account: ${data.email} (${data.role})`);
        await logAudit({
          actorId: user._id,
          actorName: user.name,
          actorRole: user.role,
          action: 'SEED_ACCOUNT_CREATED',
          targetId: user._id,
          details: { email: user.email, role: user.role },
        });
      } else if (existing.email.toLowerCase() !== profile.email.toLowerCase()) {
        existing.name = profile.name;
        existing.email = profile.email.toLowerCase();
        existing.password = await bcrypt.hash(profile.password, 10);
        existing.title = profile.title || existing.title;
        existing.headline = profile.headline;
        existing.bio = profile.bio;
        existing.faculty = profile.faculty;
        existing.skillsOrInterests = profile.skillsOrInterests;
        existing.qualifications = profile.qualifications;
        await existing.save();
        console.log(`🌱 [Auto-Seed] Updated baseline ${profile.role} account: ${profile.email}`);
      }
    }

    const demoMentorPricing = [
      ['Alex Rivera', 2500, 25000],
      ['Alex Morgan', 2000, 20000],
      ['Dipesh Sunar', 1200, 12000],
      ['Nirhang Limbu', 1000, 10000],
    ];
    for (const [name, hourly, monthly] of demoMentorPricing) {
      await User.updateOne(
        { name, role: 'mentor' },
        {
          $set: {
            hourlyRate: hourly,
            pricing: { hourly, monthly },
            'mentorProfile.monthlyRate': monthly,
          },
        },
      );
    }

    if (ADMIN_EMAIL && ADMIN_PASSWORD) {
      const existingAdmin = await User.findOne({ email: ADMIN_EMAIL });
      if (!existingAdmin) {
        const hashedPassword = await bcrypt.hash(ADMIN_PASSWORD, 10);
        const admin = new User({
          name: 'YMentor Administrator',
          email: ADMIN_EMAIL,
          password: hashedPassword,
          role: 'admin',
          status: 'active',
          isOnboarded: true,
        });
        await admin.save();
        console.log(`🌱 [Auto-Seed] Provisioned administrator account: ${ADMIN_EMAIL}`);
      }
    }

    // Seed one starter workspace and booking for the baseline mentor and mentee.
    const mentee = await User.findOne({ email: 'sarah.chen@ymentor.com' });
    const mentor = await User.findOne({ email: 'alex.morgan@ymentor.com' });

    if (mentee && mentor) {
      let ws = await Workspace.findOne({ mentorId: mentor._id, menteeId: mentee._id });
      if (!ws) {
        ws = await Workspace.create({
          mentorId: mentor._id,
          menteeId: mentee._id,
          planType: 'hourly',
          topic: 'AI Systems Architecture & Flutter Mentorship',
        });
        console.log('🌱 [Auto-Seed] Created baseline classroom workspace');

        await Note.create({
          workspaceId: ws._id,
          title: 'Assignment 01: Multi-Agent Architectures with Python.pdf',
          description: 'Study prompt chaining, structured outputs, and evaluation metrics.',
          dueDate: 'This Sunday, 11:59 PM',
          pdfUrl: '/uploads/sample-ai-architecture.pdf',
          uploadedBy: mentor._id,
          isCompleted: false,
          comments: [
            {
              senderId: mentor._id,
              senderName: 'Alex Morgan (Mentor)',
              message: 'Check out the section on deterministic tool calling before proceeding!',
              createdAt: new Date(Date.now() - 3600000 * 3),
            },
            {
              senderId: mentee._id,
              senderName: 'Sarah Chen (Mentee)',
              message: 'Thanks Alex. I am working through the schema validation exercises now.',
              createdAt: new Date(Date.now() - 3600000 * 1),
            },
          ],
        });
      }

      let booking = await Booking.findOne({ mentorId: mentor._id, menteeId: mentee._id });
      if (!booking) {
        await Booking.create({
          menteeId: mentee._id,
          mentorId: mentor._id,
          durationMinutes: 60,
          scheduledTime: new Date(Date.now() + 3600000 * 24),
          meetingUrl: mentor.meetingUrl,
          platformFee: 400,
          escrowStatus: 'held_in_escrow',
          financials: {
            grossAmount: 1500,
            platformCommission20Percent: 300,
            mentorNetPayout80Percent: 1200,
            escrowStatus: 'held_in_escrow',
          },
          status: 'CONFIRMED',
        });
      }
    }
  } else {
    // Memory store fallback auto-seed
    if (global.ymentorMemoryStore.users.length === 0) {
      global.ymentorMemoryStore.users = seedUsers.map((user) => {
        const { legacyEmail, ...profile } = user;
        return {
          ...profile,
          createdAt: new Date(),
          updatedAt: new Date(),
        };
      });

      const ws = {
        _id: 'workspace-seed-1',
        mentorId: 'user-mentor-seed',
        menteeId: 'user-mentee-seed',
        topic: 'AI Systems Architecture & Flutter Mentorship',
        createdAt: new Date(),
        lastActivityAt: new Date(),
      };
      global.ymentorMemoryStore.workspaces.push(ws);

      const note = {
        _id: 'note-seed-1',
        workspaceId: 'workspace-seed-1',
        title: 'Assignment 01: Multi-Agent Architectures with Python.pdf',
        description: 'Study prompt chaining, structured outputs, and evaluation metrics.',
        dueDate: 'This Sunday, 11:59 PM',
        pdfUrl: '/uploads/sample-ai-architecture.pdf',
        uploadedBy: 'user-mentor-seed',
        isCompleted: false,
        comments: [
          {
            _id: 'comment-seed-1',
            senderId: 'user-mentor-seed',
            senderName: 'Alex Morgan (Mentor)',
            message: 'Check out the section on deterministic tool calling before proceeding!',
            createdAt: new Date(Date.now() - 3600000 * 3),
          },
          {
            _id: 'comment-seed-2',
            senderId: 'user-mentee-seed',
            senderName: 'Sarah Chen (Mentee)',
            message: 'Thanks Alex. I am working through the schema validation exercises now.',
            createdAt: new Date(Date.now() - 3600000 * 1),
          },
        ],
        createdAt: new Date(),
      };
      global.ymentorMemoryStore.notes.push(note);

      const booking = {
        _id: 'booking-seed-1',
        menteeId: 'user-mentee-seed',
        mentorId: 'user-mentor-seed',
        durationMinutes: 60,
        scheduledTime: new Date(Date.now() + 3600000 * 24),
        meetingUrl: 'https://meet.google.com/ymentor-alex-mentor',
        platformFee: 400,
        escrowStatus: 'held_in_escrow',
        financials: {
          grossAmount: 1500,
          platformCommission20Percent: 300,
          mentorNetPayout80Percent: 1200,
          escrowStatus: 'held_in_escrow',
        },
        status: 'CONFIRMED',
        createdAt: new Date(),
      };
      global.ymentorMemoryStore.bookings.push(booking);

      console.log('🌱 [Auto-Seed] In-memory resilient baseline accounts seeded:');
      console.log('   - Mentor: Alex Morgan (alex.morgan@ymentor.com)');
      console.log('   - Mentee: Sarah Chen (sarah.chen@ymentor.com)');
    }
  }

  if (!isMongoConnected && ADMIN_EMAIL && ADMIN_PASSWORD) {
    const adminExists = global.ymentorMemoryStore.users.some(
      (user) => user.email.toLowerCase() === ADMIN_EMAIL,
    );
    if (!adminExists) {
      global.ymentorMemoryStore.users.push({
        _id: 'user-admin-bootstrap',
        name: 'YMentor Administrator',
        email: ADMIN_EMAIL,
        password: ADMIN_PASSWORD,
        role: 'admin',
        status: 'active',
        isOnboarded: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      console.log(`🌱 [Auto-Seed] Provisioned administrator account: ${ADMIN_EMAIL}`);
    }
  }
}

// Connect to MongoDB with graceful fallback
mongoose
  .connect(MONGODB_URI, { serverSelectionTimeoutMS: 2500 })
  .then(async () => {
    isMongoConnected = true;
    console.log('✅ Connected to MongoDB at', MONGODB_URI);
    await autoSeedBaselineAccounts();
  })
  .catch(async () => {
    console.log('⚠️ MongoDB not connected. Operating in resilient memory mode.');
    isMongoConnected = false;
    await autoSeedBaselineAccounts();
  });

/* =========================================================================
   1. AUTHENTICATION ROUTES (/api/auth)
   ========================================================================= */

// POST /api/auth/register
app.post('/api/auth/register', async (req, res) => {
  try {
    const {
      name,
      email,
      password,
      role = 'mentee',
      faculty = '',
      skillsOrInterests = [],
      title = '',
      bio = '',
      hourlyRate = 2000,
    } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email, and password are required.' });
    }

    const normalizedRole = ['admin', 'mentor', 'mentee'].includes(role.toLowerCase())
      ? role.toLowerCase()
      : 'mentee';
    if (normalizedRole === 'admin') {
      return res.status(403).json({ error: 'Administrator accounts must be provisioned by platform operations.' });
    }

    // Mentors start in pending_approval status awaiting admin verification;
    // Mentees and Admins start active.
    const initialStatus = normalizedRole === 'mentor' ? 'pending_approval' : 'active';

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
        role: normalizedRole,
        status: initialStatus,
        faculty,
        skillsOrInterests,
        title,
        bio,
        hourlyRate: Number.isSafeInteger(Number(hourlyRate)) ? Number(hourlyRate) : 2000,
        isOnboarded: false,
        qualifications: { faculty, skills: skillsOrInterests },
        pricingTiers: {
          tier30m: Math.round(Number(hourlyRate) * 0.5),
          tier60m: Number(hourlyRate) || 2000,
          tier120m: Math.round(Number(hourlyRate) * 1.8),
        },
        wallet: {
          balance: normalizedRole === 'mentee' ? 1000 : 0,
          pendingEscrow: 0,
        },
        walletBalance: normalizedRole === 'mentee' ? 1000 : 0,
      });

      newUser.calculateLeaderboardScore();
      await newUser.save();

      const token = jwt.sign(
        { id: newUser._id, role: String(newUser.role).toLowerCase() },
        JWT_SECRET,
        { expiresIn: '7d' },
      );

      await logAudit({
        actorId: newUser._id,
        actorName: newUser.name,
        actorRole: newUser.role,
        action: 'USER_REGISTERED',
        targetId: newUser._id,
        details: { role: newUser.role, status: newUser.status },
      });

      return res.status(201).json({ token, user: newUser });
    } else {
      const existing = global.ymentorMemoryStore.users.find((u) => u.email === email.toLowerCase());
      if (existing) {
        return res.status(400).json({ error: 'An account with this email already exists.' });
      }

      const newUser = {
        _id: 'user-' + Date.now(),
        name,
        email: email.toLowerCase(),
        password,
        role: normalizedRole,
        status: initialStatus,
        faculty,
        skillsOrInterests,
        title,
        bio,
        hourlyRate: Number.isSafeInteger(Number(hourlyRate)) ? Number(hourlyRate) : 2000,
        isOnboarded: false,
        qualifications: { faculty, skills: skillsOrInterests },
        pricingTiers: {
          tier30m: Math.round(Number(hourlyRate) * 0.5),
          tier60m: Number(hourlyRate) || 2000,
          tier120m: Math.round(Number(hourlyRate) * 1.8),
        },
        wallet: {
          balance: normalizedRole === 'mentee' ? 1000 : 0,
          pendingEscrow: 0,
        },
        walletBalance: normalizedRole === 'mentee' ? 1000 : 0,
        meetingUrl: 'https://meet.google.com/abc-defg-hij',
        ratingAvg: 5.0,
        totalSessions: 0,
        leaderboardScore: computeScore(5.0, 0),
        createdAt: new Date(),
      };

      global.ymentorMemoryStore.users.push(newUser);
      const token = 'jwt-demo-token-' + newUser._id;

      await logAudit({
        actorId: newUser._id,
        actorName: newUser.name,
        actorRole: newUser.role,
        action: 'USER_REGISTERED',
        targetId: newUser._id,
        details: { role: newUser.role, status: newUser.status },
      });

      return res.status(201).json({ token, user: newUser });
    }
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: error.message || 'Server error during registration.' });
  }
});

// POST /api/auth/login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required.' });
    }

    let user = null;
    if (isMongoConnected) {
      user = await User.findOne({ email: email.toLowerCase() });
    }
    if (!user && global.ymentorMemoryStore && global.ymentorMemoryStore.users) {
      user = global.ymentorMemoryStore.users.find((u) => u.email === email.toLowerCase());
    }

    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    // BLOCK SUSPENDED USERS
    if (user.status === 'suspended') {
      return res.status(403).json({
        error: 'Your account has been suspended by the platform administrator.',
      });
    }

    // Verify password
    let isMatch = false;
    if (user.password.startsWith('$2a$') || user.password.startsWith('$2b$')) {
      isMatch = await bcrypt.compare(password, user.password);
    } else {
      isMatch = password === user.password;
    }

    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    const normalizedRole = String(user.role || 'mentee').toLowerCase();
    user.role = normalizedRole;
    const token = isMongoConnected
      ? jwt.sign({ id: user._id, role: normalizedRole }, JWT_SECRET, { expiresIn: '7d' })
      : 'jwt-demo-token-' + user._id;

    await logAudit({
      actorId: user._id,
      actorName: user.name,
      actorRole: user.role,
      action: 'USER_LOGIN',
      targetId: user._id,
      details: { email: user.email, role: user.role },
    });

    return res.json({ token, user });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error during authentication.' });
  }
});

// GET /api/auth/me
app.get('/api/auth/me', verifyAuth, async (req, res) => {
  res.json({ user: req.user });
});

/* =========================================================================
   2. USER ONBOARDING & PROFILE ROUTES (/api/users)
   ========================================================================= */

// PUT /api/users/onboarding: Complete initial interactive survey
app.put('/api/users/onboarding', verifyAuth, async (req, res) => {
  try {
    const { faculty, skillsOrInterests = [], title = '', bio = '', hourlyRate } = req.body;
    const userId = req.user._id || req.user.id;

    if (isMongoConnected) {
      const user = await User.findById(userId);
      if (!user) return res.status(404).json({ error: 'User not found.' });

      if (faculty) {
        user.faculty = faculty;
        user.qualifications.faculty = faculty;
      }
      if (skillsOrInterests && skillsOrInterests.length > 0) {
        user.skillsOrInterests = skillsOrInterests;
        user.qualifications.skills = skillsOrInterests;
      }
      if (title) user.title = title;
      if (bio) user.bio = bio;
      if (hourlyRate) {
        const rate = parseFloat(hourlyRate);
        user.hourlyRate = rate;
        user.pricingTiers = {
          tier30m: parseFloat((rate * 0.5).toFixed(2)),
          tier60m: rate,
          tier120m: parseFloat((rate * 1.8).toFixed(2)),
        };
      }
      user.isOnboarded = true;
      await user.save();

      await logAudit({
        actorId: user._id,
        actorName: user.name,
        actorRole: user.role,
        action: 'ONBOARDING_COMPLETED',
        targetId: user._id,
        details: { faculty, skillsCount: skillsOrInterests.length },
      });

      return res.json({ message: 'Onboarding completed successfully', user });
    } else {
      const user = global.ymentorMemoryStore.users.find((u) => u._id === userId || u.id === userId);
      if (!user) return res.status(404).json({ error: 'User not found.' });

      user.isOnboarded = true;
      if (faculty) {
        user.faculty = faculty;
        if (!user.qualifications) user.qualifications = {};
        user.qualifications.faculty = faculty;
      }
      if (skillsOrInterests && skillsOrInterests.length > 0) {
        user.skillsOrInterests = skillsOrInterests;
        if (!user.qualifications) user.qualifications = {};
        user.qualifications.skills = skillsOrInterests;
      }
      if (title) user.title = title;
      if (bio) user.bio = bio;
      if (hourlyRate) {
        const rate = parseFloat(hourlyRate);
        user.hourlyRate = rate;
        user.pricingTiers = {
          tier30m: parseFloat((rate * 0.5).toFixed(2)),
          tier60m: rate,
          tier120m: parseFloat((rate * 1.8).toFixed(2)),
        };
      }

      await logAudit({
        actorId: user._id,
        actorName: user.name,
        actorRole: user.role,
        action: 'ONBOARDING_COMPLETED',
        targetId: user._id,
        details: { faculty, skillsCount: skillsOrInterests.length },
      });

      return res.json({ message: 'Onboarding completed successfully', user });
    }
  } catch (error) {
    console.error('Onboarding error:', error);
    res.status(500).json({ error: error.message });
  }
});

// PUT /api/users/profile: Edit user profile
app.put('/api/users/profile', verifyAuth, async (req, res) => {
  try {
    const { name, bio, title, faculty, skillsOrInterests, hourlyRate, pricingTiers, meetingUrl, monthlyRate, maxMentees } = req.body;
    const userId = req.user._id || req.user.id;

    if (isMongoConnected) {
      const user = await User.findById(userId);
      if (!user) return res.status(404).json({ error: 'User not found.' });

      if (name) user.name = name;
      if (bio !== undefined) user.bio = bio;
      if (title !== undefined) user.title = title;
      if (faculty !== undefined) {
        user.faculty = faculty;
        user.qualifications.faculty = faculty;
      }
      if (skillsOrInterests) {
        user.skillsOrInterests = skillsOrInterests;
        user.qualifications.skills = skillsOrInterests;
      }
      if (hourlyRate !== undefined) user.hourlyRate = parseFloat(hourlyRate);
      if (monthlyRate !== undefined || maxMentees !== undefined) {
        const parsedMonthlyRate = Number(monthlyRate ?? user.mentorProfile?.monthlyRate ?? 0);
        const parsedCapacity = Number(maxMentees ?? user.mentorProfile?.maxMentees ?? 0);
        if (user.role !== 'mentor' || !Number.isFinite(parsedMonthlyRate) || parsedMonthlyRate < 0 || !Number.isInteger(parsedCapacity) || parsedCapacity < 0 || parsedCapacity > 100) {
          return res.status(400).json({ error: 'Monthly pricing or capacity is invalid.' });
        }
        user.mentorProfile.monthlyRate = parsedMonthlyRate;
        user.mentorProfile.maxMentees = parsedCapacity;
      }
      if (pricingTiers) user.pricingTiers = pricingTiers;
      if (meetingUrl !== undefined) user.meetingUrl = meetingUrl;

      await user.save();

      await logAudit({
        actorId: user._id,
        actorName: user.name,
        actorRole: user.role,
        action: 'PROFILE_UPDATED',
        targetId: user._id,
        details: { name: user.name, role: user.role },
      });

      return res.json({ message: 'Profile updated successfully', user });
    } else {
      const user = global.ymentorMemoryStore.users.find((u) => u._id === userId || u.id === userId);
      if (!user) return res.status(404).json({ error: 'User not found.' });

      if (name) user.name = name;
      if (bio !== undefined) user.bio = bio;
      if (title !== undefined) user.title = title;
      if (faculty !== undefined) {
        user.faculty = faculty;
        if (!user.qualifications) user.qualifications = {};
        user.qualifications.faculty = faculty;
      }
      if (skillsOrInterests) {
        user.skillsOrInterests = skillsOrInterests;
        if (!user.qualifications) user.qualifications = {};
        user.qualifications.skills = skillsOrInterests;
      }
      if (hourlyRate !== undefined) user.hourlyRate = parseFloat(hourlyRate);
      if (monthlyRate !== undefined || maxMentees !== undefined) {
        const parsedMonthlyRate = Number(monthlyRate ?? user.mentorProfile?.monthlyRate ?? 0);
        const parsedCapacity = Number(maxMentees ?? user.mentorProfile?.maxMentees ?? 0);
        if (user.role !== 'mentor' || !Number.isFinite(parsedMonthlyRate) || parsedMonthlyRate < 0 || !Number.isInteger(parsedCapacity) || parsedCapacity < 0 || parsedCapacity > 100) {
          return res.status(400).json({ error: 'Monthly pricing or capacity is invalid.' });
        }
        user.mentorProfile ||= {};
        user.mentorProfile.monthlyRate = parsedMonthlyRate;
        user.mentorProfile.maxMentees = parsedCapacity;
      }
      if (pricingTiers) user.pricingTiers = pricingTiers;
      if (meetingUrl !== undefined) user.meetingUrl = meetingUrl;

      await logAudit({
        actorId: user._id,
        actorName: user.name,
        actorRole: user.role,
        action: 'PROFILE_UPDATED',
        targetId: user._id,
        details: { name: user.name, role: user.role },
      });

      return res.json({ message: 'Profile updated successfully', user });
    }
  } catch (error) {
    console.error('Profile update error:', error);
    res.status(500).json({ error: error.message });
  }
});

// PATCH /api/v1/mentors/profile: Update the authenticated mentor's commercial profile.
app.patch('/api/v1/mentors/profile', verifyAuth, async (req, res) => {
  try {
    if (String(req.user.role).toLowerCase() !== 'mentor') {
      return res.status(403).json({ error: 'Only mentors can update mentor pricing.' });
    }

    const hourlyRate = Number(req.body.hourlyRateNPR);
    const monthlyRate = Number(req.body.monthlyRateNPR);
    const meetingUrl = String(req.body.meetingUrl || '').trim();
    if (!Number.isSafeInteger(hourlyRate) || hourlyRate <= 0 ||
        !Number.isSafeInteger(monthlyRate) || monthlyRate <= 0) {
      return res.status(400).json({ error: 'Hourly and monthly rates must be whole positive NPR amounts.' });
    }
    if (meetingUrl && !/^https?:\/\//i.test(meetingUrl)) {
      return res.status(400).json({ error: 'Meeting URL must start with http:// or https://.' });
    }

    const fields = {
      hourlyRate,
      pricing: { hourly: hourlyRate, monthly: monthlyRate },
      pricingTiers: {
        tier30m: Math.round(hourlyRate * 0.5),
        tier60m: hourlyRate,
        tier120m: Math.round(hourlyRate * 1.8),
      },
      'mentorProfile.monthlyRate': monthlyRate,
      meetingUrl,
    };
    let user;
    const userId = req.user._id || req.user.id;
    if (isMongoConnected) {
      user = await User.findByIdAndUpdate(userId, { $set: fields }, {
        new: true,
        runValidators: true,
      });
    } else {
      user = (global.ymentorMemoryStore?.users || []).find(
        (item) => String(item._id || item.id) === String(userId),
      );
      if (user) {
        user.hourlyRate = hourlyRate;
        user.pricing = { hourly: hourlyRate, monthly: monthlyRate };
        user.pricingTiers = fields.pricingTiers;
        user.mentorProfile ||= {};
        user.mentorProfile.monthlyRate = monthlyRate;
        user.meetingUrl = meetingUrl;
      }
    }
    if (!user) return res.status(404).json({ error: 'Mentor account not found.' });
    return res.json({ message: 'Mentor pricing updated successfully.', user });
  } catch (error) {
    console.error('Mentor profile update error:', error);
    return res.status(500).json({ error: 'Unable to update mentor pricing.' });
  }
});

/* =========================================================================
   3. MENTOR DISCOVERY & SEARCH (/api/users/mentors & /api/mentors)
   ========================================================================= */

// Filter active & approved mentors matching tags/interests
async function handleGetMentors(req, res) {
  try {
    const { interests, skill, q } = req.query;
    const filterTag = interests || skill;
    const searchTerm = String(q || '').trim().slice(0, 100);
    if (searchTerm) {
      try {
        if (isMongoConnected) await SearchEvent.create({ term: searchTerm });
        else {
          global.ymentorMemoryStore.searchEvents ||= [];
          global.ymentorMemoryStore.searchEvents.push({
            term: searchTerm,
            createdAt: new Date(),
          });
        }
      } catch (error) {
        console.error('Search analytics recording failed:', error.message);
      }
    }

    if (isMongoConnected) {
      // Must be active role:mentor
      let query = { role: 'mentor', status: 'active' };

      if (filterTag) {
        const tags = filterTag.split(',').map((t) => t.trim());
        query.$or = [
          {
            'qualifications.skills': {
              $in: tags.map(
                (tag) =>
                  new RegExp(tag.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i'),
              ),
            },
          },
          {
            skillsOrInterests: {
              $in: tags.map(
                (tag) =>
                  new RegExp(tag.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i'),
              ),
            },
          },
        ];
      }

      if (q) {
        const qRegex = new RegExp(
          searchTerm.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'),
          'i',
        );
        const searchOr = [
          { name: qRegex },
          { headline: qRegex },
          { title: qRegex },
          { bio: qRegex },
          { 'qualifications.skills': qRegex },
          { skillsOrInterests: qRegex },
        ];
        if (query.$or) {
          query = { $and: [{ role: 'mentor', status: 'active' }, { $or: query.$or }, { $or: searchOr }] };
        } else {
          query.$or = searchOr;
        }
      }

      const mentors = await User.find(query).sort({ leaderboardScore: -1 });
      return res.json(mentors);
    } else {
      let mentors = global.ymentorMemoryStore.users.filter((u) => u.role === 'mentor' && u.status === 'active');

      if (filterTag) {
        const tags = filterTag
          .split(',')
          .map((t) => t.trim().toLowerCase())
          .filter(Boolean);
        mentors = mentors.filter((m) => {
          const mSkills = (m.skillsOrInterests || []).concat(m.qualifications?.skills || []).map((s) => s.toLowerCase());
          return tags.some((t) => mSkills.some((s) => s.includes(t)));
        });
      }

      if (q) {
        const qLower = q.toLowerCase();
        mentors = mentors.filter((m) => {
          const mSkills = (m.skillsOrInterests || []).concat(m.qualifications?.skills || []).map((s) => s.toLowerCase());
          return (
            (m.name && m.name.toLowerCase().includes(qLower)) ||
            (m.headline && m.headline.toLowerCase().includes(qLower)) ||
            (m.title && m.title.toLowerCase().includes(qLower)) ||
            (m.bio && m.bio.toLowerCase().includes(qLower)) ||
            mSkills.some((s) => s.includes(qLower))
          );
        });
      }

      mentors.sort((a, b) => (b.leaderboardScore || 0) - (a.leaderboardScore || 0));
      return res.json(mentors);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
}

app.get('/api/users/mentors', handleGetMentors);
app.get('/api/mentors', handleGetMentors);

// GET /api/mentors/leaderboard
app.get('/api/mentors/leaderboard', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    if (isMongoConnected) {
      const leaderboard = await User.find({ role: 'mentor', status: 'active' })
        .sort({ leaderboardScore: -1 })
        .limit(limit);
      return res.json(leaderboard);
    } else {
      const leaderboard = global.ymentorMemoryStore.users
        .filter((u) => u.role === 'mentor' && u.status === 'active')
        .sort((a, b) => (b.leaderboardScore || 0) - (a.leaderboardScore || 0))
        .slice(0, limit);
      return res.json(leaderboard);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/mentors/:id: profile & slot generation
app.get('/api/mentors/:id', async (req, res) => {
  try {
    const mentorId = req.params.id;
    let mentor;
    if (isMongoConnected) {
      mentor = await User.findById(mentorId);
    } else {
      mentor = global.ymentorMemoryStore.users.find((u) => u._id === mentorId || u.id === mentorId);
    }

    if (!mentor) {
      return res.status(404).json({ error: 'Mentor not found.' });
    }

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

    res.json({ mentor, availableSlots });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// PATCH /api/mentors/:id/config
app.patch('/api/mentors/:id/config', verifyAuth, async (req, res) => {
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
      const mentor = global.ymentorMemoryStore.users.find((u) => u._id === mentorId || u.id === mentorId);
      if (!mentor) return res.status(404).json({ error: 'Mentor not found.' });
      if (pricingTiers) mentor.pricingTiers = pricingTiers;
      if (meetingUrl) mentor.meetingUrl = meetingUrl;
      return res.json(mentor);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/* =========================================================================
   4. BOOKINGS & ESCROW WORKFLOW (/api/bookings)
   ========================================================================= */

// POST /api/bookings/checkout
app.post('/api/bookings/checkout', verifyAuth, verifyRole(['mentee']), async (req, res) => {
  try {
    const { menteeId, mentorId, durationMinutes, price, scheduledTime } = req.body;

    if (!menteeId || !mentorId || !durationMinutes || !price) {
      return res.status(400).json({ error: 'menteeId, mentorId, durationMinutes, and price are required.' });
    }
    if (String(req.user._id || req.user.id) !== String(menteeId)) {
      return res.status(403).json({ error: 'You can only book a session for your own account.' });
    }

    const numPrice = Number(price);
    if (![30, 60, 120, 180].includes(Number(durationMinutes)) ||
        !Number.isSafeInteger(numPrice) || numPrice <= 0) {
      return res.status(400).json({ error: 'Select a valid session duration and whole NPR price.' });
    }
    const appointmentAt = new Date(scheduledTime || Date.now() + 86400000);
    if (!Number.isFinite(appointmentAt.getTime()) || appointmentAt.getTime() <= Date.now()) {
      return res.status(400).json({ error: 'Select a future session time.' });
    }
    const platformConfig = isMongoConnected
      ? await PlatformConfig.findOne({ key: 'default' })
      : global.ymentorMemoryStore.config;
    const split = splitEscrow(numPrice);
    const platformFee = split.platformFee;
    const mentorNetPayout80Percent = split.mentorPayout;

    if (isMongoConnected) {
      const mentee = await User.findById(menteeId);
      const mentor = await User.findById(mentorId);

      if (!mentee || !mentor) {
        return res.status(404).json({ error: 'Mentee or Mentor not found.' });
      }
      const expectedPrice = Number(durationMinutes) === 30
        ? Number(mentor.pricingTiers?.tier30m ?? mentor.hourlyRate * 0.5)
        : Number(durationMinutes) === 120
            ? Number(mentor.pricingTiers?.tier120m ?? mentor.hourlyRate * 1.8)
            : Math.round(mentor.hourlyRate * Number(durationMinutes) / 60);
      if (mentor.role !== 'mentor' || mentor.status !== 'active' || expectedPrice !== numPrice) {
        return res.status(400).json({ error: 'The mentor is unavailable or the submitted price does not match the selected session.' });
      }

      if (mentee.walletBalance < numPrice) {
        return res.status(400).json({
          error: `Insufficient wallet balance (NPR ${mentee.walletBalance}). Session requires NPR ${numPrice}.`,
        });
      }

      // Deduct from mentee wallet
      mentee.walletBalance -= numPrice;
      if (mentee.wallet) mentee.wallet.balance = mentee.walletBalance;
      await mentee.save();

      // Add to mentor pendingEscrow
      if (mentor.wallet) {
        mentor.wallet.pendingEscrow =
          (mentor.wallet.pendingEscrow || 0) + mentorNetPayout80Percent;
      }
      await mentor.save();

      const booking = new Booking({
        menteeId,
        mentorId,
        durationMinutes: parseInt(durationMinutes),
        scheduledTime: appointmentAt,
        meetingUrl: mentor.meetingUrl || 'https://meet.google.com/abc-defg-hij',
        platformFee,
        escrowStatus: 'held_in_escrow',
        financials: {
          grossAmount: numPrice,
          platformCommission20Percent: platformFee,
          mentorNetPayout80Percent,
          escrowStatus: 'held_in_escrow',
        },
        status: 'CONFIRMED',
      });
      await booking.save();

      // Ensure per-mentee classroom Workspace exists
      let workspace = await Workspace.findOne({
        mentorId,
        menteeId,
        planType: 'hourly',
      });
      if (!workspace) {
        workspace = new Workspace({
          mentorId,
          menteeId,
          planType: 'hourly',
          topic: `${mentor.name} & ${mentee.name} Micro-Mentorship Workspace`,
        });
        await workspace.save();
      }

      await logAudit({
        actorId: mentee._id,
        actorName: mentee.name,
        actorRole: mentee.role,
        action: 'BOOKING_CREATED',
        targetId: booking._id,
        details: { grossAmount: numPrice, platformFee, mentorNetPayout: mentorNetPayout80Percent },
      });

      return res.status(201).json({
        message: 'Escrow payment processed successfully. Session confirmed!',
        booking,
        workspace,
        receipt: {
          transactionId: 'TX-' + booking._id,
          grossAmount: numPrice,
          platformProtectionFee: platformFee,
          mentorNetPayout: mentorNetPayout80Percent,
          escrowStatus: 'held_in_escrow',
          remainingWallet: mentee.walletBalance,
        },
      });
    } else {
      const mentee = global.ymentorMemoryStore.users.find((u) => u._id === menteeId || u.id === menteeId);
      const mentor = global.ymentorMemoryStore.users.find((u) => u._id === mentorId || u.id === mentorId);

      if (!mentee || !mentor) {
        return res.status(404).json({ error: 'Mentee or Mentor not found.' });
      }
      const expectedPrice = Number(durationMinutes) === 30
        ? Number(mentor.pricingTiers?.tier30m ?? mentor.hourlyRate * 0.5)
        : Number(durationMinutes) === 120
            ? Number(mentor.pricingTiers?.tier120m ?? mentor.hourlyRate * 1.8)
            : Math.round(mentor.hourlyRate * Number(durationMinutes) / 60);
      if (mentor.role !== 'mentor' || mentor.status !== 'active' || expectedPrice !== numPrice) {
        return res.status(400).json({ error: 'The mentor is unavailable or the submitted price does not match the selected session.' });
      }

      if (mentee.walletBalance < numPrice) {
        return res.status(400).json({
          error: `Insufficient wallet balance (NPR ${mentee.walletBalance}). Session requires NPR ${numPrice}.`,
        });
      }

      mentee.walletBalance -= numPrice;
      if (mentee.wallet) mentee.wallet.balance = mentee.walletBalance;

      if (mentor.wallet) {
        mentor.wallet.pendingEscrow =
          (mentor.wallet.pendingEscrow || 0) + mentorNetPayout80Percent;
      }

      const newBooking = {
        _id: 'booking-' + Date.now(),
        menteeId,
        mentorId,
        durationMinutes: parseInt(durationMinutes),
        scheduledTime: appointmentAt,
        meetingUrl: mentor.meetingUrl || 'https://meet.google.com/abc-defg-hij',
        platformFee,
        escrowStatus: 'held_in_escrow',
        financials: {
          grossAmount: numPrice,
          platformCommission20Percent: platformFee,
          mentorNetPayout80Percent,
          escrowStatus: 'held_in_escrow',
        },
        status: 'CONFIRMED',
        createdAt: new Date(),
      };
      global.ymentorMemoryStore.bookings.push(newBooking);

      let workspace = global.ymentorMemoryStore.workspaces.find((w) =>
        w.mentorId === mentorId &&
        w.menteeId === menteeId &&
        (w.planType || 'hourly') === 'hourly',
      );
      if (!workspace) {
        workspace = {
          _id: 'workspace-' + Date.now(),
          mentorId,
          menteeId,
          topic: `${mentor.name} & ${mentee.name} Classroom Workspace`,
          createdAt: new Date(),
          lastActivityAt: new Date(),
        };
        global.ymentorMemoryStore.workspaces.push(workspace);
      }

      await logAudit({
        actorId: mentee._id,
        actorName: mentee.name,
        actorRole: mentee.role,
        action: 'BOOKING_CREATED',
        targetId: newBooking._id,
        details: { grossAmount: numPrice, platformFee, mentorNetPayout: mentorNetPayout80Percent },
      });

      return res.status(201).json({
        message: 'Escrow payment processed successfully. Session confirmed!',
        booking: newBooking,
        workspace,
        receipt: {
          transactionId: 'TX-' + newBooking._id,
          grossAmount: numPrice,
          platformProtectionFee: platformFee,
          mentorNetPayout: mentorNetPayout80Percent,
          escrowStatus: 'held_in_escrow',
          remainingWallet: mentee.walletBalance,
        },
      });
    }
  } catch (error) {
    console.error('Checkout error:', error);
    res.status(500).json({ error: error.message });
  }
});

// PUT /api/bookings/:id/complete: release escrow funds (80%)
app.put('/api/bookings/:id/complete', verifyAuth, verifyRole(['mentee']), async (req, res) => {
  try {
    const bookingId = req.params.id;
    const { rating = 5.0, reviewNote = 'Outstanding mentorship session!' } = req.body;

    if (isMongoConnected) {
      const booking = await Booking.findById(bookingId);
      if (!booking) return res.status(404).json({ error: 'Booking not found.' });
      if (String(booking.menteeId) !== String(req.user._id)) {
        return res.status(403).json({ error: 'Only the booking mentee can complete this session.' });
      }

      if (booking.escrowStatus === 'released' || booking.financials?.escrowStatus === 'released') {
        return res.json({ message: 'Escrow has already been released.', booking });
      }
      if (booking.planType === 'monthly' && booking.planEndsAt > new Date()) {
        return res.status(400).json({ error: 'Monthly mentorship funds remain held until the plan period ends.' });
      }

      booking.escrowStatus = 'released';
      if (booking.financials) booking.financials.escrowStatus = 'released';
      booking.status = 'COMPLETED';
      booking.ratingGiven = rating;
      booking.reviewNote = reviewNote;
      await booking.save();
      await Review.findOneAndUpdate(
        { bookingId: booking._id },
        { $setOnInsert: { bookingId: booking._id, mentorId: booking.mentorId, menteeId: booking.menteeId, rating, text: reviewNote, status: 'pending' } },
        { upsert: true, new: true },
      );

      const mentor = await User.findById(booking.mentorId);
      if (mentor) {
        const payout = booking.financials?.mentorNetPayout80Percent || 16.0;
        mentor.walletBalance = parseFloat(((mentor.walletBalance || 0) + payout).toFixed(2));
        if (mentor.wallet) {
          mentor.wallet.balance = mentor.walletBalance;
          mentor.wallet.pendingEscrow = Math.max(0, parseFloat(((mentor.wallet.pendingEscrow || 0) - payout).toFixed(2)));
        }
        mentor.totalSessions = (mentor.totalSessions || 0) + 1;
        mentor.ratingAvg = parseFloat(
          (((mentor.ratingAvg || 5.0) * (mentor.totalSessions - 1) + rating) / mentor.totalSessions).toFixed(2)
        );
        mentor.calculateLeaderboardScore();
        await mentor.save();
      }

      await logAudit({
        actorId: booking.menteeId,
        action: 'ESCROW_RELEASED',
        targetId: booking._id,
        details: { mentorId: booking.mentorId, rating, payout: booking.financials?.mentorNetPayout80Percent },
      });

      return res.json({
        message: 'Escrow released successfully! Mentor wallet credited.',
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
      const booking = global.ymentorMemoryStore.bookings.find((b) => b._id === bookingId || b.id === bookingId);
      if (!booking) return res.status(404).json({ error: 'Booking not found.' });
      if (String(booking.menteeId) !== String(req.user._id || req.user.id)) {
        return res.status(403).json({ error: 'Only the booking mentee can complete this session.' });
      }
      if (booking.escrowStatus === 'released') {
        return res.json({ message: 'Escrow has already been released.', booking });
      }
      if (booking.planType === 'monthly' && new Date(booking.planEndsAt) > new Date()) {
        return res.status(400).json({ error: 'Monthly mentorship funds remain held until the plan period ends.' });
      }

      booking.escrowStatus = 'released';
      if (booking.financials) booking.financials.escrowStatus = 'released';
      booking.status = 'COMPLETED';
      booking.ratingGiven = rating;
      booking.reviewNote = reviewNote;
      global.ymentorMemoryStore.reviews ||= [];
      global.ymentorMemoryStore.reviews.push({
        _id: `review-${Date.now()}`,
        bookingId: booking._id,
        mentorId: booking.mentorId,
        menteeId: booking.menteeId,
        rating,
        text: reviewNote,
        status: 'pending',
        createdAt: new Date(),
      });

      const mentor = global.ymentorMemoryStore.users.find((u) => u._id === booking.mentorId || u.id === booking.mentorId);
      if (mentor) {
        const payout = booking.financials?.mentorNetPayout80Percent || 16.0;
        mentor.walletBalance = parseFloat(((mentor.walletBalance || 0) + payout).toFixed(2));
        if (mentor.wallet) {
          mentor.wallet.balance = mentor.walletBalance;
          mentor.wallet.pendingEscrow = Math.max(0, parseFloat(((mentor.wallet.pendingEscrow || 0) - payout).toFixed(2)));
        }
        mentor.totalSessions = (mentor.totalSessions || 0) + 1;
        mentor.ratingAvg = parseFloat(
          (((mentor.ratingAvg || 5.0) * (mentor.totalSessions - 1) + rating) / mentor.totalSessions).toFixed(2)
        );
        mentor.leaderboardScore = computeScore(mentor.ratingAvg, mentor.totalSessions);
      }

      await logAudit({
        actorId: booking.menteeId,
        action: 'ESCROW_RELEASED',
        targetId: booking._id,
        details: { mentorId: booking.mentorId, rating },
      });

      return res.json({
        message: 'Escrow released successfully! Mentor wallet credited.',
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
    console.error('Complete booking error:', error);
    res.status(500).json({ error: error.message });
  }
});

// GET /api/bookings/user/:userId
app.get('/api/bookings/user/:userId', verifyAuth, async (req, res) => {
  try {
    const userId = req.params.userId;
    if (String(req.user._id || req.user.id) !== String(userId)) {
      return res.status(403).json({ error: 'You can only view your own bookings.' });
    }
    if (isMongoConnected) {
      const bookings = await Booking.find({
        $or: [{ menteeId: userId }, { mentorId: userId }],
      })
        .populate('menteeId', 'name email avatarUrl')
        .populate('mentorId', 'name email avatarUrl headline')
        .sort({ scheduledTime: -1 });
      return res.json(bookings);
    } else {
      const bookings = global.ymentorMemoryStore.bookings.filter(
        (b) => (b.menteeId?._id || b.menteeId) === userId || (b.mentorId?._id || b.mentorId) === userId
      );
      return res.json(bookings);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/* =========================================================================
   5. WORKSPACE & PDF NOTES ROUTES (/api/workspaces)
   ========================================================================= */

// GET /api/workspaces/user/:userId
app.get('/api/workspaces/user/:userId', verifyAuth, async (req, res) => {
  try {
    const userId = req.params.userId;
    if (String(req.user._id || req.user.id) !== String(userId)) {
      return res.status(403).json({ error: 'You can only view your own workspaces.' });
    }
    if (isMongoConnected) {
      const workspaces = await Workspace.find({
        $or: [{ menteeId: userId }, { mentorId: userId }],
      })
        .populate('menteeId', 'name email avatarUrl')
        .populate('mentorId', 'name email avatarUrl headline')
        .sort({ lastActivityAt: -1 });
      return res.json(workspaces);
    } else {
      const workspaces = global.ymentorMemoryStore.workspaces
        .filter((w) => (w.menteeId?._id || w.menteeId) === userId || (w.mentorId?._id || w.mentorId) === userId)
        .map((w) => {
          const mentee = global.ymentorMemoryStore.users.find((u) => u._id === w.menteeId || u.id === w.menteeId);
          const mentor = global.ymentorMemoryStore.users.find((u) => u._id === w.mentorId || u.id === w.mentorId);
          return {
            ...w,
            menteeId: mentee || { name: 'Sarah Chen', email: 'sarah.chen@ymentor.com' },
            mentorId: mentor || { name: 'Alex Morgan', email: 'alex.morgan@ymentor.com' },
          };
        });
      return res.json(workspaces);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/workspaces/:workspaceId/notes
app.get('/api/workspaces/:workspaceId/notes', verifyAuth, async (req, res) => {
  try {
    const workspaceId = req.params.workspaceId;
    if (isMongoConnected) {
      const workspace = await Workspace.findById(workspaceId);
      if (!workspace || (![String(workspace.mentorId), String(workspace.menteeId)].includes(String(req.user._id)))) {
        return res.status(404).json({ error: 'Workspace not found.' });
      }
      const notes = await Note.find({ workspaceId }).sort({ createdAt: -1 });
      return res.json(notes);
    } else {
      const workspace = global.ymentorMemoryStore.workspaces.find((item) => item._id === workspaceId);
      if (!workspace || (![String(workspace.mentorId), String(workspace.menteeId)].includes(String(req.user._id || req.user.id)))) {
        return res.status(404).json({ error: 'Workspace not found.' });
      }
      const notes = global.ymentorMemoryStore.notes.filter((n) => n.workspaceId === workspaceId);
      return res.json(notes);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// POST /api/workspaces/:workspaceId/notes (Multer PDF upload)
app.post('/api/workspaces/:workspaceId/notes', verifyAuth, upload.single('pdf'), async (req, res) => {
  try {
    const workspaceId = req.params.workspaceId;
    const { title, description, uploadedBy, dueDate } = req.body;
    if (req.user.role !== 'mentor' || String(req.user._id || req.user.id) !== String(uploadedBy)) {
      return res.status(403).json({ error: 'Only the signed-in mentor can upload to a classroom.' });
    }

    const pdfUrl = req.file ? `/uploads/${req.file.filename}` : '/uploads/sample-assignment.pdf';

    if (isMongoConnected) {
      const workspace = await Workspace.findById(workspaceId);
      if (!workspace || String(workspace.mentorId) !== String(req.user._id)) {
        return res.status(404).json({ error: 'Mentor workspace not found.' });
      }
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
      await Workspace.findByIdAndUpdate(workspaceId, { lastActivityAt: new Date() });

      await logAudit({
        actorId: uploadedBy,
        action: 'NOTE_UPLOADED',
        targetId: note._id,
        details: { title: note.title, pdfUrl },
      });

      return res.status(201).json(note);
    } else {
      const workspace = global.ymentorMemoryStore.workspaces.find((item) => item._id === workspaceId);
      if (!workspace || String(workspace.mentorId) !== String(req.user._id || req.user.id)) {
        return res.status(404).json({ error: 'Mentor workspace not found.' });
      }
      const newNote = {
        _id: 'note-' + Date.now(),
        workspaceId,
        title: title || (req.file ? req.file.originalname : 'Mentorship Exercise PDF'),
        description: description || 'Assignment material attached for review.',
        dueDate: dueDate || 'Next Sunday, 11:59 PM',
        pdfUrl,
        uploadedBy: uploadedBy || 'user-mentor-seed',
        isCompleted: false,
        comments: [],
        createdAt: new Date(),
      };
      global.ymentorMemoryStore.notes.push(newNote);

      await logAudit({
        actorId: uploadedBy,
        action: 'NOTE_UPLOADED',
        targetId: newNote._id,
        details: { title: newNote.title, pdfUrl },
      });

      return res.status(201).json(newNote);
    }
  } catch (error) {
    console.error('Note upload error:', error);
    res.status(500).json({ error: error.message });
  }
});

// POST /api/workspaces/notes/:noteId/comments
app.post('/api/workspaces/notes/:noteId/comments', verifyAuth, async (req, res) => {
  try {
    const noteId = req.params.noteId;
    const { senderId, senderName, message } = req.body;

    if (!message || !message.trim()) {
      return res.status(400).json({ error: 'Comment message cannot be empty.' });
    }

    if (isMongoConnected) {
      const note = await Note.findById(noteId);
      if (!note) return res.status(404).json({ error: 'Note not found.' });
      const workspace = await Workspace.findById(note.workspaceId);
      if (!workspace || (![String(workspace.mentorId), String(workspace.menteeId)].includes(String(req.user._id)))) {
        return res.status(404).json({ error: 'Workspace not found.' });
      }

      const comment = {
        senderId: req.user._id,
        senderName: req.user.name,
        message: message.trim(),
        createdAt: new Date(),
      };
      note.comments.push(comment);
      await note.save();
      return res.status(201).json(comment);
    } else {
      const note = global.ymentorMemoryStore.notes.find((n) => n._id === noteId || n.id === noteId);
      if (!note) return res.status(404).json({ error: 'Note not found.' });
      const workspace = global.ymentorMemoryStore.workspaces.find((item) => item._id === note.workspaceId);
      if (!workspace || (![String(workspace.mentorId), String(workspace.menteeId)].includes(String(req.user._id || req.user.id)))) {
        return res.status(404).json({ error: 'Workspace not found.' });
      }

      const comment = {
        _id: 'comment-' + Date.now(),
        senderId: req.user._id || req.user.id,
        senderName: req.user.name,
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

// PATCH /api/workspaces/notes/:noteId/toggle
app.patch('/api/workspaces/notes/:noteId/toggle', verifyAuth, async (req, res) => {
  try {
    const noteId = req.params.noteId;
    if (isMongoConnected) {
      const note = await Note.findById(noteId);
      if (!note) return res.status(404).json({ error: 'Note not found' });
      const workspace = await Workspace.findById(note.workspaceId);
      if (!workspace || (![String(workspace.mentorId), String(workspace.menteeId)].includes(String(req.user._id)))) {
        return res.status(404).json({ error: 'Workspace not found.' });
      }
      note.isCompleted = !note.isCompleted;
      await note.save();
      return res.json(note);
    } else {
      const note = global.ymentorMemoryStore.notes.find((n) => n._id === noteId || n.id === noteId);
      if (!note) return res.status(404).json({ error: 'Note not found' });
      const workspace = global.ymentorMemoryStore.workspaces.find((item) => item._id === note.workspaceId);
      if (!workspace || (![String(workspace.mentorId), String(workspace.menteeId)].includes(String(req.user._id || req.user.id)))) {
        return res.status(404).json({ error: 'Workspace not found.' });
      }
      note.isCompleted = !note.isCompleted;
      return res.json(note);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/* =========================================================================
   6. ADMIN ENDPOINTS (Protected by verifyAuth and verifyRole(['admin']))
   ========================================================================= */

// GET /api/admin/pending-mentors: list mentors awaiting verification
app.get('/api/admin/pending-mentors', verifyAuth, verifyRole(['admin']), async (req, res) => {
  try {
    if (isMongoConnected) {
      const pendingMentors = await User.find({
        role: 'mentor',
        status: 'pending_approval',
      }).sort({ createdAt: -1 });
      return res.json(pendingMentors);
    } else {
      const pendingMentors = global.ymentorMemoryStore.users.filter(
        (u) => u.role === 'mentor' && u.status === 'pending_approval'
      );
      return res.json(pendingMentors);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// PUT /api/admin/approve-mentor/:id: approve a pending mentor
app.put('/api/admin/approve-mentor/:id', verifyAuth, verifyRole(['admin']), async (req, res) => {
  try {
    const mentorId = req.params.id;

    if (isMongoConnected) {
      const mentor = await User.findById(mentorId);
      if (!mentor) return res.status(404).json({ error: 'Mentor not found.' });

      mentor.status = 'active';
      mentor.isIdentityVerified = true;
      mentor.isSkillVerified = true;
      await mentor.save();

      await logAudit({
        actorId: req.user._id,
        actorName: req.user.name,
        actorRole: req.user.role,
        action: 'MENTOR_APPROVED',
        targetId: mentor._id,
        details: { approvedMentorEmail: mentor.email, approvedMentorName: mentor.name },
      });

      return res.json({ message: `Mentor ${mentor.name} successfully approved!`, user: mentor });
    } else {
      const mentor = global.ymentorMemoryStore.users.find((u) => u._id === mentorId || u.id === mentorId);
      if (!mentor) return res.status(404).json({ error: 'Mentor not found.' });

      mentor.status = 'active';
      mentor.isIdentityVerified = true;
      mentor.isSkillVerified = true;

      await logAudit({
        actorId: req.user._id,
        actorName: req.user.name,
        actorRole: req.user.role,
        action: 'MENTOR_APPROVED',
        targetId: mentor._id,
        details: { approvedMentorEmail: mentor.email, approvedMentorName: mentor.name },
      });

      return res.json({ message: `Mentor ${mentor.name} successfully approved!`, user: mentor });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// PUT /api/admin/toggle-user-status/:id: ban / unban / activate / suspend
app.put('/api/admin/toggle-user-status/:id', verifyAuth, verifyRole(['admin']), async (req, res) => {
  try {
    const targetUserId = req.params.id;
    const { status } = req.body;

    if (isMongoConnected) {
      const targetUser = await User.findById(targetUserId);
      if (!targetUser) return res.status(404).json({ error: 'User not found.' });

      const newStatus = status || (targetUser.status === 'suspended' ? 'active' : 'suspended');
      targetUser.status = newStatus;
      await targetUser.save();

      await logAudit({
        actorId: req.user._id,
        actorName: req.user.name,
        actorRole: req.user.role,
        action: newStatus === 'suspended' ? 'USER_SUSPENDED' : 'USER_ACTIVATED',
        targetId: targetUser._id,
        details: { email: targetUser.email, newStatus },
      });

      return res.json({
        message: `User status changed to ${newStatus}`,
        user: targetUser,
      });
    } else {
      const targetUser = global.ymentorMemoryStore.users.find((u) => u._id === targetUserId || u.id === targetUserId);
      if (!targetUser) return res.status(404).json({ error: 'User not found.' });

      const newStatus = status || (targetUser.status === 'suspended' ? 'active' : 'suspended');
      targetUser.status = newStatus;

      await logAudit({
        actorId: req.user._id,
        actorName: req.user.name,
        actorRole: req.user.role,
        action: newStatus === 'suspended' ? 'USER_SUSPENDED' : 'USER_ACTIVATED',
        targetId: targetUser._id,
        details: { email: targetUser.email, newStatus },
      });

      return res.json({
        message: `User status changed to ${newStatus}`,
        user: targetUser,
      });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/admin/escrow-transactions: view platform escrow transactions and fee breakdown
app.get('/api/admin/escrow-transactions', verifyAuth, verifyRole(['admin']), async (req, res) => {
  try {
    if (isMongoConnected) {
      const bookings = await Booking.find({})
        .populate('menteeId', 'name email')
        .populate('mentorId', 'name email')
        .sort({ createdAt: -1 });

      const totals = bookings.reduce(
        (acc, b) => {
          const gross = b.financials?.grossAmount || 0;
          const fee = b.platformFee || b.financials?.platformCommission20Percent || 400;
          const net = b.financials?.mentorNetPayout80Percent || gross - fee;
          acc.totalGross += gross;
          acc.totalPlatformFees += fee;
          if (b.escrowStatus === 'held_in_escrow' || b.financials?.escrowStatus === 'held_in_escrow') {
            acc.totalHeldInEscrow += net;
          } else if (b.escrowStatus === 'released' || b.financials?.escrowStatus === 'released') {
            acc.totalReleased += net;
          }
          return acc;
        },
        { totalGross: 0, totalPlatformFees: 0, totalHeldInEscrow: 0, totalReleased: 0 }
      );

      return res.json({ totals, transactions: bookings });
    } else {
      const bookings = global.ymentorMemoryStore.bookings.map((b) => {
        const mentee = global.ymentorMemoryStore.users.find((u) => u._id === b.menteeId || u.id === b.menteeId);
        const mentor = global.ymentorMemoryStore.users.find((u) => u._id === b.mentorId || u.id === b.mentorId);
        return {
          ...b,
          menteeId: mentee ? { name: mentee.name, email: mentee.email } : { name: 'Mentee', email: 'mentee@demo.com' },
          mentorId: mentor ? { name: mentor.name, email: mentor.email } : { name: 'Mentor', email: 'mentor@demo.com' },
        };
      });

      const totals = bookings.reduce(
        (acc, b) => {
          const gross = b.financials?.grossAmount || 0;
          const fee = b.platformFee || b.financials?.platformCommission20Percent || 400;
          const net = b.financials?.mentorNetPayout80Percent || gross - fee;
          acc.totalGross += gross;
          acc.totalPlatformFees += fee;
          if (b.escrowStatus === 'held_in_escrow') {
            acc.totalHeldInEscrow += net;
          } else {
            acc.totalReleased += net;
          }
          return acc;
        },
        { totalGross: 0, totalPlatformFees: 0, totalHeldInEscrow: 0, totalReleased: 0 }
      );

      return res.json({ totals, transactions: bookings });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// PUT /api/admin/release-escrow/:bookingId: manual admin release override
app.put('/api/admin/release-escrow/:bookingId', verifyAuth, verifyRole(['admin']), async (req, res) => {
  try {
    const bookingId = req.params.bookingId;

    if (isMongoConnected) {
      const booking = await Booking.findById(bookingId);
      if (!booking) return res.status(404).json({ error: 'Booking not found.' });

      if (booking.escrowStatus === 'released' || booking.financials?.escrowStatus === 'released') {
        return res.status(400).json({ error: 'Escrow for this booking has already been released.' });
      }

      booking.escrowStatus = 'released';
      if (booking.financials) booking.financials.escrowStatus = 'released';
      booking.status = 'COMPLETED';
      await booking.save();

      const mentor = await User.findById(booking.mentorId);
      if (mentor) {
        const payout = booking.financials?.mentorNetPayout80Percent || 16.0;
        mentor.walletBalance = parseFloat(((mentor.walletBalance || 0) + payout).toFixed(2));
        if (mentor.wallet) {
          mentor.wallet.balance = mentor.walletBalance;
          mentor.wallet.pendingEscrow = Math.max(0, parseFloat(((mentor.wallet.pendingEscrow || 0) - payout).toFixed(2)));
        }
        mentor.totalSessions = (mentor.totalSessions || 0) + 1;
        mentor.calculateLeaderboardScore();
        await mentor.save();
      }

      await logAudit({
        actorId: req.user._id,
        actorName: req.user.name,
        actorRole: req.user.role,
        action: 'ADMIN_RELEASE_ESCROW',
        targetId: booking._id,
        details: { bookingId, mentorId: booking.mentorId, amount: booking.financials?.mentorNetPayout80Percent },
      });

      return res.json({ message: 'Escrow released by administrator override.', booking });
    } else {
      const booking = global.ymentorMemoryStore.bookings.find((b) => b._id === bookingId || b.id === bookingId);
      if (!booking) return res.status(404).json({ error: 'Booking not found.' });

      booking.escrowStatus = 'released';
      if (booking.financials) booking.financials.escrowStatus = 'released';
      booking.status = 'COMPLETED';

      const mentor = global.ymentorMemoryStore.users.find((u) => u._id === booking.mentorId || u.id === booking.mentorId);
      if (mentor) {
        const payout = booking.financials?.mentorNetPayout80Percent || 16.0;
        mentor.walletBalance = parseFloat(((mentor.walletBalance || 0) + payout).toFixed(2));
        if (mentor.wallet) {
          mentor.wallet.balance = mentor.walletBalance;
          mentor.wallet.pendingEscrow = Math.max(0, parseFloat(((mentor.wallet.pendingEscrow || 0) - payout).toFixed(2)));
        }
        mentor.totalSessions = (mentor.totalSessions || 0) + 1;
        mentor.leaderboardScore = computeScore(mentor.ratingAvg, mentor.totalSessions);
      }

      await logAudit({
        actorId: req.user._id,
        actorName: req.user.name,
        actorRole: req.user.role,
        action: 'ADMIN_RELEASE_ESCROW',
        targetId: booking._id,
        details: { bookingId, mentorId: booking.mentorId },
      });

      return res.json({ message: 'Escrow released by administrator override.', booking });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/admin/audit-logs: retrieve chronological timeline of system logs
app.get('/api/admin/audit-logs', verifyAuth, verifyRole(['admin']), async (req, res) => {
  try {
    if (isMongoConnected) {
      const logs = await AuditLog.find({}).sort({ timestamp: -1 }).limit(100);
      return res.json(logs);
    } else {
      const memoryLogs = getMemoryAuditLogs();
      return res.json(memoryLogs);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/admin/users: view all users for administration
app.get('/api/admin/users', verifyAuth, verifyRole(['admin']), async (req, res) => {
  try {
    if (isMongoConnected) {
      const users = await User.find({}).sort({ createdAt: -1 });
      return res.json(users);
    } else {
      return res.json(global.ymentorMemoryStore.users);
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/* =========================================================================
   7. HEALTH CHECK & START SERVER
   ========================================================================= */

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ONLINE',
    service: 'Ymentor 3-Role API Engine',
    roles: ['admin', 'mentor', 'mentee'],
    mongoConnected: isMongoConnected,
    timestamp: new Date().toISOString(),
  });
});

app.get('/api/platform/fees', async (req, res) => {
  const amount = Number(req.query.amount);
  if (!Number.isFinite(amount) || amount <= 0) {
    return res.status(400).json({ error: 'A positive amount is required.' });
  }
  try {
    const config = isMongoConnected
      ? await PlatformConfig.findOne({ key: 'default' })
      : global.ymentorMemoryStore.config;
    const fee = Number(config?.percentageFee) > 0
      ? Number((amount * config.percentageFee / 100).toFixed(2))
      : Number(config?.flatFee ?? 4);
    return res.json({ fee, mentorNetPayout: Number((amount - fee).toFixed(2)) });
  } catch (error) {
    console.error('Platform fee lookup failed:', error);
    return res.status(500).json({ error: 'Unable to calculate platform fees.' });
  }
});

if (require.main === module) {
  app.listen(PORT, HOST, () => {
    console.log(`🚀 Ymentor API server listening on http://${HOST}:${PORT}`);
    console.log(`📡 Devices on your Wi-Fi can connect to http://${WIFI_HOST}:${PORT}`);
  });
}

app.autoSeedBaselineAccounts = autoSeedBaselineAccounts;

module.exports = app;
