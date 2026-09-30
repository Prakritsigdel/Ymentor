const express = require('express');
const mongoose = require('mongoose');
const Booking = require('../../models/Booking');
const User = require('../../models/User');
const Workspace = require('../../models/Workspace');
const ChatConversation = require('../../models/ChatConversation');
const { splitEscrow } = require('../../services/escrowService');

function createBookingsRouter({ verifyAuth }) {
  const router = express.Router();

  router.post('/bookings/monthly', verifyAuth, async (req, res) => {
    try {
      if (req.user.role !== 'mentee') return res.status(403).json({ error: 'Monthly mentorship plans are for mentees.' });
      const mentorId = String(req.body.mentorId || '');
      const mentor = await findUser(mentorId);
      const menteeId = String(req.user._id || req.user.id);
      const mentee = await findUser(menteeId);
      if (!mentor || mentor.role !== 'mentor' || mentor.status !== 'active') {
        return res.status(404).json({ error: 'An active mentor was not found.' });
      }
      const monthlyRate = Number(mentor.mentorProfile?.monthlyRate) || 0;
      if (!Number.isSafeInteger(monthlyRate)) {
        return res.status(400).json({ error: 'Monthly plan rates must be whole NPR amounts.' });
      }
      if (monthlyRate <= 0) return res.status(400).json({ error: 'This mentor has not configured a monthly plan.' });
      if (Number(mentor.mentorProfile?.maxMentees) > 0) {
        const activeCount = mongoose.connection.readyState === 1
          ? await Booking.countDocuments({ mentorId, planType: 'monthly', status: 'CONFIRMED', planEndsAt: { $gt: new Date() } })
          : (global.ymentorMemoryStore.bookings || []).filter((booking) => String(booking.mentorId) === mentorId && booking.planType === 'monthly' && booking.status === 'CONFIRMED' && new Date(booking.planEndsAt) > new Date()).length;
        if (activeCount >= Number(mentor.mentorProfile.maxMentees)) {
          return res.status(409).json({ error: 'This mentor has reached monthly mentee capacity.' });
        }
      }
      if (Number(mentee.walletBalance) < monthlyRate) return res.status(400).json({ error: 'Insufficient wallet balance for this monthly plan.' });
      const platformConfig = mongoose.connection.readyState === 1
        ? await require('../../models/PlatformConfig').findOne({ key: 'default' })
        : global.ymentorMemoryStore.config;
      const split = splitEscrow(monthlyRate);
      const fee = split.platformFee;
      const net = split.mentorPayout;
      const startsAt = new Date();
      const endsAt = new Date(startsAt.getTime() + 30 * 24 * 60 * 60 * 1000);
      if (mongoose.connection.readyState === 1) {
        await User.updateOne({ _id: menteeId }, { $inc: { walletBalance: -monthlyRate, 'wallet.balance': -monthlyRate } });
        await User.updateOne({ _id: mentorId }, { $inc: { 'wallet.pendingEscrow': net } });
        const booking = await Booking.create({
          menteeId, mentorId, durationMinutes: 0, planType: 'monthly', planStartsAt: startsAt, planEndsAt: endsAt,
          scheduledTime: startsAt, meetingUrl: mentor.meetingUrl, platformFee: fee, escrowStatus: 'held_in_escrow',
          currency: 'NPR',
          financials: { currency: 'NPR', grossAmount: monthlyRate, platformCommission20Percent: fee, mentorNetPayout80Percent: net, escrowStatus: 'held_in_escrow' },
          status: 'CONFIRMED',
        });
        const workspace = await Workspace.findOneAndUpdate(
          { mentorId, menteeId, planType: 'monthly' },
          { $setOnInsert: { mentorId, menteeId, planType: 'monthly', topic: `${mentor.name} & ${mentee.name} Monthly Mentorship` } },
          { upsert: true, new: true },
        );
        const conversation = await ChatConversation.create({ bookingId: booking._id, mentorId, menteeId });
        booking.conversationId = conversation._id;
        await booking.save();
        return res.status(201).json({ booking, workspace, conversationId: String(conversation._id), endsAt });
      }
      if (!mentee.wallet) mentee.wallet = { balance: Number(mentee.walletBalance) || 0, pendingEscrow: 0 };
      mentee.walletBalance -= monthlyRate;
      mentee.wallet.balance = mentee.walletBalance;
      if (!mentor.wallet) mentor.wallet = { balance: 0, pendingEscrow: 0 };
      mentor.wallet.pendingEscrow += net;
      const booking = {
        _id: `booking-${Date.now()}`, menteeId, mentorId, durationMinutes: 0, planType: 'monthly',
        planStartsAt: startsAt, planEndsAt: endsAt, scheduledTime: startsAt, meetingUrl: mentor.meetingUrl || '',
        platformFee: fee, escrowStatus: 'held_in_escrow', status: 'CONFIRMED',
        currency: 'NPR',
        financials: { currency: 'NPR', grossAmount: monthlyRate, platformCommission20Percent: fee, mentorNetPayout80Percent: net, escrowStatus: 'held_in_escrow' },
      };
      global.ymentorMemoryStore.bookings.push(booking);
      let workspace = global.ymentorMemoryStore.workspaces.find((item) =>
        String(item.mentorId) === mentorId &&
        String(item.menteeId) === menteeId &&
        item.planType === 'monthly',
      );
      if (!workspace) {
        workspace = {
          _id: `workspace-${Date.now()}`,
          mentorId,
          menteeId,
          planType: 'monthly',
          topic: `${mentor.name} & ${mentee.name} Monthly Mentorship`,
          createdAt: startsAt,
        };
        global.ymentorMemoryStore.workspaces.push(workspace);
      }
      const conversationId = `conversation-${Date.now()}`;
      booking.conversationId = conversationId;
      global.ymentorMemoryStore.conversations ||= [];
      global.ymentorMemoryStore.conversations.push({ _id: conversationId, bookingId: booking._id, mentorId, menteeId, lastMessageAt: startsAt });
      return res.status(201).json({ booking, workspace, conversationId, endsAt });
    } catch (error) {
      console.error('Monthly checkout error:', error);
      return res.status(500).json({ error: 'Unable to start monthly mentorship.' });
    }
  });

  async function findUser(id) {
    if (mongoose.connection.readyState === 1 && mongoose.Types.ObjectId.isValid(id)) return User.findById(id);
    return (global.ymentorMemoryStore?.users || []).find((user) => String(user._id || user.id) === id) || null;
  }
  return router;
}

module.exports = createBookingsRouter;
