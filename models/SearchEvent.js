const mongoose = require('mongoose');

const SearchEventSchema = new mongoose.Schema(
  {
    term: { type: String, required: true, trim: true, maxlength: 100, index: true },
  },
  { timestamps: true }
);
SearchEventSchema.index({ createdAt: 1 }, { expireAfterSeconds: 90 * 24 * 60 * 60 });

module.exports = mongoose.model('SearchEvent', SearchEventSchema);
