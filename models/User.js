const mongoose = require('mongoose');

const QualificationsSchema = new mongoose.Schema(
  {
    degree: { type: String, default: 'Software Developer' },
    faculty: { type: String, default: 'Computer Science' },
    skills: { type: [String], default: [] },
    githubUrl: { type: String, default: 'https://github.com' },
    linkedinUrl: { type: String, default: 'https://linkedin.com' },
  },
  { _id: false }
);

const PricingTiersSchema = new mongoose.Schema(
  {
    tier30m: { type: Number, default: 1200, min: 0, validate: Number.isInteger },
    tier60m: { type: Number, default: 2000, min: 0, validate: Number.isInteger },
    tier120m: { type: Number, default: 3800, min: 0, validate: Number.isInteger },
  },
  { _id: false }
);

const PricingSchema = new mongoose.Schema(
  {
    hourly: { type: Number, default: 0, min: 0, validate: Number.isInteger },
    monthly: { type: Number, default: 0, min: 0, validate: Number.isInteger },
  },
  { _id: false }
);

const WalletSchema = new mongoose.Schema(
  {
    balance: { type: Number, default: 40000, min: 0, validate: Number.isInteger },
    pendingEscrow: { type: Number, default: 0, min: 0, validate: Number.isInteger },
  },
  { _id: false }
);

const MentorProfileSchema = new mongoose.Schema(
  {
    dateOfBirth: { type: Date },
    location: { type: String, default: '' },
    timezone: { type: String, default: '' },
    primaryDomain: { type: String, default: '' },
    subSkills: { type: [String], default: [] },
    yearsExperience: { type: Number, default: 0 },
    currentOrganization: { type: String, default: '' },
    monthlyRate: { type: Number, default: 0, min: 0, validate: Number.isInteger },
    maxMentees: { type: Number, default: 0 },
    weeklyAvailableHours: { type: Number, default: 0 },
    fluentLanguages: { type: [String], default: [] },
    qualificationDocUrl: { type: String, default: '' },
    identityDocUrl: { type: String, default: '' },
    governmentIdType: { type: String, default: '' },
    portfolioUrl: { type: String, default: '' },
  },
  { _id: false }
);

const MenteeProfileSchema = new mongoose.Schema(
  {
    academicStatus: { type: String, default: '' },
    fieldOfInterest: { type: String, default: '' },
    primaryGoal: { type: String, default: '' },
    targetSkills: { type: [String], default: [] },
    competencyLevel: { type: String, default: 'beginner' },
    preferredMode: { type: String, default: 'not_sure' },
    mentorStyle: { type: String, default: '' },
    targetBudget: { type: Number, default: 0, min: 0, validate: Number.isInteger },
    weeklyCommitmentHours: { type: Number, default: 0 },
  },
  { _id: false }
);

const UserSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, lowercase: true },
    password: { type: String, required: true },
    role: {
      type: String,
      enum: ['admin', 'mentor', 'mentee'],
      default: 'mentee',
    },
    currency: { type: String, enum: ['NPR'], default: 'NPR' },
    status: {
      type: String,
      enum: ['pending_approval', 'active', 'suspended'],
      default: 'active',
    },
    faculty: { type: String, default: '' },
    skillsOrInterests: { type: [String], default: [] },
    title: { type: String, default: '' },
    bio: { type: String, default: '' },
    hourlyRate: { type: Number, default: 2000, min: 0, validate: Number.isInteger },
    pricing: { type: PricingSchema, default: () => ({}) },
    isOnboarded: { type: Boolean, default: false },
    wallet: { type: WalletSchema, default: () => ({ balance: 40000, pendingEscrow: 0 }) },
    avatarUrl: { type: String, default: '' },
    headline: { type: String, default: '' },
    isIdentityVerified: { type: Boolean, default: false },
    isSkillVerified: { type: Boolean, default: false },
    qualifications: { type: QualificationsSchema, default: () => ({}) },
    pricingTiers: { type: PricingTiersSchema, default: () => ({}) },
    meetingUrl: { type: String, default: '' },
    ratingAvg: { type: Number, default: 5.0 },
    totalSessions: { type: Number, default: 0 },
    leaderboardScore: { type: Number, default: 0.0 },
    walletBalance: { type: Number, default: 40000, min: 0, validate: Number.isInteger },
    verificationStatus: {
      type: String,
      enum: ['NOT_SUBMITTED', 'PENDING_APPROVAL', 'APPROVED', 'REJECTED'],
      default: 'NOT_SUBMITTED',
    },
    verificationReason: { type: String, default: '' },
    mentorProfile: { type: MentorProfileSchema, default: () => ({}) },
    menteeProfile: { type: MenteeProfileSchema, default: () => ({}) },
  },
  { timestamps: true }
);

// Synchronize walletBalance with wallet.balance before save
UserSchema.pre('save', function (next) {
  if (this.wallet) {
    if (this.isModified('wallet.balance')) {
      this.walletBalance = this.wallet.balance;
    } else if (this.isModified('walletBalance')) {
      this.wallet.balance = this.walletBalance;
    }
  }
  // Sync skills with skillsOrInterests if one is empty
  if (this.skillsOrInterests && this.skillsOrInterests.length > 0 && (!this.qualifications.skills || this.qualifications.skills.length === 0)) {
    this.qualifications.skills = this.skillsOrInterests;
  } else if (this.qualifications && this.qualifications.skills && this.qualifications.skills.length > 0 && (!this.skillsOrInterests || this.skillsOrInterests.length === 0)) {
    this.skillsOrInterests = this.qualifications.skills;
  }
  // Sync faculty with qualifications.faculty
  if (this.faculty && !this.qualifications.faculty) {
    this.qualifications.faculty = this.faculty;
  } else if (this.qualifications && this.qualifications.faculty && !this.faculty) {
    this.faculty = this.qualifications.faculty;
  }
  next();
});

// leaderboardScore = (ratingAvg * 0.7) + (log10(totalSessions + 1) * 0.3)
UserSchema.methods.calculateLeaderboardScore = function () {
  const r = (this.ratingAvg || 5.0) * 0.7;
  const s = Math.log10((this.totalSessions || 0) + 1) * 0.3;
  this.leaderboardScore = parseFloat((r + s).toFixed(4));
  return this.leaderboardScore;
};

UserSchema.set('toJSON', {
  transform: (doc, ret) => {
    delete ret.password;
    delete ret.mentorProfile?.qualificationDocUrl;
    delete ret.mentorProfile?.identityDocUrl;
    // ensure walletBalance is present
    if (ret.wallet && ret.wallet.balance !== undefined) {
      ret.walletBalance = ret.wallet.balance;
    }
    return ret;
  },
});

module.exports = mongoose.model('User', UserSchema);
