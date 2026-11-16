# ADRense — development notes

See [README.md](README.md) for setup, configuration, run commands, tests, and troubleshooting. These are the project's two maintained Markdown documents; historical change logs and screenshot notes have been consolidated here.

## Connected features

- General-user and analyst registration, bcrypt password hashing, persistent JWT login, startup session verification, account persistence, and authenticated profile retrieval.
- Email ownership verification and forgot-password recovery using six-digit email codes.
- Six-step analyst applications with professional details and private PDF/image uploads.
- Admin application review, private document previews, persisted approvals/rejections, and decision emails.
- Database-backed user management with search, role/status filters, account details, and restrict/restore actions.
- Registration analytics with separate general-user and analyst series, interactive tooltips, range selection, and legend filters.
- Independent light/dark themes, responsive phone-width layouts, shared UI components, and chart animations. Bottom navigation has a full-width background for all roles. Controls fill available widths up to 600 logical pixels; on larger screens they form a centered 393-pixel row aligned with the page content. Navigation controls respect device safe-area insets while the bar background reaches both screen edges.

## Authentication and email rules

- New non-admin accounts must verify their email before login. Analyst accounts also require professional approval; email verification alone does not grant analyst access.
- Forgot-password requests return a generic confirmation regardless of whether the address exists. Resetting a password neither verifies the email nor activates a pending/rejected/restricted account.
- Codes expire after 10 minutes, are single-use, and are stored as keyed HMAC digests. There is a 60-second resend cooldown and a five-attempt limit; the attempt lock remains until expiry, including across resends.
- Authentication routes have persistent per-peer/per-route limits of 30 requests per hour. Configure trusted proxy handling explicitly when deploying behind a reverse proxy.
- Passwords require at least eight characters, uppercase, lowercase, a special character, no spaces, and no more than 72 UTF-8 bytes for bcrypt. Confirmation must match.
- Password resets and account restrictions invalidate earlier JWTs using a database session version. New protected routes must enforce role, active status, email verification, and session-version checks.
- Verification/reset emails use FastAPI background tasks after the response. They are not a durable queue; a server interruption can lose a pending OTP email. Users can resend a code.
- Analyst review emails use a persistent outbox, committed with the review decision. The retry worker runs every 30 seconds and backs off up to an hour after delivery failures. Existing decisions are not retroactively emailed. A crash after SMTP acceptance but before the database commit can cause a duplicate on retry.
- Emails include the ADRense logo and plain-text alternatives. Keep `assets/native_splash.png` available alongside the backend deployment.

## Analyst registration and document review

The six steps are credentials, basic information, professional information, license details, documents, and submission review.

- Country and calling-code selectors are searchable, themed, and display country flags. Residence country and phone calling code are independent selections.
- License expiry accepts a valid future date. The input inserts slashes automatically as `MM/DD/YYYY` and supports backspacing.
- Professional license and degree certificate are required. Professional ID card is optional.
- Accepted files: PDF, JPG/JPEG, and PNG, maximum **5 MB each**. Files can be replaced or removed before submission.
- Frontend checks extension, size, and signature. Backend independently parses content, rejects malformed/mismatched files, oversized images, encrypted PDFs, and PDFs with automatic actions, scripts, or embedded files.
- Registration submits details and base64 documents together, with a **22 MiB** whole-request limit. User, application, and documents are committed together to avoid orphaned uploads.
- Document bytes are stored in PostgreSQL, not under a public static URL. Admin preview requests require an authenticated admin bearer token and return `Cache-Control: no-store`.
- Admin path: **Verification → Review Application → View / Approve / Reject**. Rejection requires a reason; completed reviews cannot be overwritten by a repeat review request.
- Approved/rejected analysts receive the decision at their registered account email. Rejection emails include administrator notes. Approval still requires email ownership verification before login.
- Older analyst accounts without the required application documents cannot be approved through this flow.

## User management and analytics

User Management reads patient/analyst account metadata from the database. Password hashes, document contents, medications, medical conditions, and personalized health data are excluded. Administrator seed accounts are excluded from this list and registration totals.

Restricting an active account saves `restricted` and revokes sessions. Restoring a restricted account saves `active`; email verification is still required. This action cannot activate a pending/rejected analyst application.

The overview chart uses **teal for general users** and **purple for analysts**. Available ranges:

