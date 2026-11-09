# ADRense — setup and commands

ADRense has a Flutter frontend and a FastAPI/PostgreSQL backend. This file contains the commands needed to run and check the project. See [DEVELOPMENT.md](DEVELOPMENT.md) for features, API routes, database tables, and implementation notes.

## Requirements

- Flutter SDK with Dart, Chrome, and optionally Android Studio.
- Python 3.11 or newer.
- PostgreSQL running locally; pgAdmin is optional.
- SMTP credentials and a verified sender for authentication and analyst-review emails.

The project folder is `adrense_flutter`. Run the following commands from that folder unless another directory is specified. The existing `backend/.env` is already configured locally; keep it private and do not overwrite it.

## Start the app — everyday commands

Open two PowerShell terminals.

**Terminal 1: backend**

```powershell
cd backend
.\.venv\Scripts\python.exe -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

**Terminal 2: frontend**, starting in `adrense_flutter`:

```powershell
flutter pub get
flutter run -d chrome --web-port=5173 --dart-define=ADR_API_URL=http://localhost:8000
```

Useful addresses:

- App: http://localhost:5173
- Backend health: http://localhost:8000/health
- Interactive API documentation: http://localhost:8000/docs

Keep both terminals running. Press `Ctrl+C` to stop a server. In the Flutter terminal, `r` hot reloads, `R` hot restarts, and `q` stops the app. Hot restart and reopening the app restore a saved login after backend validation, while the token remains valid.

To serve the web app without opening Chrome:

```powershell
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=5173 --dart-define=ADR_API_URL=http://localhost:8000
```

## First-time setup on another computer

Create the PostgreSQL database in pgAdmin's Query Tool:

```sql
CREATE DATABASE adrense_db;
```

From `adrense_flutter`, install the backend:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt -r requirements-test.txt
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
```

Edit `backend/.env` using the settings below. Start the backend with the everyday command above. Startup creates missing application tables; it does not replace existing users. Use migrations for future changes to existing database columns.

Install the frontend from `adrense_flutter`:

```powershell
flutter pub get
```

The Android and web platform folders already exist. Do not run `flutter create .` for normal startup.

## Backend configuration

Use `backend/.env.example` as the reference. Real secrets belong only in `backend/.env`, which is ignored by Git.

| Setting | Purpose |
| --- | --- |
| `DATABASE_URL` | PostgreSQL connection, such as `postgresql+psycopg://postgres:YOUR_PASSWORD@localhost:5432/adrense_db` |
| `SECRET_KEY` | Stable, random JWT/OTP secret, at least 32 characters |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | JWT lifetime; default 1440 minutes |
| `ADR_ADMIN_PASSWORD` | Optional local administrator seed password; only used when the account does not already exist |
| `SMTP_HOST` | Current provider: `smtp-relay.brevo.com` |
| `SMTP_PORT` | `587` for STARTTLS |
| `SMTP_FROM` | Verified sender: `ADRense <admin.adrense@gmail.com>` |
| `SMTP_USERNAME` | Brevo SMTP login |
| `SMTP_PASSWORD` | Brevo SMTP key, not the normal account password or HTTP API key |
| `SMTP_STARTTLS` | `true` for port 587 |
| `SMTP_SSL` | `false` for port 587; use `true` for implicit TLS on port 465 |

Generate a new secret for a new installation, from the backend directory:

```powershell
.\.venv\Scripts\python.exe -c "import secrets; print(secrets.token_urlsafe(48))"
```

Do not regenerate the secret at every startup. Changing it invalidates JWTs and outstanding email codes. SMTP delivery does not require a Brevo HTTP API key.

The local administrator email is `admin.adrense@gmail.com`. The startup seed never resets an existing account's password or elevates an ordinary user. Setting a different `ADR_ADMIN_PASSWORD` will not change an existing administrator password. Use the administrator's existing password to sign in; there is no public admin registration endpoint. Remove seed credentials from production configuration after provisioning.

## Persistent login

