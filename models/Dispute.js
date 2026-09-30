const mongoose = require('mongoose');

const DisputeSchema = new mongoose.Schema(
  {
    bookingId: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking' },
    workspaceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Workspace' },
    reporterId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    reason: { type: String, required: true, trim: true },
    status: { type: String, enum: ['open', 'resolved'], default: 'open' },
    resolution: { type: String, enum: ['refund_mentee', 'release_mentor', 'split'] },
    resolvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    resolvedAt: { type: Date },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Dispute', DisputeSchema);
