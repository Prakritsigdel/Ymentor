const mongoose = require('mongoose');

const ChatConversationSchema = new mongoose.Schema(
  {
    bookingId: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true, unique: true },
    mentorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    menteeId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    lastMessageAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

module.exports = mongoose.model('ChatConversation', ChatConversationSchema);
