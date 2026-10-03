const express = require('express');
const multer = require('multer');
const path = require('path');
const mongoose = require('mongoose');
const Booking = require('../../models/Booking');
const Workspace = require('../../models/Workspace');
const ChatConversation = require('../../models/ChatConversation');
const ChatMessage = require('../../models/ChatMessage');

function createChatRouter({ verifyAuth, uploadsDir }) {
  const router = express.Router();
  const storage = multer.diskStorage({
    destination: (_req, _file, callback) => callback(null, uploadsDir),
    filename: (_req, file, callback) => {
      const extension = path.extname(file.originalname).toLowerCase() || '.pdf';
      callback(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}${extension}`);
    },
  });
  const upload = multer({
    storage,
    limits: { fileSize: 25 * 1024 * 1024 },
    fileFilter: (_req, file, callback) => {
      const isPdf = file.mimetype === 'application/pdf' || file.originalname.toLowerCase().endsWith('.pdf');
      callback(isPdf ? null : new Error('Chat attachments must be PDF files.'), isPdf);
    },
  });

  router.get('/:conversationId', verifyAuth, async (req, res) => {
    try {
      const conversation = await findConversation(req.params.conversationId);
      if (!conversation || !isParticipant(conversation, req.user)) {
        return res.status(404).json({ error: 'Conversation not found.' });
      }
      const booking = await findBooking(conversation.bookingId);
      if (!booking || !['CONFIRMED', 'ACTIVE'].includes(booking.status)) {
        return res.status(403).json({ error: 'Chat is available only during an active mentorship.' });
      }
      if (booking.planType === 'monthly' &&
          (!booking.planEndsAt || new Date(booking.planEndsAt) <= new Date())) {
        return res.status(403).json({ error: 'This monthly mentorship has ended.' });
      }
      const after = req.query.after ? new Date(req.query.after) : null;
      if (mongoose.connection.readyState === 1) {
        const query = { conversationId: conversation._id };
        if (after && Number.isFinite(after.getTime())) query.createdAt = { $gt: after };
        const messages = await ChatMessage.find(query).sort({ createdAt: 1 }).limit(200);
        return res.json(messages);
      }
      const messages = (global.ymentorMemoryStore.messages || []).filter((message) =>
        String(message.conversationId) === String(conversation._id) &&
        (!after || new Date(message.createdAt) > after),
      );
      return res.json(messages);
    } catch (error) {
      console.error('Chat history error:', error);
      return res.status(500).json({ error: 'Unable to load conversation.' });
    }
  });

  router.post('/send', verifyAuth, upload.single('pdf'), async (req, res) => {
    try {
      const {
        conversationId,
        workspaceId,
        text = '',
        sessionType,
        messageType = 'USER',
        preset,
      } = req.body;
      const requestedConversationId = conversationId || workspaceId;
      if (!requestedConversationId || (!String(text).trim() && !req.file)) {
        return res.status(400).json({ error: 'A message or PDF attachment is required.' });
      }
      const conversation = await findConversation(requestedConversationId);
      if (!conversation || !isParticipant(conversation, req.user)) {
        return res.status(404).json({ error: 'Conversation not found.' });
      }
      const booking = await findBooking(conversation.bookingId);
      if (!booking || !['CONFIRMED', 'ACTIVE'].includes(booking.status)) {
        return res.status(403).json({ error: 'Chat is available only during a confirmed mentorship.' });
      }
      if (booking.planType === 'monthly' &&
          (!booking.planEndsAt || new Date(booking.planEndsAt) <= new Date())) {
        return res.status(403).json({ error: 'This monthly mentorship has ended.' });
      }
      const messageData = {
        conversationId: conversation._id,
        senderId: req.user._id || req.user.id,
        text: String(text).trim(),
        attachmentUrl: req.file ? `/uploads/${path.basename(req.file.path)}` : '',
        createdAt: new Date(),
      };
      let message;
      if (mongoose.connection.readyState === 1) {
        message = await ChatMessage.create(messageData);
        await ChatConversation.updateOne({ _id: conversation._id }, { $set: { lastMessageAt: message.createdAt } });
      } else {
        message = { ...messageData, _id: `message-${Date.now()}` };
        global.ymentorMemoryStore.messages ||= [];
        global.ymentorMemoryStore.messages.push(message);
        conversation.lastMessageAt = message.createdAt;
      }
      return res.status(201).json(message);
    } catch (error) {
      console.error('Chat send error:', error);
      return res.status(400).json({ error: error.message || 'Unable to send message.' });
    }
  });

  async function findConversation(id) {
    if (mongoose.connection.readyState === 1) {
      if (mongoose.Types.ObjectId.isValid(id)) {
        const direct = await ChatConversation.findById(id);
        if (direct) return direct;
        const workspace = await Workspace.findById(id).lean();
        if (workspace) {
          const booking = await Booking.findOne({
            mentorId: workspace.mentorId,
            menteeId: workspace.menteeId,
            planType: workspace.planType,
          }).sort({ createdAt: -1 });
          return getOrCreateConversation(booking);
        }
        const booking = await Booking.findById(id);
        if (booking) {
          return getOrCreateConversation(booking);
        }
      }
      return null;
    }
    const direct = (global.ymentorMemoryStore?.conversations || [])
        .find((item) => String(item._id) === id);
    if (direct) return direct;
    const workspace = (global.ymentorMemoryStore?.workspaces || [])
        .find((item) => String(item._id) === id);
    if (workspace) {
      const booking = (global.ymentorMemoryStore?.bookings || [])
          .filter((item) =>
            String(item.mentorId) === String(workspace.mentorId) &&
            String(item.menteeId) === String(workspace.menteeId) &&
            item.planType === workspace.planType)
          .sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0))[0];
      return getOrCreateConversation(booking);
    }
    const booking = (global.ymentorMemoryStore?.bookings || [])
        .find((item) => String(item._id) === id);
    return getOrCreateConversation(booking);
  }

  async function getOrCreateConversation(booking) {
    if (!booking) return null;
    if (booking.conversationId) {
      if (mongoose.connection.readyState === 1) {
        return ChatConversation.findById(booking.conversationId);
      }
      return (global.ymentorMemoryStore?.conversations || []).find(
          (item) => String(item._id) === String(booking.conversationId));
    }
    if (mongoose.connection.readyState === 1) {
      const conversation = await ChatConversation.create({
        bookingId: booking._id,
        mentorId: booking.mentorId,
        menteeId: booking.menteeId,
      });
      booking.conversationId = conversation._id;
      await booking.save();
      return conversation;
    }
    const conversation = {
      _id: `conversation-${Date.now()}`,
      bookingId: booking._id,
      mentorId: booking.mentorId,
      menteeId: booking.menteeId,
      lastMessageAt: new Date(),
    };
    booking.conversationId = conversation._id;
    global.ymentorMemoryStore.conversations ||= [];
    global.ymentorMemoryStore.conversations.push(conversation);
    return conversation;
  }

  async function findBooking(id) {
    if (mongoose.connection.readyState === 1 && mongoose.Types.ObjectId.isValid(id)) return Booking.findById(id);
    return (global.ymentorMemoryStore?.bookings || []).find((item) => String(item._id) === String(id)) || null;
  }

  function isParticipant(conversation, user) {
    const id = String(user._id || user.id);
    return String(conversation.mentorId) === id || String(conversation.menteeId) === id;
  }

  return router;
}

module.exports = createChatRouter;
