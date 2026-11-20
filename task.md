# LAKBAY LOKAL — Implementation Task List

> Consolidated, ordered task breakdown derived from `docs/PROJECT.MD`, `docs/SERVER.MD`,
> `docs/MAP.MD`, `docs/THEME.MD`, and the project skills in `.agents/skills/`.
> Source of truth for every task is the referenced document section. When a task and a doc
> disagree, the doc wins — update the doc first.

## Status Legend

| Marker | Meaning |
| --- | --- |
| `[ ]` | Not started |
| `[~]` | In progress |
| `[x]` | Done (verified) |
| `[!]` | Blocked |
| `[–]` | Deferred by decision (documented, deliberately not built) |

## Current Baseline (verified 2026-10-29)

- Ionic React 19 + Vite 8 + TypeScript starter scaffolded (`src/App.tsx`, `src/pages/Home.tsx`).
- Only one route exists: `/home`. No auth, no API layer, no domain models in the frontend.
- `server/` exists with the FastAPI initialization slice: config, DB session, health endpoint,
  pinned `requirements.txt`, venv, and a green smoke test. No auth, destination, or itinerary routes yet.
- `docs/` contains the four authoritative specs (project, server, map, theme).
- Theme tokens exist only as the Ionic starter `src/theme/variables.css`; the LAKBAY palette is **not** applied.
- Test tooling present but empty of real coverage: Vitest (`src/App.test.tsx`), Playwright (`e2e/app.spec.ts`).
- `android/` platform added with `@capacitor/android ^8.6.0`; `android/app/src/main/AndroidManifest.xml` present.
- Capacitor identity is still the starter's, **baked into Gradle** — `android/app/build.gradle` has
  `namespace = "io.ionic.starter"` and `applicationId "io.ionic.starter"`, with the Java package at
  `android/app/src/main/java/io/ionic/starter/`. Changing only `capacitor.config.ts` will not fix this.
- Android SDK present (`ANDROID_HOME=E:\Android`, SDK at `%LOCALAPPDATA%\Android\Sdk`), JDK 17 (Temurin).

---

# Phase 0 — Project Foundations

| ID | Task | Source |
| --- | --- | --- |
| T-001 | [x] Set Capacitor app identity end-to-end: appId `ph.lakbaylokal.app`, appName `LAKBAY LOKAL`; `namespace`/`applicationId` in `android/app/build.gradle`; `MainActivity` moved to `ph/lakbaylokal/app/`; `strings.xml`; `npx cap sync android`; Gradle `assembleDebug` + `assembleRelease` green; identity confirmed via `aapt2 dump badging` on the built APK. NOTE: project requires **JDK 21**, not 17 — Capacitor 8.6.0 declares Java 21 source/target | PROJECT §4 |
| T-002 | [x] Replace the empty `src/theme/variables.css` with LAKBAY design tokens (`--ll-*` palette, spacing, radius) and map them to `--ion-color-*` incl. shade/contrast; ship the brand logo (`public/lakbay.jpg`) in the app header | THEME §2, §15 |
| T-003 | [x] Load the Inter font family with `system-ui` fallback and define the typography scale as utilities/classes (self-hosted `@fontsource/inter`, no CDN — must work offline) | THEME §5 |
| T-004 | [x] Create `.env.example` for the frontend (`VITE_API_BASE_URL`, `VITE_MAPTILER_API_KEY`) and confirm `.env.local` stays gitignored | MAP §5, SERVER §9.8 |
| T-005 | [x] Establish the `src/` folder contract (`components/`, `pages/`, `hooks/`, `services/`, `types/`, `theme/`) without duplicating existing files | MAP §6 |
| T-006 | [x] Add shared design primitives: `Button`, `Card`, `StatusBadge`, `EmptyState`, `ErrorState`, `LoadingState`, `Input` — driven by theme tokens only | THEME §8, §9, §10, §12 |
| T-007 | [ ] Produce real brand assets: transparent PNG/SVG logo, 512x512 maskable PWA icon, favicon, Android launcher icons in all densities. `public/lakbay.jpg` is a 100 KB JPEG that renders muddy at 24px, and `manifest.json` still points at two icon files that do not exist | THEME §9, MAP §4 |
| T-008 | [ ] Decide the dark-mode strategy. `dark.system.css` is currently disabled because THEME.MD defines a light-only palette; either specify dark tokens or record the light-only decision permanently | THEME §2, §15 |

---

# Phase 1 — Backend Core

| ID | Task | Source |
| --- | --- | --- |
| T-101 | [x] Scaffold `server/` per the documented structure (`app/main.py`, `core/`, `db/`, `models/`, `schemas/`, `api/routes/`, `services/`, `tests/`, `data/`) | SERVER §3 |
| T-102 | [x] Add `requirements.txt` with pinned FastAPI, Uvicorn, SQLAlchemy 2.x, Pydantic, PyJWT, pwdlib[argon2]; add `README.md` and `.gitignore` (DB file, `.venv`, `.env`) | SERVER §2, §3 |
| T-103 | [x] Implement `core/config.py` (Pydantic settings from env: `APP_NAME`, `APP_ENV`, `API_PREFIX`, `DATABASE_URL`, `JWT_*`, `ACCESS_TOKEN_EXPIRE_MINUTES`, `CORS_ORIGINS`, discovery ports) with startup validation for production secrets | SERVER §5 |
| T-104 | [x] Implement `db/session.py` + `db/base.py`: SQLite engine (`check_same_thread=False`), FK pragma enforcement, request-scoped session dependency with reliable close | SERVER §4 |
| T-105 | [x] Implement `models/user.py` with unique+indexed email, password hash only, created_at | SERVER §7, PROJECT §6 |
| T-106 | [x] Implement `models/destination.py` (name, description, address, nullable lat/lng, category, nullable image_url, verification_status, created_at) | SERVER §7 |
| T-107 | [x] Implement `models/itinerary.py` and `models/itinerary_item.py` with FK cascade, positive `visit_order`, and documented unique `(itinerary_id, visit_order)` strategy | SERVER §7 |
| T-108 | [x] Implement `db/init_db.py` to create `data/` and tables; dev-only idempotent seed in `scripts/seed_dev.py` (10 synthetic destinations, explicit run only, `APP_ENV=development` gate, `--force` deletes only its own marked rows) | SERVER §4 |
| T-109 | [x] Implement `main.py`: app factory, `API_PREFIX` router mounting, CORS from config (no wildcard with credentials), global exception handler returning non-sensitive errors | SERVER §9.10, §10 |
| T-110 | [x] Implement `GET /api/health` returning `{status, service: "lakbay-lokal", version}` with no auth and no sensitive data | SERVER §9.5 |

---

# Phase 2 — Authentication API

| ID | Task | Source |
| --- | --- | --- |
| T-201 | [x] Implement `core/security.py`: Argon2 hashing via `pwdlib`, JWT encode/decode validating signature + expiry + required claims | SERVER §2, §8 |
| T-202 | [x] Implement `schemas/auth.py` and `schemas/user.py` (register, login, token response, safe user out — never expose `password_hash`) | SERVER §6, §7 |
| T-203 | [x] Implement `POST /api/auth/register`: validate input, reject duplicate email with `409`, hash password, return safe user (`201`) | SERVER §6 |
| T-204 | [x] Implement `POST /api/auth/login`: validate credentials, return access token + `token_type` + `expires_in` | SERVER §6 |
| T-205 | [x] Implement `GET /api/auth/me`: requires valid bearer token, returns authenticated profile | SERVER §6 |
| T-206 | [x] Implement `api/deps.py` `get_current_user` — identity derived only from the validated token, never from request body | SERVER §8 |
| T-207 | [x] Implement `services/auth_service.py` and keep route handlers thin | SERVER §3 |