| Range | Aggregation |
| --- | --- |
| 7 days | Daily |
| 30 days | Daily |
| 90 days | Weekly |
| 365 days / 1Y | Monthly |

Missing dates are filled with zero registrations. Calendar boundaries use `Asia/Karachi`. The graph counts new accounts, including unverified and pending registrations. Summary cards show lifetime account totals and active, email-verified accounts. Hover/tap points for details; toggle series using the legend. Refresh fetches current data.

## API reference

All paths are relative to the backend URL. Admin routes require an active, email-verified administrator and a valid session version.

| Method | Route | Purpose |
| --- | --- | --- |
| GET | `/health` | Backend availability |
| POST | `/api/auth/register` | Create a general-user/analyst account |
| POST | `/api/auth/login` | Obtain a JWT |
| GET | `/api/auth/me` | Current account and permitted own-profile data |
| GET / PATCH | `/api/profile` | Read/update the signed-in general user's profile |
| POST | `/api/profile/email-change/request` | Send an OTP to a proposed new email without changing the account |
| POST | `/api/profile/email-change/confirm` | Verify the OTP, update email, and rotate the active session |
| POST | `/api/auth/resend-verification` | Request a verification code |
| POST | `/api/auth/verify-email` | Verify a six-digit code |
| POST | `/api/auth/forgot-password` | Request a reset code; generic response |
| POST | `/api/auth/reset-password` | Set and confirm a new password using the code |
| GET | `/api/admin/analysts` | Applications and document metadata |
| GET | `/api/admin/documents/{id}` | Private PDF/image bytes |
| POST | `/api/admin/analysts/{id}/review` | `decision`: `approve` or `reject`; rejection requires `reason` |
| GET | `/api/admin/users` | Real general-user/analyst account metadata |
| POST | `/api/admin/users/{id}/status` | `action`: `restrict` or `restore` |
| GET | `/api/admin/registrations?days=30` | Registration buckets and account summary; accepts 7, 30, 90, 365 |

Analyst registration adds `analyst_details` and a `documents` list to the standard registration payload. Each document includes `kind` (`license`, `degree`, or `id_card`), `filename`, and `content_base64`. Use `/docs` for the complete request schemas. Validation errors omit raw passwords and document contents.

## Database tables

| Table | Contents |
| --- | --- |
| `users` | Account identity, bcrypt hash, role, status, registration date, basic professional fields |
| `patients` | General-user basic profile and legacy list columns |
| `patient_profile_data` | JSON conditions, medications, allergies, and medication doses |
| `pending_email_changes` | User-bound pending address, OTP digest, expiry, attempt count, and session version |
| `auth_states` | Email-verification flag and session version |
| `email_challenges` | OTP digests, purpose/address keys, expiry, attempts, consumed state |
| `auth_rate_limits` | Persistent authentication request counters |
| `analyst_applications` | Professional details and review audit fields |
| `analyst_documents` | Private document bytes, category, filename, MIME type, size |
| `review_notifications` | Decision-email delivery status, attempts, and next retry |

Startup creates missing tables. It does not migrate existing columns. Back up the database, including document and notification tables, before deployment changes.

Useful read-only SQL for pgAdmin:

```sql
SELECT id, name, email, role, status, created_at
FROM users ORDER BY created_at DESC;

SELECT user_id, is_verified, session_version
FROM auth_states ORDER BY user_id;

SELECT user_id, details, reviewed_by, reviewed_at, review_reason
FROM analyst_applications ORDER BY user_id DESC;

SELECT id, user_id, kind, filename, media_type, size
FROM analyst_documents ORDER BY id DESC;

SELECT id, user_id, decision, attempts, next_attempt_at, sent_at
FROM review_notifications ORDER BY id DESC;
```

Avoid selecting password hashes or document byte columns for routine diagnostics.

## Source map

