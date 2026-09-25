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

const UserSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, lowercase: true },
    password: { type: String, required: true },
    role: { type: String, enum: ['mentee', 'mentor'], default: 'mentee' },
    avatarUrl: { type: String, default: '' },
    headline: { type: String, default: '' },
    bio: { type: String, default: '' },
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
    return ret;
  },
});

module.exports = mongoose.model('User', UserSchema);