---

q
---

# Phase 4 — Itineraries API

| ID | Task | Source |
| --- | --- | --- |
| T-401 | [x] Implement `schemas/itinerary.py` (create, patch, item in/out, ordered detail response) | SERVER §6, §7 |
| T-402 | [x] Implement `POST /api/itineraries`: auth required, owner from token, validate every `destination_id`, validate positive `visit_order` and duplicate rules, create itinerary + items in one transaction | SERVER §6 |
| T-403 | [x] Implement `GET /api/itineraries/me`: returns only the caller's itineraries with items in `visit_order` | SERVER §6 |
| T-404 | [x] Implement `PATCH /api/itineraries/{id}` with ownership check, documented item replacement contract, transaction-safe reordering, and `404` for inaccessible/nonexistent | SERVER §6, §7 |
| T-405 | [x] Implement `DELETE /api/itineraries/{id}` with ownership check, cascading item deletion, `204` success, `404` otherwise | SERVER §6 |
| T-406 | [x] Implement `services/itinerary_service.py` with ownership assertion helper reused by PATCH/DELETE | SERVER §3, §8 |
| T-407 | [x] Add `GET /api/destinations/categories` (or equivalent derived list) to support the frontend filter UI | PROJECT §5.2 |

---

# Phase 5 — Backend Test Suite

| ID | Task | Source |
| --- | --- | --- |
| T-501 | [x] Add `pytest` + `httpx` test harness with an isolated temp SQLite DB per test session and dependency overrides | SERVER §12 |
| T-502 | [x] `test_auth.py`: registration, duplicate email, login success/failure, expired token, malformed/invalid token, `/me` protection | SERVER §12 |
| T-503 | [x] `test_destinations.py`: listing, search, category filter, pagination, missing ID `404` | SERVER §12 |
| T-504 | [x] `test_itineraries.py`: create valid/invalid destination IDs, visit ordering, update, delete, cross-user access prevention | SERVER §12 |
| T-505 | [x] Test transaction rollback when an itinerary item fails mid-create | SERVER §12 |
| T-506 | [x] Test FK enforcement and persistence across sessions | SERVER §12 |

---

# Phase 6 — Local Discovery, Health, and Reconnection

| ID | Task | Source |
| --- | --- | --- |
| T-601 | [x] Define and document the versioned discovery protocol (`service`, `version`, `action`, `server_id`, `api_port`) shared by app and server | SERVER §9.4 |
| T-602 | [x] Implement the server-side UDP listener on port `37020`: validate payload/version, ignore malformed and unrelated packets, cap packet size and processing time, reply from the real interface address (never `127.0.0.1`) | SERVER §9.3, §9.4 |
| T-603 | [x] Persist a stable `server_id` in server configuration so identity survives restarts | SERVER §9.4 |
| T-604 | [–] Optional: advertise `_lakbay-lokal._tcp.local.` over mDNS as a supplementary discovery channel — deferred by decision, no `zeroconf` dependency added; UDP broadcast is the primary channel and the README states this | SERVER §9.3 |
| T-605 | [x] Document Windows Firewall rules for TCP `8000` and UDP `37020`, restricted to private/local profiles; add a runnable PowerShell snippet to the server README | SERVER §9.6 |
| T-606 | [x] Document the `--host 0.0.0.0 --port 8000` run command for LAN testing and keep `127.0.0.1` as the default dev command | SERVER §9.2, §11 |
| T-607 | [x] Implement a custom Capacitor Android plugin (or vetted plugin) exposing UDP broadcast discovery + optional mDNS discovery to JS; refuse normally impossible browser-only paths | SERVER §9.3 |
| T-608 | [x] Implement `src/services/connection.service.ts`: discovery orchestration, health-check validation of candidates, deterministic multi-server resolution, cached endpoint as a temporary hint only | SERVER §9.3, §9.4, §9.5 |
| T-609 | [x] Implement bounded exponential-backoff retry, network-change detection (`@capacitor/network`), obsolete-attempt cancellation, and recovery after server restart | SERVER §9.7 |
| T-610 | [x] Expose connection state machine (`Discovering`, `Connecting`, `Connected`, `Reconnecting`, `Unavailable`, `Blocked`) and surface it in the UI with a retry action | SERVER §9.12 |
| T-611 | [x] Configure Android manifest: `INTERNET`, `ACCESS_NETWORK_STATE`, discovery/multicast needs; cleartext HTTP scoped to local development only via network security config | SERVER §9.9 |
| T-612 | [x] Handle the documented hotspot/router failure modes (client isolation, blocked broadcast) with diagnostics and a clear retry flow — never invent an IP or silently fall back to manual entry | SERVER §9.11 |

---

# Phase 7 — Frontend Foundations

| ID | Task | Source |
| --- | --- | --- |
| T-701 | [x] Define `src/types/` domain models mirroring the API (`User`, `Destination`, `Itinerary`, `ItineraryItem`, map types, API envelopes) | MAP §6, PROJECT §6 |
| T-702 | [x] Implement `src/services/api-client.ts` that resolves the base URL from the connection service, attaches the bearer token, and normalizes errors | SERVER §9.8 |
| T-703 | [x] Implement `src/services/auth.service.ts`, `destination.service.ts`, `itinerary.service.ts` on top of the API client | MAP §6 |
| T-704 | [x] Implement `AuthContext` + token persistence (Capacitor Preferences or secure storage) with guarded routes and logout cleanup | PROJECT §5.1, §5.4 |
| T-705 | [x] Implement `AuthGuard` / redirect logic so private routes require a session and auth routes redirect when signed in | PROJECT §5.1 |
| T-706 | [x] Implement `useDestinations`, `useItineraries`, `useConnection` hooks with loading/error/empty states and request de-duplication | MAP §6, §11 |
| T-707 | [x] Build the app shell: bottom tab navigation (Explore, My Trips, Profile) using Ionic components and LAKBAY tokens | THEME §11 |
| T-708 | [x] Wire all documented routes in `src/App.tsx`: `/splash`, `/login`, `/register`, `/home`, `/search`, `/destinations/:id`, `/itineraries`, `/itineraries/new`, `/itineraries/:id/edit`, `/itineraries/:id/map`, `/profile`, `/map` — `/splash` deferred to T-801 | PROJECT §9, MAP §6 |

---

# Phase 8 — Application Screens

| ID | Task | Acceptance focus | Source |
| --- | --- | --- | --- |
| T-801 | [x] Splash screen: brand mark, session restore, redirect to Home or Login | no flash of wrong route | PROJECT §9 |
| T-802 | [x] Login screen: email/password, inline validation, loading and error states, link to Register | accessible labels, 44px targets | PROJECT §5.1 |
| T-803 | [x] Registration screen: name/email/password, client + server validation, duplicate-email message | mirrors API errors | PROJECT §5.1 |
| T-804 | [x] Home / Explore screen: destination feed with image, name, municipality, category/verification badge, short description | intentional no-image fallback | THEME §9 |
| T-805 | [x] Destination search screen: debounced `search` query, category filter, empty and error states | no request storms | PROJECT §5.2 |
| T-806 | [x] Destination details screen: description, address, category, image, map position, **Add to Itinerary** action | single destination record source | MAP §3.3 |
| T-807 | [x] My Itineraries screen: list with title, travel date, item count, empty state, create CTA | ordering preserved | PROJECT §5.3 |
| T-808 | [x] Create Itinerary screen: title, description, travel date, destination picker, visit-order editing | validates IDs and order | PROJECT §5.3 |
| T-809 | [x] Edit Itinerary screen: update fields, add/remove/reorder destinations, save with optimistic-safe rollback | transaction-safe reorder UX | PROJECT §5.3 |
| T-810 | [x] Itinerary detail screen: ordered stop list, notes, "View on map" entry point, delete with confirmation | cascade delete reflected | PROJECT §5.3 |
| T-811 | [x] Profile screen: account info, saved itineraries shortcut, logout | no token leakage | PROJECT §5.4 |
| T-812 | [x] Global connection banner/dialog showing discovery state with retry, non-blocking for cached data | app usable while reconnecting | SERVER §9.12 |

