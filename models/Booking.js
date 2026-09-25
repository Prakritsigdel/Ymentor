const mongoose = require('mongoose');

const FinancialsSchema = new mongoose.Schema(
  {
    grossAmount: { type: Number, required: true },
    platformCommission20Percent: { type: Number, required: true },
    mentorNetPayout80Percent: { type: Number, required: true },
    escrowStatus: { type: String, enum: ['HELD', 'RELEASED', 'REFUNDED'], default: 'HELD' },
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
    financials: { type: FinancialsSchema, required: true },
    status: { type: String, enum: ['CONFIRMED', 'COMPLETED', 'CANCELLED'], default: 'CONFIRMED' },
    ratingGiven: { type: Number },
    reviewNote: { type: String },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Booking', BookingSchema);
