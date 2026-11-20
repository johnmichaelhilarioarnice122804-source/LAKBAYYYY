# LAKBAY LOKAL

LAKBAY LOKAL is a community-focused local tourism directory and itinerary planner.
Users discover verified local destinations, explore them on a map, and build ordered
travel itineraries. The client is an Ionic React app packaged for Android with
Capacitor; the backend is a local FastAPI + SQLite server that the phone discovers on
the same Wi-Fi or hotspot.

## Start here

- **[docs/RUNBOOK.md](docs/RUNBOOK.md)** — prerequisites, first-time setup, running
  locally and on a LAN, Windows Firewall rules, automatic discovery, environment
  variables, MapTiler key restrictions, database seeding, testing, and the Android
  build. **Read this first if you want to run the project.**
- [docs/PROJECT.MD](docs/PROJECT.MD) — product scope and requirements.
- [docs/SERVER.MD](docs/SERVER.MD) — backend API, networking, discovery, and security.
- [docs/MAP.MD](docs/MAP.MD) — map integration, MapTiler usage, and coordinates.
- [docs/THEME.MD](docs/THEME.MD) — design tokens and UI conventions.
- [e2e/README.md](e2e/README.md) — Playwright end-to-end suite details.

## Quick orientation

| Path | What it is |
| --- | --- |
| `src/` | Ionic React + TypeScript frontend |
| `server/` | FastAPI backend, SQLAlchemy models, SQLite database, tests |
| `android/` | Capacitor Android project |
| `e2e/` | Playwright end-to-end tests |
| `docs/` | Project, server, map, theme, and runbook documentation |

## Requirements at a glance

- Node.js 22+ and npm
- Python 3.11+
- JDK 21+ for the Android build (**not** JDK 17)
- Android SDK (compileSdk 36)
- A MapTiler account and public map key for the map UI

## Run in one screen

```powershell
# frontend dependencies
npm install

# backend (from server/)
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements.txt
.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000

# frontend (from the repository root, in another terminal)
npm run dev
```

The API is at `http://127.0.0.1:8000/api`, Swagger UI at
`http://127.0.0.1:8000/docs`, and the web app at `http://localhost:5173`.

For a physical Android device, bind the backend to `0.0.0.0`, open Windows Firewall
for TCP 8000 and UDP 37020 on the Private profile, and make sure both devices are on
the same network. See the runbook for the exact commands and their limitations.

## Status

The backend and frontend test suites pass. The Android debug build works. Physical
device discovery/reconnection is **not yet proven**, mDNS is not implemented, the
public OSRM demo routing server is not production-approved, and the e2e suite is
mid-refactor. See [Known gaps](docs/RUNBOOK.md#11-known-gaps--not-yet-done) for the
honest list before release.