Sign in once, then close and reopen the app. Startup reads the saved access token and validates it with `/api/auth/me` before opening the correct general-user, analyst, or administrator dashboard. Passwords are not saved. Logging out removes the saved token. Expired, revoked, or restricted sessions return to splash/sign-in.

If the backend cannot be reached, the app preserves the saved session and offers **Retry connection** or **Sign in instead**. Choosing sign-in instead clears the saved session. The current access-token lifetime is controlled by `ACCESS_TOKEN_EXPIRE_MINUTES` (default 1440); this implementation does not issue refresh tokens.

Tokens use `flutter_secure_storage`. On web, use **HTTPS or localhost**, keep the same browser profile and frontend origin/port, and do not clear site data if you want login to persist. Browser storage remains accessible to the app's origin, so normal web/XSS protections still matter. On Android, secure storage requires API 23+; app backup is disabled to avoid restoring encrypted tokens without their device keys. Adding the storage plugin requires a full Flutter restart/rebuild the first time.

## Checks and diagnostics

From `adrense_flutter`:

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

From `adrense_flutter/backend`:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements-test.txt
.\.venv\Scripts\python.exe -m unittest discover -s tests -v
.\.venv\Scripts\python.exe check_smtp.py
```

The tests use an isolated SQLite database and mock mail delivery. `check_smtp.py` checks SMTP TLS/authentication without sending an email.

With the backend running, this optional diagnostic signs in using the configured local seed password and reads only user counts/statistics:

```powershell
.\.venv\Scripts\python.exe check_live_admin.py
```

It will fail to sign in if the existing administrator password differs from `ADR_ADMIN_PASSWORD`; this does not mean the server is unavailable.

The backend suite and Flutter suite cover authentication, analyst applications, live admin data, and persistent-session behavior. Run the commands above for current results; existing analyzer warnings/style notices remain.

## Android and device connections

For the Android emulator, run from `adrense_flutter`:

```powershell
flutter run -d YOUR_DEVICE_ID --dart-define=ADR_API_URL=http://10.0.2.2:8000
```

Find device IDs with `flutter devices`. For a physical phone, use the computer's LAN IP, start Uvicorn with `--host 0.0.0.0`, and allow the connection through the local firewall. Localhost on a phone refers to the phone itself. Use HTTPS for deployed environments. The default CORS configuration allows local browser origins; configure explicit deployment origins before hosting a web frontend elsewhere.

## Build and maintenance

From `adrense_flutter`:

```powershell
flutter build web --release --dart-define=ADR_API_URL=https://YOUR_API_HOST
flutter build apk --release --dart-define=ADR_API_URL=https://YOUR_API_HOST
dart run flutter_native_splash:create
```

Use cleanup only when resolving stale build artifacts or dependency changes:

```powershell
flutter clean
flutter pub get
```

Common issues:

- **Cannot connect to backend:** check `/health`, the running API terminal, and `ADR_API_URL`.
- **No pubspec.yaml found:** run Flutter commands inside `adrense_flutter`.
- **Python module import errors:** run Uvicorn from `backend`, using its `.venv` Python.
- **Emails do not arrive:** check SMTP credentials, verified sender, spam folder, provider logs, and backend errors. OTP emails can be resent; review emails are retried automatically.
- **Analyst cannot sign in:** both email verification and administrator approval are required.
- **Frontend shows old code:** hot restart or reload the browser. After adding plugins, restart Flutter completely.
- **Blank/failed screen:** check the first Flutter/browser-console error. The overview's nonuniform-border issue has been fixed.
- **Font loading on an offline machine:** Google Fonts may need network access; font assets are not bundled.


Profile updates now save through the backend: basic information, medical conditions, medications/doses, and allergies. Changing the email opens a verification-code dialog; the old address stays active until the new one is verified. Previous ADR records remain demo-only. Restart the backend after this update so its two additional profile tables are created.


The selected light/dark appearance is saved locally and restored after reloads and app restarts, including after logout. Select the desired theme once after installing this update; earlier choices were not saved. New plugin dependencies require a complete Flutter restart/rebuild, and a new APK installation is needed to get this change on Android.
