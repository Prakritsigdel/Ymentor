const { WebSocketServer, WebSocket } = require('ws');
const url = require('url');

class SocketService {
  constructor() {
    this.wss = null;
    // Map of channelId (string) -> Set of WebSocket clients
    this.channels = new Map();
  }

  init(server) {
    if (this.wss) return;

    this.wss = new WebSocketServer({ noServer: true });

    server.on('upgrade', (request, socket, head) => {
      try {
        const parsed = url.parse(request.url, true);
        const pathname = parsed.pathname;

        if (pathname === '/ws/chat' || pathname === '/ws' || pathname === '/api/chat/ws') {
          this.wss.handleUpgrade(request, socket, head, (ws) => {
            this.wss.emit('connection', ws, request);
          });
        }
      } catch (err) {
        console.error('⚠️ [WS UPGRADE ERROR]', err);
        socket.destroy();
      }
    });

    this.wss.on('connection', (ws, request) => {
      try {
        const parsed = url.parse(request.url, true);
        const initialChannel =
          parsed.query.channel ||
          parsed.query.workspaceId ||
          parsed.query.conversationId;

        ws.subscriptions = new Set();

        if (initialChannel) {
          this.joinChannel(ws, String(initialChannel));
        }

        ws.on('message', (raw) => {
          try {
            const payload = JSON.parse(raw.toString());
            if (payload.type === 'join' || payload.action === 'join') {
              const ch = payload.channel || payload.workspaceId || payload.conversationId;
              if (ch) this.joinChannel(ws, String(ch));
            } else if (payload.type === 'leave' || payload.action === 'leave') {
              const ch = payload.channel || payload.workspaceId || payload.conversationId;
              if (ch) this.leaveChannel(ws, String(ch));
            } else if (payload.type === 'ping') {
              ws.send(JSON.stringify({ type: 'pong', timestamp: Date.now() }));
            }
          } catch (_) {}
        });

        ws.on('close', () => {
          this.cleanUpClient(ws);
        });

        ws.on('error', (err) => {
          console.error('⚠️ [WS CLIENT ERROR]', err.message);
          this.cleanUpClient(ws);
        });

        // Send connection acknowledgement
        try {
          ws.send(JSON.stringify({
            type: 'connected',
            message: 'Real-time chat WebSocket connected',
            channel: initialChannel || null,
          }));
        } catch (_) {}
      } catch (err) {
        console.error('⚠️ [WS CONNECTION ERROR]', err);
      }
    });

    console.log('⚡ [SOCKET SERVICE] Real-time WebSocket server initialized on /ws/chat');
  }

  joinChannel(ws, channel) {
    if (!channel) return;
    const ch = String(channel).trim();
    if (!ch) return;
    if (!this.channels.has(ch)) {
      this.channels.set(ch, new Set());
    }
    this.channels.get(ch).add(ws);
    if (!ws.subscriptions) ws.subscriptions = new Set();
    ws.subscriptions.add(ch);
  }

  leaveChannel(ws, channel) {
    if (!channel) return;
    const ch = String(channel).trim();
    if (this.channels.has(ch)) {
      this.channels.get(ch).delete(ws);
      if (this.channels.get(ch).size === 0) {
        this.channels.delete(ch);
      }
    }
    if (ws.subscriptions) {
      ws.subscriptions.delete(ch);
    }
  }

  cleanUpClient(ws) {
    if (ws.subscriptions) {
      for (const ch of ws.subscriptions) {
        if (this.channels.has(ch)) {
          this.channels.get(ch).delete(ws);
          if (this.channels.get(ch).size === 0) {
            this.channels.delete(ch);
          }
        }
      }
      ws.subscriptions.clear();
    }
  }

  broadcastToChannels(channels, payload) {
    if (!channels) return;
    const channelList = Array.isArray(channels) ? channels : [channels];
    const dataStr = JSON.stringify(payload);
    const deliveredClients = new Set();

    for (const rawCh of channelList) {
      if (!rawCh) continue;
      const ch = String(rawCh).trim();
      const clients = this.channels.get(ch);
      if (clients) {
        for (const client of clients) {
          if (!deliveredClients.has(client) && client.readyState === WebSocket.OPEN) {
            try {
              client.send(dataStr);
              deliveredClients.add(client);
            } catch (err) {
              console.error('Failed to send to WS client:', err.message);
            }
          }
        }
      }
    }

    if (deliveredClients.size > 0) {
      console.log(`📡 [WS BROADCAST] Sent to ${deliveredClients.size} client(s) across channels:`, channelList);
    }
  }
}

const socketService = new SocketService();
module.exports = socketService;