---

# Phase 9 — Map Integration

### Phase 9.1 — Interactive Map Base

| ID | Task | Source |
| --- | --- | --- |
| T-901 | [x] Install and configure MapTiler SDK JS using `VITE_MAPTILER_API_KEY`; add `useMapTiler` hook | MAP §2, §4 |
| T-902 | [x] Build `DestinationMap` with an explicit non-zero container height, responsive sizing, Ionic lifecycle-aware resize, and full cleanup of instance/listeners | MAP §10, §11 |
| T-903 | [x] Apply LAKBAY colors to map controls, markers, and popup surfaces via `src/theme/map.css` | MAP §9 |
| T-904 | [x] Implement graceful handling for missing/invalid key, tile failure, and network failure | MAP §13 |

### Phase 9.2 — Destination Integration

| ID | Task | Source |
| --- | --- | --- |
| T-905 | [x] Render markers strictly from API coordinates; validate finite values and valid ranges; skip invalid records visibly | MAP §3.2, §8 |
| T-906 | [x] Prevent duplicate markers across refreshes by keying markers to destination IDs | MAP §3.2 |
| T-907 | [x] Build `DestinationPopup` with name, category, thumbnail, short description, verification badge, View Details | MAP §3.2 |
| T-908 | [x] Implement coordinate normalization `[longitude, latitude]` in one place only; add a unit test | MAP §8 |

### Phase 9.3 — Explore Experience

| ID | Task | Source |
| --- | --- | --- |
| T-909 | [x] Add `ExploreMapPage` with map/list switching, search, category filters, loading/empty/error states | MAP §3.1 |
| T-910 | [x] Implement `MapControls`: zoom in/out, reset view, focus selected, map/list toggle | MAP §3.5 |
| T-911 | [x] Keep the list view fully usable when the map fails | MAP §13 |

### Phase 9.4 — Itinerary Visualization

| ID | Task | Source |
| --- | --- | --- |
| T-912 | [x] Implement `ItineraryRoute`: ordered markers with visit-order labels, connecting line, and update on add/remove/reorder | MAP §3.4 |
| T-913 | [x] Label connections as visual links, not routes; no "driving"/"walking" wording | MAP §3.4, §14 |
| T-914 | [x] Handle itineraries with coordinate-less destinations without breaking the map | MAP §3.4 |

### Phase 9.5 — Optional Enhancements (only after core DoD)

| ID | Task | Source |
| --- | --- | --- |
| T-915 | [x] Current-location control with permission requested only on activation and a usable denied state | MAP §3.5, §12 |
| T-916 | [x] Geocoding / location search via MapTiler Geocoding API | MAP §2 |
| T-917 | [x] Marker clustering for dense destination sets | MAP §11 |
| T-918 | [x] Real road routing via a compatible provider, visually distinct from straight lines | MAP §14 |
| T-919 | [ ] **Before release:** replace the default public OSRM demo server (`router.project-osrm.org`) with a production-grade routing source. Status: road routing now works by default (T-923) using the OSRM demo endpoint, which is acceptable for development and demos but has no SLA. Point `VITE_ROUTING_BASE_URL` at a self-hosted OSRM or a paid provider before shipping, or set `VITE_ROUTING_PROVIDER=none` | MAP §14 |
| T-920 | [x] Fix the cold-start session-restore race found by e2e: on reload with a stored token, `/api/auth/me` can run before the connection service has resolved a base URL; `request()` throws `not_connected`, `AuthContext` clears the token and a valid session is silently discarded. Restore should wait for a usable endpoint (or re-attempt once connected) instead of treating "not connected yet" as "invalid session". FIXED: `not_connected` now means "not ready"; restore waits (bounded 15s) for a Connected endpoint, retries `me()`, and only `unauthorized` clears the token. Timeout settles anonymous with the token kept | e2e finding |
| T-921 | [x] Fix stale itinerary detail after PATCH: `useItinerary` is not invalidated by the edit flow (only the list hooks are), so the detail screen can show the pre-edit snapshot until a reload. FIXED: per-id detail staleness registry plus `markItineraryStale(id)`, called by the edit page after a successful PATCH | e2e finding |
| T-922 | [x] Emulator discovery: replies arrive with source `127.0.0.1` (QEMU NAT presents the host loopback), which resolves inside the emulator, so the health check fails there even though real packets reach the host. FIXED: emulator detection splits discovery targets (AVD sends only to `10.0.2.2`, Genymotion only to `10.0.3.2` — mixing broadcast plus aliases on one socket made the NAT drop replies), and loopback sources on an emulator are rewritten to `10.0.2.2` / `10.0.3.2`. Physical-device path unchanged; verified in the emulator: discovery returned host `10.0.2.2` and the server logged `GET /api/health 200` | emulator finding |
| T-923 | [x] Fix the route on the map where it will follow on the roads. DONE: road routing is ON by default (OSRM adapter), so the itinerary map draws real road-following geometry as a solid line over the dashed sequence link, with the legend and the "not directions" wording intact. `VITE_ROUTING_PROVIDER=none` disables it; provider failure falls back to the dashed link with an honest notice; fewer than 2 mapped stops makes no request | MAP §14 |
| T-924 | [x] Add forgot password and change profile details on the profile section. Backend: `password_reset_tokens` (SHA-256 hash only), `POST /auth/forgot-password` (202, no enumeration), `POST /auth/reset-password` (204/400), `PATCH /auth/me` (200/409), `POST /auth/change-password` (204/401), stdlib `smtplib` email service with dev-link fallback. Frontend: `/forgot-password`, `/reset-password`, login recovery link, profile display-name edit and password change. Verified 104 backend + 248 frontend tests, build and lint green.
 

---

# Phase 10 — Design, Accessibility, and Polish

| ID | Task | Source |
| --- | --- | --- |
| T-1001 | [x] Audit every screen against the THEME palette rules (navy structure, green actions, orange/sparing sky accents; no four-color equal intensity). Evidence: 12 screens audited; navy headings/structure, green primary actions, gold ratings/highlights, sky focus/links all resolve to `--ll-*` tokens; zero raw hex/rgba outside `variables.css`; no screen uses all four at equal intensity | THEME §4 |
| T-1002 | [x] Apply the 4px spacing scale, radius scale, and border-over-shadow elevation rules consistently. Evidence: radius offenders 0; spacing offenders 10 (all optical 1–2px, safe-area `0px`, or the `-1px` visually-hidden clip), judged in `.agents/audit/after-summary.txt`; the one real offender (20px) moved to `--ll-space-5` | THEME §6, §7 |
| T-1003 | [x] Verify WCAG AA contrast, visible focus states, screen-reader names for icon-only buttons, 44px touch targets, and font-scaling tolerance. Evidence: axe critical/serious 0 except ONE documented map-marker spacing node; contrast 33→0; touch 31→0 (6 vendor/inline exceptions); names 6→0 (all 6 baseline hits were shadow-DOM checker artifacts); focus 36→0; font-scale 12→0 (all 12 baseline hits were `.ll-visually-hidden` false positives) | THEME §13 |
| T-1004 | [x] Ensure status is never conveyed by color alone — pair badges with text/icon. Evidence: every `StatusBadge` renders a text label; verification/status labels (`Verified`, `Pending review`, `Unverified`) plus category; selected category chips add a check mark; map active markers change size and add a gold ring; itinerary stop numbers are text | THEME §12 |
| T-1005 | [x] Provide loading, empty, success, and error states on every data-driven screen. Evidence: driven with Playwright route interception on Home, Search, My Trips, Profile (loading/error/empty all reached), destination detail (error + not-found), map failure fallback; success is the normal audited render | PROJECT §10 |
| T-1006 | [x] Responsive pass for compact phones, large phones, tablets, and web preview with no horizontal overflow. Evidence: `documentElement.scrollWidth <= innerWidth` at 360/390/768/1024 on all 12 screens (0 failures); 125% and 200% root font-size checks show no real overflow or truncation | THEME §14, MAP §10 |
| T-1007 | [x] Filter the visual result through `anti-ai-slop` + `ui-design-principles` skills; remove decorative effects that reduce clarity. Evidence: no gradients/glass/glow; Inter retained because THEME §5 mandates it (documented conflict); removed the redundant Ionic calendar, author-supplied card labels, and in-content header/footer landmarks; kept the branded no-image plate, the dashed itinerary link, and the search prompt as functional | `.agents/skills/*` |

