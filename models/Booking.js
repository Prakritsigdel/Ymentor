const mongoose = require('mongoose');

const FinancialsSchema = new mongoose.Schema(
  {
    currency: { type: String, enum: ['NPR'], default: 'NPR' },
    grossAmount: { type: Number, required: true, min: 0, validate: Number.isInteger },
    platformCommission20Percent: { type: Number, required: true, min: 0, validate: Number.isInteger },
    mentorNetPayout80Percent: { type: Number, required: true, min: 0, validate: Number.isInteger },
    escrowStatus: {
      type: String,
      enum: ['held_in_escrow', 'release_requested', 'released', 'refunded', 'HELD', 'RELEASED', 'REFUNDED'],
      default: 'held_in_escrow',
    },
  },
  { _id: false }
);

const BookingSchema = new mongoose.Schema(
  {
    menteeId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    mentorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    durationMinutes: { type: Number, enum: [0, 30, 60, 120, 180], required: true },
    planType: { type: String, enum: ['hourly', 'monthly'], default: 'hourly' },
    planStartsAt: { type: Date },
    planEndsAt: { type: Date },
    conversationId: { type: mongoose.Schema.Types.ObjectId, ref: 'ChatConversation' },
    scheduledTime: { type: Date, required: true },
    meetingUrl: { type: String, default: 'https://meet.google.com/abc-defg-hij' },
    currency: { type: String, enum: ['NPR'], default: 'NPR' },
    platformFee: { type: Number, default: 0, min: 0, validate: Number.isInteger },
    escrowStatus: {
      type: String,
      enum: ['held_in_escrow', 'release_requested', 'released', 'refunded', 'HELD', 'RELEASED', 'REFUNDED'],
      default: 'held_in_escrow',
    },
    financials: { type: FinancialsSchema, required: true },
    status: { type: String, enum: ['CONFIRMED', 'COMPLETED', 'CANCELLED'], default: 'CONFIRMED' },
    ratingGiven: { type: Number },
    reviewNote: { type: String },
  },
  { timestamps: true }
);

BookingSchema.pre('save', function (next) {
  if (this.escrowStatus && (!this.financials || !this.financials.escrowStatus)) {
    if (this.financials) this.financials.escrowStatus = this.escrowStatus;
  } else if (this.financials && this.financials.escrowStatus) {
    this.escrowStatus = this.financials.escrowStatus;
  }
  next();
});

module.exports = mongoose.model('Booking', BookingSchema);
