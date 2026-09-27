# YMentor

YMentor connects learners with experienced mentors through one-to-one sessions,
shared workspaces, document exchange, and escrow-based payments.

## Requirements

- Flutter SDK
- Node.js
- MongoDB (optional for local development; the API can start with in-memory
  storage when MongoDB is unavailable)

## Start the backend

From the repository root:

```powershell
npm install
node server.js
```

The Express server listens on `0.0.0.0:3000` and exposes
`GET /api/health`. To connect from a phone or another device, use the laptop's
current Wi-Fi IPv4 address, keep both devices on the same network, and allow
inbound TCP port 3000 through the host firewall.

## Run the Flutter app

The default API host is configured in `lib/config/api_config.dart`. If the
laptop's Wi-Fi address changes, update `hostIp` there or override it at launch:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://<COMPUTER-LAN-IP>:3000
```

For a physical device using USB ADB reverse, run
`adb reverse tcp:3000 tcp:3000` and set
`API_BASE_URL=http://localhost:3000`.

## Local account setup

The backend initializes one mentor and one mentee account when starting with
an empty database or in-memory storage:

| Role | Name | Email | Password |
|---|---|---|---|
| Mentor | Alex Morgan, Senior Engineer | `alex.morgan@ymentor.com` | `AlexMentor!Ymentor2026` |
| Mentee | Sarah Chen, Computer Science Student | `sarah.chen@ymentor.com` | `SarahStudent!Ymentor2026` |

These accounts are for local development. Change their passwords before using
the application in a shared or production environment.

To provision an administrator, set both `YMENTOR_ADMIN_EMAIL` and
`YMENTOR_ADMIN_PASSWORD` before starting the backend or running
`node scripts/seedDatabase.js`. No administrator account is created unless both
values are supplied.

## Android networking

The Android manifest includes internet permission and permits cleartext HTTP
for local development. For production, serve the API over HTTPS and disable
cleartext traffic.

## Project structure

- `lib/` — Flutter application, screens, widgets, models, and API client
- `server.js` — Express API server
- `models/` — MongoDB models
- `middleware/` — Authentication and authorization middleware
- `scripts/seedDatabase.js` — MongoDB setup for the two local accounts
- `android/` — Android application configuration