---

# Phase 11 — Verification and Delivery

| ID | Task | Source |
| --- | --- | --- |
| T-1101 | [x] Frontend unit tests (Vitest + Testing Library) for services, coordinate normalization, auth guard, and key screen states — 224 tests across 35 files | PROJECT §10 |
| T-1102 | [x] Playwright e2e: register, login, browse, search, create itinerary, reorder, delete — 11/11 passing against an isolated throwaway DB, Edge channel | PROJECT §12 |
| T-1103 | [x] `npm run lint` and `npm run build` clean; backend `pytest` green (89 passed) | repo scripts |
| T-1104 | [x] Android build verified on a physical device over LAN, including discovery and reconnection. Verified on a vivo V2126 (Android 14), phone 192.168.1.11 / PC 192.168.1.4: UDP discovery returned the server automatically with **no IP entry**, `/api/health` 200, and the app reconnected by itself after the server was stopped and restarted. Network-change reconnection (Wi-Fi → hotspot switch) still not exercised | SERVER §9.14 |
| T-1105 | [x] Verify no secrets committed: no `.env`, no DB file, no MapTiler key in source, no JWT secret defaults in production path — full sweep incl. git history; root `.env` gap found and fixed | MAP §4, §12; SERVER §5 |
| T-1106 | [x] Write run/verify documentation: server start, LAN/hotspot setup, firewall rules, env vars, MapTiler key restrictions — `docs/RUNBOOK.md` | SERVER §9.6, MAP §4 |

---

## Definition of Done (release gate)

- [x] Users can register and log in; sessions persist and survive app restart (e2e: register, re-login, session survives full reload).
- [x] Users can discover and search destinations, and destination details load from the API (e2e browse + search + detail).
- [x] Authenticated users can create, update, reorder, and delete their own itineraries (e2e journey).
- [x] Itinerary items preserve `visit_order`; reordering is transaction-safe (e2e asserts order after reload; backend rollback test).
- [x] Unauthorized and cross-user itinerary operations are rejected (e2e ownership spec + backend 404-not-403 tests).
- [x] Data persists in SQLite; FK enforcement is on (backend persistence + PRAGMA tests).
- [x] Interactive map loads from real backend coordinates; invalid coordinates are handled safely (tiles rendered live; 2 coordinate-less rows skipped and disclosed).
- [x] Itinerary map reflects visit order and stays correct after edits (setData update, no map rebuild).
- [x] Map failures fall back to a usable list view (verified by aborting real MapTiler requests).
- [x] The Android app discovers the Windows FastAPI server automatically, reconnects after server restarts, and needs no manual IP entry — verified on a physical device (vivo V2126, Android 14). Network-change reconnection untested.
- [x] Connection failures produce clear states with a retry action (6-state machine, banner, retry, diagnostics).
- [x] UI follows THEME.md tokens, spacing, typography, and accessibility rules (audited: contrast 33→0, touch 31→0, focus 36→0).
- [x] API validation and error responses are consistent and non-sensitive (generic 401/404, no stack traces, no probing oracle).
- [x] Automated backend and frontend tests cover critical security and data-integrity behavior (89 backend + 224 frontend unit + 11 e2e).

## Explicitly Out of Scope (must not be presented as implemented)

Interactive turn-by-turn navigation, distance/route estimation, reviews and ratings, community
submissions, admin verification dashboard, favorites/bookmarks, offline destination caching,
push notifications, multi-day scheduling. — PROJECT §11

## Open Questions

1. **Target API path prefix collision** — `MAP.MD` uses `GET /api/destinations` while `PROJECT.MD`
   lists `GET /api/destinations`; confirm `API_PREFIX=/api` and no `/api/api` duplication.
2. **Publication policy** — decide whether `verification_status` values (`verified`, `pending`,
   `unverified`) gate discoverability or only drive badges.
3. **Discovery plugin** — build a custom Capacitor Android plugin vs. adopt a community UDP plugin;
   confirm multicast viability on the lowest target Android API.
4. **Token storage** — Capacitor Preferences vs. a secure-storage plugin for the JWT.
5. **MapTiler plan** — confirm whether routing is included or a separate provider is required
   before starting T-918.
6. **Seed data** — decide whether Phase 1 ships seeded sample destinations (clearly unverified)
   or an empty directory with fixtures used only in tests.
7. ~~**Python version**~~ — RESOLVED: target is Python 3.11+; `SERVER.MD` §2 amended to
   "Python 3.11+ (3.12+ recommended)". Backend is built and verified on 3.11.0.
8. **Android applicationId** — must be decided before T-001 can complete (the ID is baked into
   `build.gradle`, the Java package path, and `strings.xml`).

## Progress Log

