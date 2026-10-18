# Self-hosting

1. Install Docker Engine and Compose on a Linux VPS. Configure DNS names for API/realtime and private media. Restrict database, Redis, MinIO console and service ports to the Docker network.
2. Copy `.env.example` to `.env`. Generate independent random database, storage and JWT secrets. Set the real API web origin and S3 endpoint. Never commit `.env`.
3. Put a certificate covering both names and its private key at `infra/certs/fullchain.pem` and `infra/certs/privkey.pem`. Update the two nginx server names. Configure certificate renewal outside the container.
4. Run `docker compose --env-file .env -f infra/compose.yaml up --build -d`. The migration job must complete before server/gateway start.
5. Create `qchat-private` in MinIO using an administrative client on the private network. Keep the bucket private. Configure bucket CORS for the exact Flutter web origin, with PUT/GET/HEAD and Content-Type allowed. The same S3 endpoint must be reachable from browsers and containers so signatures match.
6. Configure SMTP credentials for verification/reset. The server returns EMAIL_NOT_CONFIGURED when no provider exists; it never fakes delivery.
7. Build Flutter with `--dart-define=API_URL=https://chat.example.com/api --dart-define=REALTIME_URL=https://chat.example.com`. Web media and camera require HTTPS except localhost.
8. The admin console is at `/admin` on the Next.js service. Promote a specific existing user to ADMIN through an audited operational database procedure; there is no default admin or shared password.

The current Compose deployment has not been executed in this Windows environment. The admin UI is served by the main Next.js application to share authorization and avoid an additional public origin. TURN, push, background calling and media scanning require further implementation/configuration before production.

## Backup and restore

Take encrypted PostgreSQL dumps with `docker compose -f infra/compose.yaml exec -T postgres pg_dump -U qchat -Fc qchat > qchat.dump`. Back up the private MinIO bucket with an S3-compatible backup client and retain its encryption/access configuration. Store backups off-host with restricted access. Redis holds transient coordination; its loss must not delete messages.

Restore to an isolated environment first using `pg_restore --clean --if-exists --no-owner`, restore media objects with unchanged keys, and validate counts and account/message access before switching DNS. Revoke sessions and rotate secrets if the backup was exposed. Practice restore drills; backups are not verified until restored.

## Retention

The current account-delete endpoint disables the account and revokes sessions; it does not purge all personal data. Export currently caps each collection at 1,000 records. A complete retention/export/purge job and legal policy are release blockers. No production retention promise is made by this baseline.
