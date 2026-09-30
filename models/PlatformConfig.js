const mongoose = require('mongoose');

const PlatformConfigSchema = new mongoose.Schema(
  {
    key: { type: String, required: true, unique: true, default: 'default' },
    flatFee: { type: Number, default: 0, min: 0, validate: Number.isInteger },
    percentageFee: { type: Number, default: 0 },
    broadcasts: { type: [mongoose.Schema.Types.Mixed], default: [] },
  },
  { timestamps: true }
);

module.exports = mongoose.model('PlatformConfig', PlatformConfigSchema);
