/**
 * Audit Logging Helper
 */

const AuditLog = require('../models/AuditLog');

const memoryAuditLogs = [];

async function logAudit({ actorId, actorName, actorRole, action, targetId, details = {} }) {
  const timestamp = new Date();
  const entry = {
    actorId: actorId ? actorId.toString() : 'system',
    actorName: actorName || 'System',
    actorRole: actorRole || 'system',
    action,
    targetId: targetId ? targetId.toString() : null,
    details,
    timestamp,
  };

  try {
    const isMongoConnected = require('mongoose').connection.readyState === 1;
    if (isMongoConnected) {
      await AuditLog.create(entry);
    }
  } catch (err) {
    console.error('Failed to write AuditLog to MongoDB:', err.message);
  }

  // Always keep in memory for instant queries and offline resilience
  memoryAuditLogs.unshift({
    _id: 'audit-' + Date.now() + '-' + Math.round(Math.random() * 1000),
    ...entry,
  });

  if (memoryAuditLogs.length > 500) {
    memoryAuditLogs.pop();
  }

  console.log(`[AUDIT] [${action}] by ${actorName || actorId || 'System'} (${actorRole || 'system'}):`, details);
  return entry;
}

function getMemoryAuditLogs() {
  return memoryAuditLogs;
}

module.exports = {
  logAudit,
  getMemoryAuditLogs,
  memoryAuditLogs,
};
