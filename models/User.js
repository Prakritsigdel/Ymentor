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
    tier30m: { type: Number, default: 12.0 },
    tier60m: { type: Number, default: 20.0 },
    tier120m: { type: Number, default: 38.0 },
  },
  { _id: false }
);

const WalletSchema = new mongoose.Schema(
  {
    balance: { type: Number, default: 100.0 },
    pendingEscrow: { type: Number, default: 0.0 },
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
    status: {
      type: String,
      enum: ['pending_approval', 'active', 'suspended'],
      default: 'active',
    },
    faculty: { type: String, default: '' },
    skillsOrInterests: { type: [String], default: [] },
    title: { type: String, default: '' },
    bio: { type: String, default: '' },
    hourlyRate: { type: Number, default: 20.0 },
    isOnboarded: { type: Boolean, default: false },
    wallet: { type: WalletSchema, default: () => ({ balance: 100.0, pendingEscrow: 0.0 }) },
    avatarUrl: { type: String, default: '' },
    headline: { type: String, default: '' },
    isIdentityVerified: { type: Boolean, default: false },
    isSkillVerified: { type: Boolean, default: false },
    qualifications: { type: QualificationsSchema, default: () => ({}) },
    pricingTiers: { type: PricingTiersSchema, default: () => ({}) },
    meetingUrl: { type: String, default: 'https://meet.google.com/abc-defg-hij' },
    ratingAvg: { type: Number, default: 5.0 },
    totalSessions: { type: Number, default: 0 },
    leaderboardScore: { type: Number, default: 0.0 },
    walletBalance: { type: Number, default: 100.0 },
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
    // ensure walletBalance is present
    if (ret.wallet && ret.wallet.balance !== undefined) {
      ret.walletBalance = ret.wallet.balance;
    }
    return ret;
  },
});

module.exports = mongoose.model('User', UserSchema);
