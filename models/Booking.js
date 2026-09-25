const mongoose = require('mongoose');

const FinancialsSchema = new mongoose.Schema(
  {
    grossAmount: { type: Number, required: true },
    platformCommission20Percent: { type: Number, required: true },
    mentorNetPayout80Percent: { type: Number, required: true },
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
    durationMinutes: { type: Number, enum: [30, 60, 120], required: true },
    scheduledTime: { type: Date, required: true },
    meetingUrl: { type: String, default: 'https://meet.google.com/abc-defg-hij' },
    platformFee: { type: Number, default: 4.0 },
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
