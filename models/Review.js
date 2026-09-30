const mongoose = require('mongoose');

const ReviewSchema = new mongoose.Schema(
  {
    bookingId: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true, unique: true },
    mentorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    menteeId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    rating: { type: Number, min: 1, max: 5, required: true },
    text: { type: String, trim: true, default: '' },
    status: { type: String, enum: ['pending', 'approved', 'flagged', 'removed'], default: 'pending' },
    moderationReason: { type: String, default: '' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Review', ReviewSchema);
