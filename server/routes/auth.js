const express = require('express');
const multer = require('multer');
const path = require('path');
const User = require('../../models/User');

function createAuthRouter({ verifyAuth, uploadsDir }) {
  const router = express.Router();
  const storage = multer.diskStorage({
    destination: (_req, _file, callback) => callback(null, uploadsDir),
    filename: (_req, file, callback) => {
      const safeName = file.originalname.replace(/[^a-zA-Z0-9.-]/g, '_');
      callback(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}-${safeName}`);
    },
  });
  const verificationUpload = multer({
    storage,
    limits: { fileSize: 10 * 1024 * 1024 },
    fileFilter: (_req, file, callback) => {
      const accepted = /^application\/pdf$|^image\/(jpeg|png|webp)$/.test(file.mimetype);
      callback(accepted ? null : new Error('Upload a PDF, JPEG, PNG, or WebP file.'), accepted);
    },
  }).fields([
    { name: 'avatar', maxCount: 1 },
    { name: 'qualificationProof', maxCount: 1 },
    { name: 'identityFront', maxCount: 1 },
    { name: 'identityBack', maxCount: 1 },
  ]);

  router.post('/auth/onboard/mentor', verifyAuth, verificationUpload, async (req, res) => {
    try {
      const body = req.body;
      const dateOfBirth = new Date(body.dateOfBirth);
      const age = (Date.now() - dateOfBirth.getTime()) / (365.2425 * 24 * 60 * 60 * 1000);
      if (!Number.isFinite(dateOfBirth.getTime()) || age < 18 || !body.legalName || !body.headline) {
        return res.status(400).json({ error: 'A legal name, headline, and valid date of birth for an adult are required.' });
      }
      const files = req.files || {};
      if (!files.qualificationProof?.[0] || !files.identityFront?.[0] || !files.identityBack?.[0]) {
        return res.status(400).json({ error: 'Upload qualification proof and both sides of a government identity document.' });
      }
      const fileUrl = (key) => files[key]?.[0] ? `/uploads/${path.basename(files[key][0].filename)}` : '';
      const hourlyRate = parseNprAmount(body.hourlyRate, 2000);
      const monthlyRate = parseNprAmount(body.monthlyRate, 8000);
      if (!Number.isSafeInteger(hourlyRate) || hourlyRate <= 0 ||
          !Number.isSafeInteger(monthlyRate) || monthlyRate <= 0) {
        return res.status(400).json({ error: 'Hourly and monthly rates must be whole NPR amounts.' });
      }
      const maxMentees = parseWholeNumber(body.maxMentees, 0);
      const weeklyAvailableHours = parseWholeNumber(body.weeklyAvailableHours, 0);
      const userId = req.user._id || req.user.id;
      const fields = {
        name: body.legalName.trim(),
        headline: body.headline.trim(),
        bio: String(body.bio || '').trim(),
        avatarUrl: fileUrl('avatar') || String(body.avatarUrl || ''),
        currency: 'NPR',
        hourlyRate,
        pricing: { hourly: hourlyRate, monthly: monthlyRate },
        title: String(body.currentRole || '').trim(),
        verificationStatus: 'PENDING_APPROVAL',
        verificationReason: '',
        status: 'pending_approval',
        isOnboarded: true,
        mentorProfile: {
          dateOfBirth,
          location: body.location || '',
          timezone: body.timezone || '',
          primaryDomain: body.primaryDomain || '',
          subSkills: parseList(body.subSkills),
          yearsExperience: Number(body.yearsExperience) || 0,
          currentOrganization: body.currentOrganization || '',
          monthlyRate,
          maxMentees,
          weeklyAvailableHours,
          fluentLanguages: parseList(body.fluentLanguages),
          governmentIdType: body.governmentIdType || '',
          portfolioUrl: body.portfolioUrl || '',
          qualificationDocUrl: fileUrl('qualificationProof'),
          identityDocUrl: [fileUrl('identityFront'), fileUrl('identityBack')].filter(Boolean).join('|'),
        },
        qualifications: {
          degree: body.highestDegree || '',
          faculty: body.primaryDomain || '',
          skills: parseList(body.subSkills),
          githubUrl: body.portfolioUrl || '',
          linkedinUrl: body.linkedinUrl || '',
        },
      };

      let user;
      if (req.user._id && mongooseId(req.user._id)) {
        user = await User.findByIdAndUpdate(userId, { $set: fields }, { new: true, runValidators: true });
      }
      if (!user && global.ymentorMemoryStore) {
        user = global.ymentorMemoryStore.users.find((item) => String(item._id || item.id) === String(userId));
        if (user) Object.assign(user, fields);
      }
      if (!user) return res.status(404).json({ error: 'Account not found.' });
      return res.status(201).json({ message: 'Mentor application submitted for verification.', user });
    } catch (error) {
      console.error('Mentor onboarding error:', error);
      return res.status(400).json({ error: error.message });
    }
  });

  router.put('/users/onboarding/mentee', verifyAuth, async (req, res) => {
    try {
      if (req.user.role !== 'mentee') return res.status(403).json({ error: 'Only mentees can submit this onboarding form.' });
      const profile = {
        academicStatus: String(req.body.academicStatus || '').trim(),
        fieldOfInterest: String(req.body.fieldOfInterest || '').trim(),
        primaryGoal: String(req.body.primaryGoal || '').trim(),
        targetSkills: parseList(req.body.targetSkills),
        competencyLevel: String(req.body.competencyLevel || 'beginner').toLowerCase(),
        preferredMode: String(req.body.preferredMode || 'not_sure').toLowerCase(),
        mentorStyle: String(req.body.mentorStyle || '').trim(),
        targetBudget: Number(req.body.targetBudget) || 0,
        weeklyCommitmentHours: Number(req.body.weeklyCommitmentHours) || 0,
      };
      const userId = req.user._id || req.user.id;
      let user;
      if (req.user._id && mongooseId(req.user._id)) {
        user = await User.findByIdAndUpdate(userId, {
          $set: { menteeProfile: profile, isOnboarded: true },
        }, { new: true, runValidators: true });
      }
      if (!user && global.ymentorMemoryStore) {
        user = global.ymentorMemoryStore.users.find((item) => String(item._id || item.id) === String(userId));
        if (user) Object.assign(user, { menteeProfile: profile, isOnboarded: true });
      }
      if (!user) return res.status(404).json({ error: 'Account not found.' });
      return res.json({ message: 'Mentee onboarding completed.', user });
    } catch (error) {
      console.error('Mentee onboarding error:', error);
      return res.status(400).json({ error: error.message });
    }
  });

  return router;
}

function parseList(value) {
  if (Array.isArray(value)) return value.map(String).map((item) => item.trim()).filter(Boolean);
  return String(value || '').split(',').map((item) => item.trim()).filter(Boolean);
}

function parseNprAmount(value, fallback) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.round(value);
  }
  const text = String(value ?? '').replace(/,/g, '');
  const numbers = text.match(/\d+(?:\.\d+)?/g);
  if (!numbers?.length) return fallback;
  const parsed = numbers.map(Number).filter(Number.isFinite);
  if (!parsed.length) return fallback;
  return Math.round(parsed.length > 1 ? (parsed[0] + parsed[1]) / 2 : parsed[0]);
}

function parseWholeNumber(value, fallback) {
  const parsed = Number.parseInt(String(value ?? ''), 10);
  return Number.isSafeInteger(parsed) && parsed >= 0 ? parsed : fallback;
}

function mongooseId(value) {
  return /^[a-f\d]{24}$/i.test(String(value));
}

module.exports = createAuthRouter;
