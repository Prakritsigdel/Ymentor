/**
 * Authentication and Role-Based Access Control (RBAC) Middleware
 */

const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const User = require('../models/User');

const JWT_SECRET = process.env.JWT_SECRET || 'ymentor-secret-key-2026';

async function verifyAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Authorization token required in Bearer format.' });
    }

    const token = authHeader.split(' ')[1];
    let decoded;

    // Support both real JWT and fallback demo tokens
    if (token.startsWith('jwt-demo-token-')) {
      const demoId = token.replace('jwt-demo-token-', '');
      decoded = { id: demoId };
    } else {
      try {
        decoded = jwt.verify(token, JWT_SECRET);
      } catch (err) {
        return res.status(401).json({ error: 'Invalid or expired session token.' });
      }
    }

    let user = null;
    if (mongoose.connection.readyState === 1 && mongoose.Types.ObjectId.isValid(decoded.id)) {
      try {
        user = await User.findById(decoded.id);
      } catch (_) {
        // Non-fatal — fall through to memory store
      }
    }

    // Check memory store if MongoDB is offline or not found
    if (!user && global.ymentorMemoryStore && global.ymentorMemoryStore.users) {
      user = global.ymentorMemoryStore.users.find(
        (u) => (u._id && u._id.toString() === decoded.id.toString()) || u.id === decoded.id
      );
    }

    if (!user) {
      return res.status(401).json({ error: 'User associated with this token was not found.' });
    }

    // Check if user is suspended
    if (user.status === 'suspended') {
      return res.status(403).json({ error: 'Your account has been suspended. Please contact administrator.' });
    }

    req.user = user;
    next();
  } catch (error) {
    console.error('verifyAuth error:', error);
    return res.status(401).json({ error: 'Authentication failed.' });
  }
}

function verifyRole(allowedRoles = []) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'User is not authenticated.' });
    }

    const userRole = req.user.role;
    if (!allowedRoles.includes(userRole)) {
      return res.status(403).json({
        error: `Access denied. Requires one of roles: [${allowedRoles.join(', ')}], but current role is '${userRole}'.`,
      });
    }

    next();
  };
}

module.exports = {
  verifyAuth,
  verifyRole,
  JWT_SECRET,
};
