const express = require('express');
const { RtcTokenBuilder, RtcRole } = require('agora-token');

function createAgoraRouter() {
  const router = express.Router();

  const handleToken = (req, res) => {
    try {
      const appId = process.env.AGORA_APP_ID;
      const certificate = process.env.AGORA_APP_CERTIFICATE;
      if (!appId) {
        return res.status(503).json({ error: 'Agora is not configured on this server.' });
      }

      const rawChannel = (req.query.channelName || req.body.channelName || '').trim();
      const channelName = rawChannel.replace(/[^a-zA-Z0-9_]/g, '');
      if (!channelName) {
        return res.status(400).json({ error: 'channelName is required' });
      }

      let token = '';
      if (certificate) {
        const uid = 0;
        const role = RtcRole.PUBLISHER;
        const expirationInSeconds = 86400; // 24 hours
        const privilegeExpiredTs = Math.floor(Date.now() / 1000) + expirationInSeconds;

        token = RtcTokenBuilder.buildTokenWithUid(
          appId,
          certificate,
          channelName,
          uid,
          role,
          privilegeExpiredTs,
        );
      }

      console.log(`[Agora Router] Token generated for channel="${channelName}" uid=0`);
      return res.json({ token, channelName, appId, uid: 0 });
    } catch (err) {
      console.error('[Agora Router Error]:', err);
      return res.status(500).json({ error: 'Failed to generate token', details: err.message });
    }
  };

  router.get('/token', handleToken);
  router.post('/token', handleToken);

  return router;
}

module.exports = createAgoraRouter;
