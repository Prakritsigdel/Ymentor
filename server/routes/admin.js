const express = require('express');
const mongoose = require('mongoose');
const User = require('../../models/User');
const Booking = require('../../models/Booking');
const Dispute = require('../../models/Dispute');
const Review = require('../../models/Review');
const AuditLog = require('../../models/AuditLog');
const PlatformConfig = require('../../models/PlatformConfig');
const SearchEvent = require('../../models/SearchEvent');

function createAdminRouter({ verifyAuth, verifyRole, logAudit }) {
  const router = express.Router();

  router.get('/summary', verifyAuth, verifyRole(['admin']), async (_req, res) => {
    try {
      if (mongoose.connection.readyState !== 1) {
        const users = global.ymentorMemoryStore?.users || [];
        const bookings = global.ymentorMemoryStore?.bookings || [];
        const disputes = global.ymentorMemoryStore?.disputes || [];
        return res.json({
          pendingKyc: users.filter((user) => user.role === 'mentor' && user.status === 'pending_approval').length,
          gmv: bookings
            .reduce((sum, booking) => sum + Number(booking.financials?.grossAmount || 0), 0),
          activeEscrow: bookings
            .filter((booking) => booking.escrowStatus === 'held_in_escrow')
            .reduce((sum, booking) => sum + Number(booking.financials?.grossAmount || 0), 0),
          platformFees: bookings
            .reduce((sum, booking) => sum + Number(booking.platformFee || booking.financials?.platformCommission20Percent || 0), 0),
          releasedPayouts: bookings
            .filter((booking) => ['released', 'completed'].includes(booking.escrowStatus))
            .reduce((sum, booking) => sum + Number(booking.financials?.mentorNetPayout80Percent || 0), 0),
          openDisputes: disputes.filter((dispute) => dispute.status === 'open').length,
          commissionRevenue: bookings
            .filter((booking) => ['released', 'completed'].includes(booking.escrowStatus))
            .reduce((sum, booking) => sum + Number(booking.platformFee || booking.financials?.platformProtectionFee || 0), 0),
        });
      }
      const [pendingKyc, totals, openDisputes] = await Promise.all([
        User.countDocuments({
          role: 'mentor',
          $or: [{ status: 'pending_approval' }, { verificationStatus: 'PENDING_APPROVAL' }],
        }),
        Booking.aggregate([{
          $group: {
            _id: null,
            gmv: { $sum: '$financials.grossAmount' },
            platformFees: {
              $sum: {
                $max: [
                  '$platformFee',
                  '$financials.platformCommission20Percent',
                  '$financials.platformProtectionFee',
                ],
              },
            },
            activeEscrow: { $sum: { $cond: [{ $eq: ['$escrowStatus', 'held_in_escrow'] }, '$financials.grossAmount', 0] } },
            releasedPayouts: {
              $sum: {
                $cond: [
                  { $in: ['$escrowStatus', ['released', 'completed']] },
                  { $ifNull: ['$financials.mentorNetPayout80Percent', 0] },
                  0,
                ],
              },
            },
          },
        }]),
        Dispute.countDocuments({ status: 'open' }),
      ]);
      return res.json({
        pendingKyc,
        gmv: totals[0]?.gmv || 0,
        activeEscrow: totals[0]?.activeEscrow || 0,
        platformFees: totals[0]?.platformFees || 0,
        releasedPayouts: totals[0]?.releasedPayouts || 0,
        openDisputes,
        commissionRevenue: totals[0]?.platformFees || 0,
      });
    } catch (error) {
      console.error('Admin summary error:', error);
      return res.status(500).json({ error: 'Unable to load admin summary.' });
    }
  });

  router.get('/kyc', verifyAuth, verifyRole(['admin']), async (_req, res) => {
    try {
      if (mongoose.connection.readyState !== 1) {
        return res.json((global.ymentorMemoryStore?.users || [])
          .filter((user) => user.role === 'mentor' && (
            user.status === 'pending_approval' ||
            user.kycStatus === 'pending' ||
            user.isApproved === false ||
            ['PENDING_APPROVAL', 'REJECTED'].includes(user.verificationStatus)
          ))
          .map(kycView));
      }
      const users = await User.find({
        role: 'mentor',
        $or: [
          { status: 'pending_approval' },
          { kycStatus: 'pending' },
          { isApproved: false },
          { verificationStatus: { $in: ['PENDING_APPROVAL', 'REJECTED'] } },
        ],
      })
        .select('name email headline title bio status kycStatus isApproved qualifications mentorProfile verificationStatus verificationReason createdAt')
        .sort({ createdAt: 1 }).lean();
      return res.json(users.map(kycView));
    } catch (error) {
      console.error('KYC queue error:', error);
      return res.status(500).json({ error: 'Unable to load verification queue.' });
    }
  });

  router.put('/kyc/:userId', verifyAuth, verifyRole(['admin']), async (req, res) => {
    const decision = req.body.decision;
    if (!['APPROVED', 'REJECTED'].includes(decision)) return res.status(400).json({ error: 'Decision must be APPROVED or REJECTED.' });
    if (decision === 'REJECTED' && !String(req.body.reason || '').trim()) return res.status(400).json({ error: 'A rejection reason is required.' });
    try {
      const fields = {
        verificationStatus: decision,
        verificationReason: decision === 'REJECTED' ? String(req.body.reason).trim().slice(0, 1000) : '',
        status: decision === 'APPROVED' ? 'active' : 'pending_approval',
        isIdentityVerified: decision === 'APPROVED',
        isSkillVerified: decision === 'APPROVED',
      };
      const user = await updateUser(req.params.userId, fields);
      if (!user) return res.status(404).json({ error: 'Mentor not found.' });
      await logAudit({ actorId: req.user._id, actorName: req.user.name, actorRole: 'admin', action: `KYC_${decision}`, targetId: req.params.userId, details: { reason: fields.verificationReason } });
      return res.json({ user: kycView(user) });
    } catch (error) {
      console.error('KYC decision error:', error);
      return res.status(500).json({ error: 'Unable to update verification decision.' });
    }
  });

  router.get('/disputes', verifyAuth, verifyRole(['admin']), async (_req, res) => {
    try {
      if (mongoose.connection.readyState !== 1) return res.json(global.ymentorMemoryStore?.disputes || []);
      return res.json(await Dispute.find({ status: 'open' }).sort({ createdAt: 1 }).lean());
    } catch (error) {
      console.error('Dispute queue error:', error);
      return res.status(500).json({ error: 'Unable to load disputes.' });
    }
  });
  router.post('/disputes', verifyAuth, async (req, res) => {
    const reason = String(req.body.reason || '').trim();
    if (!reason) return res.status(400).json({ error: 'A dispute reason is required.' });
    try {
      const booking = mongoose.connection.readyState === 1
        ? await Booking.findById(req.body.bookingId)
        : (global.ymentorMemoryStore?.bookings || []).find((item) => String(item._id) === String(req.body.bookingId));
      if (!booking) return res.status(404).json({ error: 'Booking not found.' });
      const actor = String(req.user._id || req.user.id);
      if (String(booking.menteeId) !== actor && String(booking.mentorId) !== actor) return res.status(403).json({ error: 'Only session participants can report an issue.' });
      const disputeData = { bookingId: booking._id, reporterId: actor, reason };
      const dispute = mongoose.connection.readyState === 1
        ? await Dispute.create(disputeData)
        : { ...disputeData, _id: `dispute-${Date.now()}`, status: 'open', createdAt: new Date() };
      if (mongoose.connection.readyState !== 1) {
        global.ymentorMemoryStore.disputes ||= [];
        global.ymentorMemoryStore.disputes.push(dispute);
      }
      return res.status(201).json(dispute);
    } catch (error) {
      console.error('Dispute creation error:', error);
      return res.status(500).json({ error: 'Unable to report this issue.' });
    }
  });
  router.put('/disputes/:id/resolve', verifyAuth, verifyRole(['admin']), async (req, res) => {
    if (!['refund_mentee', 'release_mentor', 'split'].includes(req.body.resolution)) return res.status(400).json({ error: 'Select a valid dispute resolution.' });
    try {
      let dispute;
      if (mongoose.connection.readyState === 1) {
        dispute = await Dispute.findById(req.params.id);
        if (!dispute || dispute.status !== 'open') return res.status(404).json({ error: 'Open dispute not found.' });
        const booking = await Booking.findById(dispute.bookingId);
        if (!booking) return res.status(404).json({ error: 'Booking not found.' });
        const mentee = await User.findById(booking.menteeId);
        const mentor = await User.findById(booking.mentorId);
        const gross = Number(booking.financials.grossAmount);
        const net = Number(booking.financials.mentorNetPayout80Percent);
        const refund = req.body.resolution === 'split' ? Math.floor(gross / 2) : gross;
        if (req.body.resolution === 'refund_mentee' || req.body.resolution === 'split') {
          mentee.walletBalance += refund;
          if (mentee.wallet) mentee.wallet.balance = mentee.walletBalance;
          await mentee.save();
        }
        if (req.body.resolution === 'release_mentor' || req.body.resolution === 'split') {
          const payout = req.body.resolution === 'split' ? net - refund : net;
          mentor.walletBalance += payout;
          if (mentor.wallet) mentor.wallet.balance = mentor.walletBalance;
          await mentor.save();
        }
        booking.status = 'COMPLETED';
        booking.escrowStatus = req.body.resolution === 'refund_mentee' ? 'refunded' : 'released';
        booking.financials.escrowStatus = booking.escrowStatus;
        await booking.save();
        dispute.status = 'resolved';
        dispute.resolution = req.body.resolution;
        dispute.resolvedBy = req.user._id;
        dispute.resolvedAt = new Date();
        await dispute.save();
      } else {
        dispute = (global.ymentorMemoryStore?.disputes || []).find((item) => String(item._id) === req.params.id && item.status === 'open');
        if (!dispute) return res.status(404).json({ error: 'Open dispute not found.' });
        const booking = (global.ymentorMemoryStore.bookings || []).find((item) => String(item._id) === String(dispute.bookingId));
        if (!booking) return res.status(404).json({ error: 'Booking not found.' });
        const mentee = (global.ymentorMemoryStore.users || []).find((item) => String(item._id || item.id) === String(booking.menteeId));
        const mentor = (global.ymentorMemoryStore.users || []).find((item) => String(item._id || item.id) === String(booking.mentorId));
        const gross = Number(booking.financials?.grossAmount) || 0;
        const net = Number(booking.financials?.mentorNetPayout80Percent) || 0;
        const refund = req.body.resolution === 'split' ? Math.floor(gross / 2) : gross;
        if (mentee && ['refund_mentee', 'split'].includes(req.body.resolution)) {
          mentee.walletBalance = (mentee.walletBalance || 0) + refund;
          if (mentee.wallet) mentee.wallet.balance = mentee.walletBalance;
        }
        if (mentor && ['release_mentor', 'split'].includes(req.body.resolution)) {
          const payout = req.body.resolution === 'split' ? net - refund : net;
          mentor.walletBalance = (mentor.walletBalance || 0) + payout;
          if (mentor.wallet) mentor.wallet.balance = mentor.walletBalance;
        }
        booking.status = 'COMPLETED';
        booking.escrowStatus = req.body.resolution === 'refund_mentee' ? 'refunded' : 'released';
        if (booking.financials) booking.financials.escrowStatus = booking.escrowStatus;
        dispute.status = 'resolved';
        dispute.resolution = req.body.resolution;
        dispute.resolvedBy = req.user._id || req.user.id;
        dispute.resolvedAt = new Date();
      }
      await logAudit({ actorId: req.user._id, actorName: req.user.name, actorRole: 'admin', action: 'DISPUTE_RESOLVED', targetId: dispute._id, details: { resolution: req.body.resolution } });
      return res.json(dispute);
    } catch (error) {
      console.error('Dispute resolution error:', error);
      return res.status(500).json({ error: 'Unable to resolve this dispute.' });
    }
  });

  router.get('/reviews', verifyAuth, verifyRole(['admin']), async (_req, res) => {
    try {
      if (mongoose.connection.readyState !== 1) return res.json(global.ymentorMemoryStore?.reviews || []);
      return res.json(await Review.find({ status: { $in: ['pending', 'flagged'] } }).sort({ createdAt: 1 }).lean());
    } catch (error) {
      console.error('Review moderation queue error:', error);
      return res.status(500).json({ error: 'Unable to load review queue.' });
    }
  });
  router.put('/reviews/:id', verifyAuth, verifyRole(['admin']), async (req, res) => {
    if (!['pending', 'approved', 'removed'].includes(req.body.status)) return res.status(400).json({ error: 'Review status must be pending, approved, or removed.' });
    try {
      const review = mongoose.connection.readyState === 1
        ? await Review.findByIdAndUpdate(req.params.id, { status: req.body.status, text: req.body.text }, { new: true, runValidators: true })
        : (global.ymentorMemoryStore?.reviews || []).find((item) => String(item._id) === req.params.id);
      if (!review) return res.status(404).json({ error: 'Review not found.' });
      if (mongoose.connection.readyState !== 1) {
        review.status = req.body.status;
        if (req.body.text !== undefined) review.text = String(req.body.text);
      }
      if (mongoose.connection.readyState === 1) {
        const mentor = await User.findById(review.mentorId);
        if (mentor) {
          const approved = await Review.find({ mentorId: mentor._id, status: 'approved' }).select('rating').lean();
          mentor.ratingAvg = approved.length
            ? Number((approved.reduce((sum, item) => sum + item.rating, 0) / approved.length).toFixed(2))
            : 5;
          mentor.calculateLeaderboardScore();
          await mentor.save();
        }
      } else {
        const mentor = (global.ymentorMemoryStore?.users || []).find((item) => String(item._id || item.id) === String(review.mentorId));
        if (mentor) {
          const approved = (global.ymentorMemoryStore?.reviews || []).filter(
            (item) => String(item.mentorId) === String(review.mentorId) && item.status === 'approved',
          );
          mentor.ratingAvg = approved.length
            ? Number((approved.reduce((sum, item) => sum + Number(item.rating), 0) / approved.length).toFixed(2))
            : 5;
          const ratingPart = mentor.ratingAvg * 0.7;
          const sessionPart = Math.log10((mentor.totalSessions || 0) + 1) * 0.3;
          mentor.leaderboardScore = Number((ratingPart + sessionPart).toFixed(4));
        }
      }
      return res.json(review);
    } catch (error) {
      console.error('Review moderation error:', error);
      return res.status(500).json({ error: 'Unable to moderate review.' });
    }
  });

  router.get('/analytics', verifyAuth, verifyRole(['admin']), async (_req, res) => {
    try {
      if (mongoose.connection.readyState !== 1) {
        const users = global.ymentorMemoryStore?.users || [];
        const bookings = global.ymentorMemoryStore?.bookings || [];
        const frequency = new Map();
        for (const event of global.ymentorMemoryStore?.searchEvents || []) {
          frequency.set(event.term, (frequency.get(event.term) || 0) + 1);
        }
        const topSkills = [...frequency.entries()]
          .sort((left, right) => right[1] - left[1])
          .slice(0, 10)
          .map(([term, count]) => ({ _id: term, count }));
        return res.json({
          users: users.length,
          registrationsLast30Days: users.length,
          activeBookings: bookings.filter((item) => item.status === 'CONFIRMED').length,
          topSkills,
        });
      }
      const [users, registrationsLast30Days, activeBookings, topSkills] = await Promise.all([
        User.countDocuments({}),
        User.countDocuments({ createdAt: { $gte: new Date(Date.now() - 30 * 86400000) } }),
        Booking.countDocuments({ status: 'CONFIRMED' }),
        SearchEvent.aggregate([
          { $match: { createdAt: { $gte: new Date(Date.now() - 30 * 86400000) } } },
          { $group: { _id: '$term', count: { $sum: 1 } } },
          { $sort: { count: -1 } },
          { $limit: 10 },
        ]),
      ]);
      const dau = await AuditLog.distinct('actorId', { action: 'USER_LOGIN', timestamp: { $gte: new Date(Date.now() - 86400000) } });
      return res.json({ users, registrationsLast30Days, activeBookings, dau: dau.length, topSkills });
    } catch (error) {
      console.error('Platform analytics error:', error);
      return res.status(500).json({ error: 'Unable to load analytics.' });
    }
  });

  router.get('/config', verifyAuth, verifyRole(['admin']), async (_req, res) => {
    try {
      const config = mongoose.connection.readyState === 1
        ? await PlatformConfig.findOneAndUpdate({ key: 'default' }, { $setOnInsert: { key: 'default' } }, { upsert: true, new: true })
        : (global.ymentorMemoryStore.config ||= { broadcasts: [] });
      return res.json(config);
    } catch (error) {
      console.error('Platform config read error:', error);
      return res.status(500).json({ error: 'Unable to load platform configuration.' });
    }
  });
  router.put('/config', verifyAuth, verifyRole(['admin']), async (req, res) => {
    const flatFee = 0;
    const percentageFee = 20;
    try {
      const config = mongoose.connection.readyState === 1
        ? await PlatformConfig.findOneAndUpdate({ key: 'default' }, { flatFee, percentageFee }, { upsert: true, new: true, runValidators: true })
        : Object.assign(global.ymentorMemoryStore.config ||= { broadcasts: [] }, { flatFee, percentageFee });
      return res.json(config);
    } catch (error) {
      console.error('Platform config update error:', error);
      return res.status(500).json({ error: 'Unable to update platform configuration.' });
    }
  });
  router.post('/broadcasts', verifyAuth, verifyRole(['admin']), async (req, res) => {
    const message = String(req.body.message || '').trim();
    if (!message) return res.status(400).json({ error: 'Broadcast message cannot be empty.' });
    try {
      const broadcast = { message: message.slice(0, 2000), segment: String(req.body.segment || 'all'), createdAt: new Date(), createdBy: String(req.user._id || req.user.id) };
      if (mongoose.connection.readyState === 1) {
        const config = await PlatformConfig.findOneAndUpdate({ key: 'default' }, { $push: { broadcasts: broadcast } }, { upsert: true, new: true });
        return res.status(201).json(config.broadcasts[config.broadcasts.length - 1]);
      }
      const config = global.ymentorMemoryStore.config ||= { broadcasts: [] };
      config.broadcasts.push(broadcast);
      return res.status(201).json(broadcast);
    } catch (error) {
      console.error('Broadcast creation error:', error);
      return res.status(500).json({ error: 'Unable to save broadcast.' });
    }
  });

  async function updateUser(id, fields) {
    if (mongoose.connection.readyState === 1 && mongoose.Types.ObjectId.isValid(id)) return User.findByIdAndUpdate(id, { $set: fields }, { new: true, runValidators: true });
    const user = (global.ymentorMemoryStore?.users || []).find((item) => String(item._id || item.id) === id);
    if (user) Object.assign(user, fields);
    return user;
  }
  function kycView(user) {
    return {
      _id: user._id,
      name: user.name,
      email: user.email,
      headline: user.headline,
      title: user.title,
      bio: user.bio,
      status: user.status,
      kycStatus: user.kycStatus,
      isApproved: user.isApproved,
      qualifications: user.qualifications || {},
      mentorProfile: user.mentorProfile || {},
      verificationStatus: user.verificationStatus || 'PENDING_APPROVAL',
      verificationReason: user.verificationReason || '',
      createdAt: user.createdAt,
    };
  }
  return router;
}

module.exports = createAdminRouter;