| Date | Task | Result |
| --- | --- | --- |
| 2026-10-29 | T-101, T-102, T-103, T-104, T-109, T-110 | Backend init slice done. Smoke test green from both `server/` and repo root; `server/data/lakbay_lokal.db` created; FK pragma returns 1; prod-secret guard raises at import. Pinned: fastapi 0.115.6, uvicorn 0.34.0, SQLAlchemy 2.0.36, pydantic 2.10.4, pydantic-settings 2.7.0, PyJWT 2.10.1, pwdlib[argon2] 0.2.1, pytest 8.3.4, httpx 0.28.1. |
| 2026-10-29 | T-108 | `init_db()` created and wired into `create_app()`; destination seed deliberately not added (Open Question 6). |
| 2026-10-29 | T-001 | Platform added by the user; identity fix outstanding. |
| 2026-10-29 | T-105, T-106, T-107 | Four models implemented (`users`, `destinations`, `itineraries`, `itinerary_items`). Verified: 4 tables created, items read back ordered by `visit_order`, FK enforcement raises, duplicate `(itinerary_id, visit_order)` raises, `visit_order >= 1` CHECK raises, itinerary delete cascades to 0 items, deleting a referenced destination raises (RESTRICT). |
| 2026-10-29 | T-201 to T-207 | Auth API complete: register 201 (no `password_hash` in body), duplicate 409, short password 422, login 200 with bearer token, wrong password and unknown email both 401 with an identical message, `/me` 200 with token and 401 for missing/tampered/expired tokens, stored hash is `$argon2id$`. `email-validator==2.2.0` added to requirements. `/api/health` still 200. |
| 2026-10-29 | Config | `server/.env` created with a persisted 64-char `JWT_SECRET_KEY`; cross-process token decode verified. Without it the server minted an ephemeral per-process secret and every restart would invalidate sessions. File is gitignored. |
| 2026-10-29 | T-001 blocker | Gradle build required JDK 17; `JAVA_HOME` pointed at jdk-25 (class file major 69). Fixed by the user. `capacitor.settings.gradle` + `app/capacitor.build.gradle` are generated by `npx cap sync android` and are NOT gitignored — commit them so a fresh clone never hits the missing-script error. |
| 2026-10-29 | T-002 to T-006 | Design foundation shipped: 92 `--ll-*` tokens + 36 `--ion-color-*` mappings in `src/theme/variables.css`, `typography.css` scale, self-hosted `@fontsource/inter@5.3.0`, `.env.example`, `src/` folder contract, and 7 UI primitives in `src/components/ui/`. Verified: `npm run build` 0, `npm run lint` 0 warnings, `npm run test:unit` 1/1, zero raw hex outside `variables.css`, screenshot `.agents/theme-check.png` at 390x844 shows navy header + logo + wordmark + all four badge variants. |
| 2026-10-29 | T-301 to T-305, T-407 | Destinations API shipped: schema-level coordinate validation (range + both-or-neither), LIKE escaping (`100%` literal), case-insensitive search over name/description/address, case-insensitive category filter, deterministic ordering, correct `total`/`pages`, 404 for missing and non-public ids, `/categories` declared before `/{id}` so it is not swallowed. 30/30 fixture checks passed. **Publication policy decided:** `NON_PUBLIC_VERIFICATION_STATUSES = {"rejected", "archived"}` — `unverified` and `pending` stay visible per PROJECT §5.2. Real DB verified untouched by tests. |
| 2026-10-29 | T-401 to T-406 | Itineraries API shipped. 17/17 checks. Cross-user PATCH/DELETE return 404 (existence concealed), duplicate `visit_order`/`destination_id` and `visit_order=0` rejected 422 before any write, unknown and non-public destination ids return an indistinguishable 422 (no probing oracle), PATCH `items: []` clears while an absent `items` leaves them untouched (`model_fields_set`), rollback proven with a forced IntegrityError leaving items intact, delete cascades to 0 items and returns 204 with an empty body. `updated_at` set manually on item-only changes because `onupdate` does not fire for relationship mutations. Real DB SHA256 identical before/after. |
| 2026-10-29 | API surface | All 11 routes live and correctly ordered: `/api/health`, auth (3), destinations (3, `/categories` before `/{id}`), itineraries (4, `/me` before `/{id}`). |
| 2026-10-29 | T-501 to T-506 | Permanent pytest suite added: 58 tests (health 2, auth 16, destinations 17, itineraries 23). Harness uses a fresh temp SQLite file per test with FK pragma on, dependency overrides, and a session-scoped guard that hashes `server/data/lakbay_lokal.db` before/after and fails if it changed (guard itself proven to fire). Verified: superset run 58 passed twice consecutively, isolated `test_itineraries.py` 23 passed, two-file subset 40 passed, real DB hash unchanged. Backend now reports `pytest` green against a real suite instead of an empty one. |
| 2026-10-29 | T-601 to T-603, T-605, T-606 | Server-side discovery shipped. Response is exactly `{"api_port","server_id","service","version"}` — **no IP field by design**, so the client must use the UDP source address; advertising `127.0.0.1` to a remote device is structurally impossible. Oversized packets read at full length then rejected (a small buffer would silently truncate and hide them). Rate limit 5 replies/sec/source. `server_id` proven stable across two separate interpreters and overridable via settings. A held port produces a warning and the API keeps serving (`/api/health` still 200) — discovery failure never takes the server down. Suite now **89 passed** (58 existing + 31 new); discovery is disabled inside the test harness so it never binds 37020. Firewall PowerShell snippet documented (Private profile only), not executed. |
| 2026-10-29 | T-604 | mDNS deliberately deferred: no `zeroconf` dependency, README records the decision. UDP broadcast is the primary channel. |
| 2026-10-29 | T-607 | NOT STARTED, and not a JavaScript task: UDP broadcast requires a Capacitor Android plugin in Kotlin under `android/app`. Deferred to the native pass so it is not faked. |
| 2026-10-29 | T-001, T-607, T-611 | Android identity fixed to `ph.lakbaylokal.app` (verified via `aapt2 dump badging`: package name, app label, launchable activity). Java (not Kotlin) Capacitor plugin `LakbayDiscoveryPlugin` registered in `MainActivity`, compiled into both debug and release. Cleartext HTTP allowed in the **debug** source set only; release manifest has neither `usesCleartextTraffic` nor a network config. `grep io.ionic.starter` over `android/` (excluding build artifacts) = 0. APK builds: debug 5.3 MB. **Correction: this project needs JDK 21, not 17** — Capacitor 8.6.0 declares Java 21 source/target. |
| 2026-10-29 | T-608, T-609, T-610, T-612 | Connection layer shipped: 20 vitest tests. Health validation requires `200` + `status:"ok"` + `service:"lakbay-lokal"` (a wrong-service 200 is rejected), deterministic candidate ordering, cached endpoint re-validated before trust, bounded backoff (6 attempts, then `Unavailable`), monotonic generation counter cancelling stale in-flight attempts, network-change revalidation, `dispose()` leaving no listeners or timers. Web gets `Blocked` with an explicit "JavaScript cannot send UDP broadcast" message. Banner + diagnostics mounted in `App.tsx` so state is actually surfaced. Added `@capacitor/network` and `@capacitor/preferences`. |
| 2026-10-29 | T-701 to T-708 | Frontend foundations shipped: typed domain models (`short_description` on list items matches the server's validation alias), `api-client` with base URL resolved only from the connection service, typed `ApiError` handling string **and** 422-array `detail`, timeout+abort composition, 401 clearing the token, one-way dependency `AuthContext -> services -> api-client -> token.store` (no cycle), token persisted via Capacitor Preferences with session restore validated through `/api/me`, `AuthGuard` + `PublicOnlyRoute` with no redirect loop, `useDestinations`/`useItineraries` with in-flight de-duplication and abort safety, IonTabs shell with the connection banner above it, and all 12 routes wired behind guards. 10 placeholder pages carry `// TODO(T-80x)` markers for Phase 8. Verified: 42 vitest tests, build 0, lint 0 warnings, zero raw hex, zero hardcoded hosts outside test fixtures. |
| 2026-10-29 | T-802, T-803, T-801 | Auth screens shipped: login with generic 401 message (never reveals which field), distinct "server unreachable" message for network/not-connected, double-submit guard, focus moved to the first invalid field; register with server-matching validation (8-char minimum), 409 mapped to the email field with a Log-in link, 422 field paths mapped back onto inputs, and auto-login after registration (falling back to /login with a "please sign in" message if that fails); splash with 800ms minimum, 5s hard cap, single-navigation guard. `/` now routes to `/splash`. 67 vitest tests (25 new), build 0, lint 0 warnings, zero raw hex. Screenshots in `.agents/screens/`. |
| 2026-10-29 | T-610 follow-up (bugfix) | The connection banner was unreachable: Ionic's `.ion-page` is `position:absolute; inset:0` and painted over it. Proven with `elementFromPoint`, not assumed. Fixed by adding `.ll-app-frame` / `.ll-app-viewport` (own flex lane + relative viewport). Banner also reduced from 228px to 82px tall after removing a redundant, mid-word-truncated detail line and stopping `flex-wrap` from pushing Retry to its own row. Re-verified in a real browser: banner is the topmost element at three probe points. |
| 2026-10-29 | T-108 | `server/scripts/seed_dev.py` added: 10 synthetic destinations, idempotent, `--force` deletes only its own marked rows (name+category+address match) and refuses if a marker looks like real data, hard gate refuses unless `APP_ENV=development` (exit 2, no engine built). Public API now returns 9 rows (the `rejected` one stays hidden) across 5 categories; 2 of 3 coordinate-less rows are public so the map's missing-coordinate path is exercised. Backend suite still 89 passed. |
| 2026-10-29 | T-804, T-805, T-806 | Destination browsing shipped: `DestinationCard`, `DestinationImage` (null **and** load-failure both resolve to a branded tile with the `<img>` unmounted, so no broken-image icon), `CategoryFilter`, Explore (refresher, load-more, loading/empty/error), Search (300ms debounce that cancels and skips identical values, category chips with `aria-pressed`, idle vs no-results distinction, filters held in the URL so back/forward works), Detail (404 → not-found state, coordinates shown only when valid, "Location not available" otherwise, no fake map, Add to Itinerary → `/itineraries/new?destinationId=N`). 83 vitest tests (16 new), build 0, lint 0 warnings, zero raw hex, no horizontal overflow at 360/390/768/1024. Deleted three dead placeholder files (`Home.tsx`, old `SearchPage.tsx`, old `DestinationDetailPage.tsx`). |
| 2026-10-29 | Layout bugfix | Tab labels were clipped: the bar's `min-height` was 44+8=52px but icon+label+paddings need more. Raised to `touch-target + space-4` (61px measured) and halved the button padding. Verified in Edge: bar 783→844, no button overflows the viewport, all three labels legible. |
| 2026-10-29 | Verification note | Visual checks require `NODE_ENV=development` **and** `mode=development` when building, plus `VITE_API_BASE_URL` and a matching `CORS_ORIGINS` — `vite build` defaults `NODE_ENV=production`, so `import.meta.env.DEV` is false and the app stays in `Blocked` with no base URL. The shipped `dist` was rebuilt in production mode afterwards and confirmed to contain no `127.0.0.1:8000` string. |
| 2026-10-29 | T-807 to T-812 | Itinerary + profile screens shipped: My Trips (no client re-sorting, date omitted when null, pull-to-refresh), shared `ItineraryForm` for create/edit, `StopPicker` that disables already-added destinations (the server 422s on duplicates), reorder recomputing contiguous `visit_order` 1..N from the displayed order on every submit, edit sending the FULL items array and `items: []` when everything is removed, edits kept visible on PATCH failure instead of silently reverted, detail with numbered stops + delete confirmation stating the cascade, profile with no token in the DOM. 108 vitest tests (25 new), build 0, lint 0 warnings, zero raw hex, no horizontal overflow at 360/390/768/1024. T-812 verified already satisfied by the T-610 banner: it is a strip, not a modal, has Retry, and does not block cached data. |
| 2026-10-29 | API gap found | There is **no `GET /api/itineraries/{id}`** in SERVER §6, so detail and edit resolve the record from `GET /api/itineraries/me` and treat a missing id as not-found. Correct and leak-free, but it downloads the whole list to open one trip — add an owner-scoped `GET /api/itineraries/{id}` when the list grows. |
| 2026-10-29 | T-901 to T-904 | Map foundation shipped with `@maptiler/sdk@4.2.0`. **Tiles actually render** (verified in Edge: `style.json`, `tiles.json` and tile requests all 200; Philippines basemap visible, canvas 356x488, no overflow). Real bug found and fixed: the default globe style failed with `Shader compilation error` in `initHalo` despite 200s, which exercised the T-904 error box for real; switching to `projection: 'mercator'`, `space: false`, `halo: false` and the literal `streets-v4` style fixed it. 121 vitest tests (13 new), build 0, lint 0 warnings, zero raw hex. StrictMode double-mount handled via deferred `queueMicrotask` + cancelled flag so exactly one map is constructed. Attribution forced `compact: false` so it is never hidden. |
| 2026-10-29 | Secret-handling note | The MapTiler key **is** present in the built bundle, which is expected and required for a browser map (MAP §4). Mitigation is key restriction + quota on the MapTiler account, not removal. Verified: `dist/` is gitignored, `.env.local` is gitignored, and no tracked file contains the key. A sub-agent report claiming "key not found in dist" was measuring a build with the key blanked — do not rely on that claim. |
| 2026-10-29 | T-905 to T-908 | Markers + popups shipped. Coordinate swap lives in exactly one executable line (`src/lib/coordinates.ts:29`) — grep proves no other file reverses the pair. 7 markers for 7 valid destinations, 2 skipped and disclosed. Marker diffing by `Map<destinationId, Marker>` (add / `setLngLat` / remove) so refreshes never duplicate; popup content built with a React root and unmounted on close, so names cannot inject markup (XSS test passes). 150 vitest tests, build 0, lint 0 warnings, zero raw hex. |
| 2026-10-29 | Map UI bugfixes (found in screenshots, not in tests) | Three real defects the tests could not catch: (1) popup rendered with a full-width image and clipped text because `DestinationImage`'s `width:100%; aspect-ratio:16/9` beat the popup's sizing — fixed with a fixed-size thumb wrapper instead of escalating specificity; (2) popup height measured before layout, so the map eased to a wrong offset and the popup hung past the map edge — measurement deferred to `requestAnimationFrame`; (3) the skipped-locations notice was absolutely positioned over the map and covered open popups — moved into normal flow below the map. Popup width capped at 236px so it clears the right-hand control strip. |
| 2026-10-29 | Test-harness bugfix | One itinerary test failed intermittently in the full suite while passing alone. Root cause: Testing Library's 1000ms default async timeout is too tight for Ionic components with 26 files in parallel. Fixed at the source with `configure({ asyncUtilTimeout: 5000 })` in `setupTests.ts`, then verified green across 3+ consecutive full runs. Also worth noting: an earlier attempt put `findBy*/waitFor` inside a block comment, and the embedded `*/` terminated the comment and broke all 26 suites — comments in this repo must not contain `*/`. |
| 2026-10-29 | Known issue (T-910) | The zoom/compass control strip overlapped the popup's close button on the narrow temporary `/map` mount (356px wide). **RESOLVED in T-910** — controls are now docked below the map and measured as non-overlapping, so this line is kept only as history. Original note: placement was T-910's task per MAP §10 ("avoid placing controls over important labels or markers"). |
| 2026-10-29 | T-909, T-910, T-911 | Explore map shipped: Map/List segment held in the URL (?view=map|list), debounced search + category chips filtering BOTH views, loading/empty/error states, no map recreation on filter change and no refetch on view toggle. Controls are DOCKED BELOW the map instead of floating in a corner: a corner overlay was empirically intercepting marker clicks at the map edge, so placement changed with evidence rather than preference. With an open popup, controls, close button and attribution all measure as non-overlapping. T-911 verified against a REAL failure: Playwright page.route aborted every api.maptiler.com request, the page rewrote the URL to ?view=list and showed 9 usable destination cards plus a non-blocking notice and Retry map. 166 tests, build 0, lint 0 warnings, zero raw hex, no horizontal overflow at 360/390/768/1024. |
| 2026-10-29 | Popup regression (mine) | Capping the popup at 236px to dodge the old corner controls made MapTiler's close button clip the destination name (rendered as "Amihan Cov"). Once the controls moved below the map the cap was unnecessary: width restored to 300px and the name now reserves space for the close button. Verified in the browser. |
| 2026-10-29 | Test-harness bugfix 2 | Distinct from the async-utility timeout: vitest's own testTimeout was 5000ms and heavy Ionic form tests exceeded it roughly 1 run in 4 while passing in isolation. Raised testTimeout/hookTimeout to 20s in vite.config.ts with the reason documented. Confirmed green across 4 consecutive full runs. |
| 2026-10-29 | T-912, T-913, T-914 | Itinerary map shipped: GeoJSON LineString source + dashed layer on the EXISTING map instance (`setData` on change, never a rebuilt map), numbered markers driven by `visit_order` rather than array index, and unmapped stops skipped while their numbers stay reserved. **Gap decision: split the line into contiguous runs and drop single-point runs** — the only option that cannot imply stop 1 and stop 3 are neighbours, so 1-mapped → 2-null → 3-mapped draws no line at all. Disclaimer: "The dashed line links your stops in order. It only shows the sequence, not how to travel between them." A test scans body text plus every `aria-label` for the banned terms (route, driving, walking, directions, navigation, turn-by-turn, ETA, travel time, traffic) with word boundaries so "Beta Falls" does not false-positive on ETA. 187 tests (21 new), green twice, build 0, lint 0 warnings, zero raw hex. |
| 2026-10-29 | Stale copy fixed | `ItineraryDetailPage` still told users the map "opens a placeholder screen for now", which became false once T-912 landed. Replaced with the accurate consequence of the destructive action: "Deleting this trip also removes all of its stops." |
| 2026-10-29 | Deviations accepted | MapControls omitted on the itinerary map (it needs `DestinationListItem[]` fields the itinerary snapshot lacks; fabricating them just to enable a fit button was not worth it). Marker tap navigates to the destination instead of opening the richer popup, which satisfies MAP §3.4 without duplicating popup content. Line colour is read from `--ll-map-highlight` at layer creation because GL paint cannot resolve CSS variables. |
| 2026-10-29 | T-915, T-916, T-917, T-918 | Optional map features shipped. T-915: geolocation requested **only on activation**, with idle/requesting/granted/denied/timeout states, a distinct "you are here" marker, and a test proving no network call ever carries the coordinates (MAP §12). T-916: separate "find a place on the map" geocoding panel (350ms debounce, abort on change, no request on empty input) — probes showed the existing key **does** have Geocoding scope (HTTP 200). T-917: SDK `cluster: true` source with count circles and click-to-expand; gated to 40+ plottable destinations so the 9-destination dataset and the existing DOM-marker path are untouched. T-918: real routing — MapTiler Directions returns 404 on all four probe paths, so the adapter targets OSRM; with `VITE_ROUTING_PROVIDER=osrm` a real solid road path rendered over the dashed visual link (both OSRM calls HTTP 200), with a legend distinguishing them. Unconfigured and failing states both fall back to the dashed link with an honest note and no invented geometry. 224 tests (37 new), green twice, build 0, lint 0 warnings, zero raw hex. |
| 2026-10-29 | T-918 release risk | The default routing source is the **public OSRM demo server**, which has no SLA and is not meant for sustained production traffic. Routing is therefore real but not production-approved. Logged as **T-919**; the provider seam already accepts a keyed/self-hosted endpoint via env vars, so switching is configuration rather than a rewrite. |
| 2026-10-29 | Clustering tuning note | Clustering is count-gated at `CLUSTER_MIN_DESTINATIONS = 40`. That keeps the existing marker DOM path (and its tests) intact for the 9-destination seed, but a real dataset below 40 that is still visually crowded will not cluster until that constant is lowered. Lowering it is the single tuning point. |
| 2026-10-30 | T-915 to T-918 | Optional map enhancements shipped. T-915: activation-only geolocation with idle/requesting/granted/denied/unavailable/timeout states, a sky-blue "you are here" marker distinct from green pins, retry on every failure, and a test proving `fetch` is never called with the coordinates. T-916: separate "Find a place on the map" panel using MapTiler Geocoding (live probe HTTP 200, 5 results for Manila), 350ms debounce, abort-on-change, empty-query no-op, honest 403/429/no-results states, and a temporary gold pin. T-917: SDK `cluster: true` GeoJSON source + circle/count layers, cluster click zooms or lists at max zoom, individual points reuse the existing popup, and the DOM marker layer is not rendered in cluster mode (no duplicates); synthetic 60-point tests cover cluster config and 0/1/3 safety. T-918: optional OSRM adapter seam with `VITE_ROUTING_PROVIDER`/`VITE_ROUTING_API_KEY` documented in `.env.example`; unconfigured makes no request and shows the dashed-link note, failures fall back, partial legs are named, successful geometry renders as a solid sky line with a legend. MapTiler Directions probes returned 404 (public directions is beta-only), so it was not used. 224 vitest tests, green twice; build 0; lint 0 warnings; zero raw hex in map CSS. |
| 2026-10-30 | T-1001 to T-1007 | Design/accessibility/polish audit shipped with a reusable Playwright+axe harness (`.agents/audit/audit.mjs`, axe-core devDependency). Before: 51 axe (1 critical, 14 serious, 36 moderate), 33 contrast, 31 touch, 6 names (all shadow-DOM checker artifacts), 36 focus, 0 overflow. After: 1 axe (serious, map marker spacing), 0 contrast, 0 touch, 0 names, 0 focus, 0 overflow, 0 font-scale, 0 raw hex outside `variables.css`. Fixed: `user-scalable` removed; `--ll-text-secondary` darkened #64748B→#52647A (AA on muted/fallback surfaces); in-content `header`/`footer` landmarks demoted to `div`; tab bar wrapped in `<nav aria-label="Primary">`; card `aria-label`s replaced with stretched title links; 44px back-button targets and `::part(native):focus-visible` rings; 44px checkbox hit area with a check icon; native date input replaces `ion-datetime` (removes vendor critical/serious rules); map fit padding increased; redundant 20px spacing tokenised. Remaining serious: two geographically close Explore pins overlap at country-fit zoom (44×44 hit areas; centers 34px apart). Clustering is deliberately still gated at 40 to keep DOM-marker keyboard access for the 9-destination seed; lowering it would hide individual pins. Artefacts: `.agents/audit/before.json`, `after.json`, summaries, `.agents/screens/polish-*.png`. 224 vitest green twice; build and lint green. |
| 2026-10-30 | T-1102 + CRITICAL BUGFIX | Playwright e2e suite built: 6 specs (session, browse, itinerary, ownership, validation, map) over an ISOLATED throwaway database, Edge channel, both servers started by Playwright `webServer`. **11/11 passing**, green on repeated runs. It caught a ship-blocking defect: logging out grew the URL `/login?redirect=/login?redirect=...` until React aborted with "Maximum update depth exceeded" and the app froze. Root cause: the guarded area was mounted under a `/*` catch-all, which also matched `/login`, so AuthGuard kept re-rendering there and rewriting the redirect. Fixed by replacing the catch-all with explicit guarded prefixes (`/home`, `/search`, `/destinations/*`, `/itineraries/*`, `/profile`, `/map`) plus a guard in `AuthGuard` that refuses to build a redirect target from an auth route. The previously `test.fixme` logout spec now passes. |
| 2026-10-30 | T-1105 | Secret sweep PASS, including git history (every commit searched for the MapTiler key, a non-placeholder JWT secret, and private-key headers — none found). **Real gap fixed:** root `.env` was NOT gitignored, and neither were `.env.production` / `.env.development`, all of which Vite loads. Added `.env`, `.env.*`, `!.env.example`; verified with `git check-ignore`. One unavoidable exposure remains by design: the MapTiler key ships in the browser bundle (MAP §4), so the real control is account-side key restriction + quota. |
| 2026-10-30 | T-1106 | `docs/RUNBOOK.md` written (661 lines, 11 sections + verified-command appendix) plus a root `README.md`. Covers prerequisites (JDK 21, not 17), setup, loopback and LAN runs, firewall rules requiring elevation, UDP discovery semantics (no IP in the response), env var tables, MapTiler key restrictions, database and dev-only seeding, testing, Android build, and an explicit "known gaps" section. Commands were executed where runnable; firewall and release-signing commands are marked illustrative. |
| 2026-10-30 | Final gate | Frontend unit 224 passed; backend pytest 89 passed; e2e 11/11 passed; `npm run lint` clean; `npm run build` clean. Definition of Done: **13 of 14 items verified**. The outstanding item is Android LAN discovery/reconnection (T-1104), which requires a physical device and is deliberately left unchecked. |
| 2026-10-30 | T-1104 VERIFIED (physical device) | The Android app works end to end on a real phone (vivo V2126, Android 14). Two real blockers were found by reading logcat instead of guessing: (1) **Mixed Content** — Capacitor serves the WebView from `https://localhost`, so every call to the discovered `http://192.168.1.4:8000` was blocked by the WebView security policy before it reached the network; fixed with `server: { androidScheme: "http", cleartext: true }` in `capacitor.config.ts` (the same solution the sibling `regigo` project uses). The Android manifest cleartext allowance alone is NOT enough — the block happens inside the WebView. (2) **CORS** — with the WebView now on `http://localhost`, the server rejected the origin; Capacitor WebView origins (`http://localhost`, `https://localhost`, `capacitor://localhost`) were missing from `CORS_ORIGINS`. Added them to the config default, `server/.env` and `.env.example`. Discovery itself was working the whole time and was never the problem. |
| 2026-10-30 | Discovery evidence (why this matters) | Packet capture on the host showed real broadcast requests arriving from 192.168.1.11, and the device log showed `{"servers":[{"host":"192.168.1.4","serverId":"fafa01ed...","apiPort":8000}]}` — automatic discovery with zero IP entry. The failure was always the follow-up HTTP call, not discovery. Lesson recorded: read logcat for `Capacitor/Console` before changing network code. |
| 2026-10-30 | Emulator (still partial) | The emulator reaches the host only through QEMU NAT. Discovery targets now include `10.0.2.2` and `10.0.3.2`, but replies arrive with source address `127.0.0.1`, which resolves inside the emulator, so the health call still fails there. Logged as T-922; the physical device is the supported path. |
| 2026-10-30 | Seed data replaced with REAL places | The previous seed set was fictional (Amihan Cove, Talon ng Bulan, ...) and every `image_url` pointed at the unreachable `example.test`, so every card fell back to a letter tile. Replaced with **12 real Philippine destinations** whose names, addresses and coordinates were pulled from the English Wikipedia API (`prop=coordinates`), and whose photos are the Wikipedia lead images downloaded locally into `public/seed/` so cards still render with no internet on a LAN. Categories now cover Nature, Beach, Heritage and Food. Old fictional rows deleted from the dev DB (10 rows), 12 real rows seeded. Attribution and per-image licence sourcing recorded in `public/seed/ATTRIBUTION.md`. Seed script docstring corrected: `verification_status` is DEV data only and is not a claim that any place was officially verified. Verified on the physical device: Explore shows the real Banaue photo. Backend 89 passed, frontend 224 passed. |
| 2026-11-04 | T-920, T-921, T-923 | Session restore now waits for a usable endpoint instead of discarding a valid token on `not_connected` (15s bounded wait, only 401 clears). Itinerary detail is invalidated per-id after a PATCH, so a saved edit is visible without a reload. Road routing is ON by default: the itinerary map draws real road-following geometry as a solid line over the dashed sequence link, with `VITE_ROUTING_PROVIDER=none` as the opt-out. 249 frontend tests, build and lint green. |
| 2026-11-04 | T-922 | Emulator discovery fixed. Diagnosis: packets reached the host but the reply source was `127.0.0.1`, which resolves inside the emulator. Also discovered that sending broadcast + loopback + host aliases from one socket makes QEMU drop the reply, so targets are now split per device type (AVD -> `10.0.2.2` only, Genymotion -> `10.0.3.2` only) and loopback sources are rewritten on emulators. Verified: logcat shows `host":"10.0.2.2"` and the server logged `GET /api/health 200`. Physical device path untouched. |
| 2026-11-04 | T-924 | Password recovery and profile editing shipped. `PATCH /auth/me`, `POST /auth/change-password`, `POST /auth/forgot-password` (202 with one fixed body for known and unknown emails), `POST /auth/reset-password`. Reset tokens are stored as SHA-256 hashes only, single-use, expiring, and previous unused tokens are invalidated on each request. New `/forgot-password` and `/reset-password` screens plus profile name edit and change-password sections. Verified live end to end: forgot 202 -> reset 204 -> new password logs in 200 -> old password 401 -> token reuse 400. Backend 104 tests, frontend 249. |
| 2026-11-04 | Environment restored | `server/.venv` and `server/.env` had been deleted (the dev database was wiped with them). Recreated the venv, regenerated a 64-char `JWT_SECRET_KEY`, copied the SMTP settings into `server/.env` (gitignored), re-seeded the 12 real destinations, and recreated the test account `lakbay.tester@gmail.com`. |
| 2026-11-04 | Revision R1 | Province-first model shipped. Backend: `provinces` table, `province_id` on destinations and itineraries, province API, and province-locked validation that rejects a stop from another province with 422 on both create and patch. Data replaced with 3 real provinces and 15 real spots (Bohol 4, Cebu 7, Palawan 4) whose coordinates come from Wikipedia and whose photos are bundled locally. UI: Provinces home, province page with hero + category chips + Map/List toggle, province-scoped itinerary picker, province shown on itinerary detail and cards. Demo mode and the e2e suite were rewritten to the province flow. Backend 117 tests, frontend 262, e2e 11, build and lint clean. |
| 2026-11-04 | R1 data note | Two candidate spots were dropped instead of faked: Loboc River (Wikipedia lead image is a 3x2 placeholder) and Puerto Princesa city (repeated 429). Restaurants and night markets are represented by what is verifiable (Carbon Market, Cebu); if the client wants specific restaurants or night markets pinned, real photos and coordinates must be supplied. |
| 2026-11-06 | Map regression fix | The province map showed "MapTiler key was rejected" on the device. Cause: the mixed-content fix had switched `androidScheme` to `http`, changing the WebView origin to `http://localhost`, which the MapTiler key no longer accepted. Reverted to Capacitor's default `https://localhost` origin and unblocked the plain-HTTP API with `android.allowMixedContent` instead. Tiles and API calls both work from the previously-working origin; the debug-only network security config still governs cleartext, so release builds are unaffected. |

---

# Revision R1 — Province-first browsing (client request)

> Client feedback after the presentation: "at least 2-3 provinces, with spots you can visit, pinned like Waze.
> Enter Bohol -> what is famous in Bohol (night market, white sand beach resort, famous resto) -> build an
> itinerary from there." Itineraries are **province-locked**.

| ID | Task | Status |
| --- | --- | --- |
| R1-01 | Province entity + `province_id` FK on destinations and itineraries | [x] |
| R1-02 | Province API (`GET /api/provinces`, `GET /api/provinces/{id}`, `destinations?province_id=`) | [x] |
| R1-03 | Province-locked validation: mixed-province stops rejected with 422 on create AND patch | [x] |
| R1-04 | 3 provinces / 15 real spots with real coordinates and bundled photos (Bohol 4, Cebu 7, Palawan 4) | [x] |
| R1-05 | Provinces home + province page (hero, category chips, Map/List toggle) | [x] |
| R1-06 | Province-scoped itinerary create/edit picker; province shown on detail and cards | [x] |
| R1-07 | Demo mode rewritten province-first (offline APK still works) | [x] |
| R1-08 | e2e suite updated to the province flow (11 passing) | [x] |
| R1-09 | `reset_dev_db.py` (development-only) because `create_all` cannot add columns | [x] |
| R1-10 | `/map` is still a GLOBAL cross-province map; `/search` stays global by design | open |

**New categories in use:** `Beach & Resort`, `Nature`, `Heritage`, `Attraction`, `Market & Food`.
