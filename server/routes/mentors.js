const express = require('express');
const mongoose = require('mongoose');
const User = require('../../models/User');

function createMentorsRouter({ verifyAuth }) {
  const router = express.Router();

  router.patch('/:id/monthly-plan', verifyAuth, async (req, res) => {
    try {
      const userId = String(req.user._id || req.user.id);
      if (req.user.role !== 'mentor' || userId !== req.params.id) {
        return res.status(403).json({ error: 'Mentors may update only their own plan.' });
      }
      const monthlyRate = Number(req.body.monthlyRate);
      const maxMentees = Number(req.body.maxMentees);
      if (!Number.isSafeInteger(monthlyRate) || monthlyRate < 0 || !Number.isInteger(maxMentees) || maxMentees < 0 || maxMentees > 100) {
        return res.status(400).json({ error: 'Monthly rate and capacity are invalid.' });
      }
      let user;
      if (mongoose.connection.readyState === 1) {
        user = await User.findByIdAndUpdate(
          userId,
          { $set: { 'mentorProfile.monthlyRate': monthlyRate, 'mentorProfile.maxMentees': maxMentees } },
          { new: true, runValidators: true },
        );
      } else {
        user = (global.ymentorMemoryStore?.users || []).find((item) => String(item._id || item.id) === userId);
        if (user) {
          user.mentorProfile ||= {};
          user.mentorProfile.monthlyRate = monthlyRate;
          user.mentorProfile.maxMentees = maxMentees;
        }
      }
      if (!user) return res.status(404).json({ error: 'Mentor not found.' });
      return res.json({ user });
    } catch (error) {
      console.error('Monthly plan update error:', error);
      return res.status(400).json({ error: 'Unable to update monthly plan.' });
    }
  });
  return router;
}

module.exports = createMentorsRouter;
