const mongoose = require('mongoose');

const TransactionSchema = new mongoose.Schema(
  {
    bookingId: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking' },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    type: {
      type: String,
      enum: ['DEBIT', 'PLATFORM_FEE', 'ESCROW_HOLD', 'PAYOUT', 'REFUND'],
      required: true,
    },
    amount: { type: Number, required: true, min: 0, validate: Number.isInteger },
    currency: { type: String, enum: ['NPR'], default: 'NPR' },
    status: { type: String, enum: ['PENDING', 'COMPLETED', 'REVERSED'], default: 'COMPLETED' },
  },
  { timestamps: true },
);

module.exports = mongoose.model('Transaction', TransactionSchema);