```text
adrense_flutter/
  README.md                         Setup and command reference
  DEVELOPMENT.md                    Feature, API, database, and maintenance notes
  assets/                           SVG logo and PNG email/native-splash logo
  lib/
    main.dart                       App entry point, navigation, shared state
    core/                           Themes, reusable widgets, registration inputs
    features/                       Splash and animated charts
    services/api_service.dart       Backend requests and saved JWT session
    views/auth/                     Registration, login, verification/reset screens
    views/patient/                  General-user screens
    views/analyst/                  Analyst workspace screens
    views/admin/                    Review, users, and registration chart
    widgets/                        Shared cards, buttons, navigation
    theme/                          Semantic color palette
  test/                             Flutter widget/unit tests
  backend/
    main.py                         FastAPI startup, CORS, upload limit, routes
    API/                            Authentication and administrator endpoints
    Business/                       Auth, email, rate limits, access checks, retries
    DAO/                            SQLAlchemy engine and session handling
    DTO/                            Request validation and document checks
    Models/                         SQLAlchemy tables
    tests/                          Isolated backend tests
    requirements.txt                Runtime Python dependencies
    requirements-test.txt           HTTP test-client dependency
    .env.example                    Configuration template without real secrets
    .env                            Private local configuration, ignored by Git
```

Many screen files use Dart `part` / `part of` and extensions on `_ADRenseAppState`; they are not independent libraries. Standalone widgets such as the registration chart have normal imports. Follow the existing file declarations when adding screens. `ApiService` keeps the active JWT in memory and persists it through `SessionStore` / `SecureSessionStore` in `lib/services/session_store.dart`. Storage keys are scoped to the backend URL. Startup validates the saved token through `/api/auth/me` and reuses the same profile-loading and role-routing logic as a normal sign-in. Logout, password recovery completion, and rejected sessions remove the persisted token; temporary connectivity/server failures preserve it for a retry. The token expires according to backend policy; refresh-token rotation is not implemented. Storage operations are serialized, and session generations prevent an old restore response from reopening a logged-out session or clearing a newer login.

## Current boundaries

Drug safety scores, clinical predictions, evidence, medicines, analyst ADR/signal decisions, report generation/export, and dataset workflows still contain illustrative/demo data or placeholder actions. Registration/profile retrieval, uploaded credential review, account management, and registration analytics are connected; this does not make clinical analysis a live backend feature. Basic information, conditions, current medications/doses, and allergies persist through the authenticated profile API. Previous ADR records remain hardcoded/local and are not sent to this API.

Names currently follow the existing English first/last-name validation rule. Exact pixel matching to historical screenshots is not certified. Google Fonts are used without bundled offline font assets. Before production hosting, configure HTTPS, deployment CORS origins, trusted proxies, operational monitoring, database migrations/backups, and an appropriate client token-storage policy.


## Patient-screen interactions

Drug Comparison has a back control returning to medicine details, styled like Personalized Evidence. Analyze uses plain-language input, example chips, paste/clear actions, a character limit, and input guidance. After Analyze, it retains the original demonstration results: confidence banner, detected-drug card, detected-ADR cards, relationship rows, Submit ADR, and Reset Analysis. Scores and relationships are explicitly illustrative sample data, not live clinical analysis. Submit ADR saves a demo report in the current screen session only; no server report is submitted. Reset preserves the entered description, and editing the text invalidates previous results.


## Profile saves and email changes

Registration accepts medical conditions, current medications, optional doses, and allergies. The frontend collects allergies in the health-information step. Save/Add/Remove actions on the profile wait for the API to confirm before updating displayed values. Empty lists remove all entries. JSON storage preserves names containing commas; older profiles continue to load from the existing columns until first updated. The weight display uses the saved weight-range field. Condition dates/statuses and default medication doses are no longer fabricated for the live lists. Previous ADRs retain their existing local/demo behavior.

Direct email changes are rejected by PATCH. Requesting an email change sends a six-digit code to the proposed address, while the original address remains the login until verification succeeds. Codes expire after 10 minutes, have a 60-second resend cooldown and a five-attempt lock, and are bound to the authenticated user and session version. Verification rechecks address availability, updates the verified email atomically, invalidates older JWTs and old address verification/reset codes, and returns a replacement JWT for the current device to persist. SMTP failure, invalid/expired codes, and conflicting addresses do not change the account email. The new profile tables are created on backend startup; existing columns are preserved.


Theme selection is a local preference stored with `shared_preferences`, independent of saved login tokens. Startup restores it before attempting session restoration. Logout does not remove it. Basic Information shows a fixed Edit/Save and red-cross column for every row in edit mode; a cross discards that row's unsaved draft rather than changing saved account data.
