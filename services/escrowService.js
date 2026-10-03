function splitEscrow(grossAmount) {
  const gross = Number(grossAmount);
  if (!Number.isSafeInteger(gross) || gross < 0) {
    throw new Error('Escrow amounts must be non-negative integer NPR values.');
  }
  const mentorPayout = Math.round(gross * 0.8);
  return {
    currency: 'NPR',
    grossAmount: gross,
    platformFee: Math.round(gross * 0.2),
    mentorPayout,
  };
}

module.exports = { splitEscrow };
