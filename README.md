# QChat

Flutter + TDesign messaging application with a Next.js REST backend, PostgreSQL/Prisma, Redis, a standalone Socket.IO gateway, and private S3/MinIO media. Source is implemented in this workspace; no fake chat API or seeded user conversations are used.

**Status: incomplete, not production-ready.** Read [implementation and verification status](docs/STATUS.md) before deployment.

## Requirements

- Node.js 24 and pnpm 10.11.0
- Flutter 3.47.7 / Dart 3.13.5 (resolved package versions in `apps/mobile/pubspec.lock`)
- PostgreSQL 17, Redis 7, private S3-compatible storage
- Android SDK/JDK for APK builds; macOS/Xcode for iOS

## Backend

```sh
pnpm install --frozen-lockfile
pnpm db:generate
# Set DATABASE_URL, REDIS_URL, JWT_SECRET and WEB_ORIGIN in the process environment.
pnpm db:migrate
pnpm --filter @qchat/server dev
pnpm --filter @qchat/realtime dev
```

For local Flutter web, use `WEB_ORIGIN=http://localhost:8080`. The REST base is `http://localhost:3000/api` and realtime is `http://localhost:3001`. Production requires HTTPS/WSS. See [deployment](docs/DEPLOYMENT.md) for Docker Compose and backups.

## Flutter on Chrome

```sh
cd apps/mobile
flutter pub get --enforce-lockfile
flutter run -d chrome --web-port 8080
```

Or build and serve the release bundle:

```sh
cd apps/mobile
flutter build web --release
cd ../..
node scripts/serve-web.mjs
```

Open `http://localhost:8080` in Chrome. Dependencies and SDK are installed locally under `.tools/flutter` in this workspace. The Windows SDK path contains spaces, which currently triggers a native-hook tool error; a temporary `subst Q: "E:\Qchat APP"` alias allows invoking `Q:\.tools\flutter\bin\flutter.bat` from a path without spaces. The alias does not move files.

Register two real accounts, send and accept a friend request, then open the friend from Contacts. Verify text delivery with two browser profiles or separate devices; browsers sharing one origin/profile also share secure storage and should not be used as independent accounts.

## Checks

```sh
pnpm typecheck
pnpm test
pnpm build
# Requires running real backend/gateway/database/Redis:
TEST_API_URL=http://localhost:3000/api TEST_REALTIME_URL=http://localhost:3001 pnpm test:integration
cd apps/mobile
flutter analyze
flutter test
flutter build web --release
```

Integration tests skip explicitly when TEST_API_URL is unset. A skipped test is not a pass.

## Structure

- `apps/mobile`: Flutter QChat design system, authentication, chats, contacts, groups, Moments, profile, settings and initial WebRTC client.
- `apps/server`: Next.js API, domain modules, Prisma schema and SQL migration.
- `apps/realtime`: authenticated gateway and transactional outbox delivery.
- `apps/admin`: admin interface served through Next.js `/admin`.
- `packages/contracts`: strict shared Zod schemas.
- `infra`: Dockerfiles, Compose, HTTPS/WSS reverse proxy.
- `tests`: contract/security unit tests and real-service integration scenario.

No end-to-end encryption is claimed. Private message content is stored server-side. Full push/background-call support and several advanced UI flows remain unfinished.
