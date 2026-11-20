# LAKBAY LOKAL — Client Revision Requests

> Recorded after the review with the client. These are **requests**, not implemented behaviour.
> Nothing below is in the app yet unless the Status column says so.

| ID | Revision | Status |
| --- | --- | --- |
| R-01 | Create Account: separate First name, Middle name, Last name, Suffix | **Done** |
| R-02 | Only Restaurant, Hotel and Municipality spot types can be added to an itinerary (for testing) | **Done** |
| R-03 | UI polish: a more formal look, less "too simple" | **Done** |
| R-04 | Search a specific place inside a province and add it to the itinerary | **Done — both A and B** |
| R-05 | Modern travel-app layout (reference design), keeping the hamburger menu | **Done** |

---

## R-01 — Create Account name fields

**Client request.** The registration form should collect First name, Middle name, Last name, and Suffix
(optional) instead of a single Name field.

**Current state.**
- `users.name` is one `String(255)` column — `server/app/models/user.py`.
- Registration accepts `{ name, email, password }` — `server/app/schemas/user.py`.
- The UI has one "Name" input — `src/pages/auth/RegisterPage.tsx`.
- The display name is used in the profile, comment authors, and itinerary ownership views.

**Proposed change.**
1. Data model — add, keeping the existing column for compatibility:

   | Column | Type | Required |
   | --- | --- | --- |
   | `first_name` | String(100) | yes |
   | `middle_name` | String(100) | no |
   | `last_name` | String(100) | yes |
   | `suffix` | String(20) | no (Jr., Sr., III, IV, ...) |

   Keep `name` as the **computed display name** (`First [Middle] Last [Suffix]`) written on every
   create/update, so existing readers (comments, itinerary lists, `/auth/me`) keep working unchanged.

2. Migration: `create_all` **cannot add columns** to an existing table, and the dev database holds real
   accounts and trips. Use a small ALTER-based dev script (`ALTER TABLE users ADD COLUMN ...`), backfill from
   the current `name`, and only then make the new columns non-null. **No database reset.**

3. API:
   - `POST /api/auth/register` accepts `first_name`, `middle_name?`, `last_name`, `suffix?`.
     Keep accepting `name` temporarily and split it, so an old client does not break.
   - `PATCH /api/auth/me` accepts the same fields and recomputes `name`.
   - `UserRead` returns the individual fields **plus** the display `name`.

4. UI: four fields with sensible widths (First/Last side by side only if it stays readable at 360px),
   `Middle name (optional)` and `Suffix (optional)` clearly marked, correct `autoComplete` values
   (`given-name`, `additional-name`, `family-name`, `honorific-suffix`), and the profile page showing the
   same fields.

**Validation.** Each name part trimmed; reject blank first/last; allow letters, spaces, hyphens, periods and
apostrophes; suffix limited to a short allow-list plus a free-text fallback (max 20 chars).

**Implemented.** `server/scripts/migrate_user_names.py` (ALTER + backfill, idempotent, dev-only) ran on the dev database: 3 users before, 3 users after, 0 lost, all still able to log in. Display-name rule: space-separated parts, e.g. `Juan Dela Cruz Jr.`; a single-token legacy name keeps `last_name` NULL rather than duplicating the first name. Tests: backend 158, frontend 282.

**Acceptance criteria.**
- A new account created with all four fields shows "Juan Dela Cruz Jr." consistently everywhere.
- An account with no middle name and no suffix shows "Juan Dela Cruz".
- Existing accounts keep working and show their old name until edited.
- No database reset; existing trips and comments survive.

**Open questions for the client.**
- Is Middle name required or optional?
- Should Suffix be a dropdown (Jr., Sr., II, III, IV) or free text?
- Should users be able to change their name later from the Profile page? (Currently yes, name only.)

---

## R-02 — Itinerary limited to Restaurants, Hotels and Municipalities

**Client request.** On the province map, only **resto**, **hotel** and **municipality** entries should be
addable to an itinerary, for testing.

**Current state.**
- Destination categories in use: `Beach & Resort`, `Nature`, `Heritage`, `Attraction`, `Market & Food`.
- The itinerary picker offers **every** spot of the selected province.
- Server-side validation only enforces province membership (`server/app/services/itinerary_service.py`).

**Proposed change.**
1. Introduce three testing categories: `Restaurant`, `Hotel`, `Municipality`.
2. One source of truth for what is addable:

   ```python
   # server/app/core/config.py (or a constants module)
   ITINERARY_ADDABLE_CATEGORIES = {"Restaurant", "Hotel", "Municipality"}
   ```

   - `GET /api/destinations?addable=true` (or an `addable` field on each item) so the UI does not hardcode it.
   - `POST`/`PATCH /api/itineraries` reject a stop whose category is not addable, with `422` naming the ids.
3. UI: the `StopPicker` lists only addable spots and tells the user why the rest are hidden
   ("Only restaurants, hotels and municipalities can be added yet"). The province map and list still show
   everything, so browsing is not reduced.
4. Seed data: keep the existing 15 spots **and** add restaurant / hotel / municipality entries for Bohol,
   Cebu and Palawan so the testing flow has real options.

**Important.** This is a testing restriction, not a data model change. Making it a single constant means
relaxing it later is one line, not a refactor.

**Implemented.** `ITINERARY_ADDABLE_CATEGORIES = {"Restaurant", "Hotel", "Municipality"}`; destinations expose `addable`, `?addable=true` filters, create/PATCH return `422` `Destination ids not addable: 42`. Seeded 12 real entries (7 municipalities, 2 restaurants, 3 hotels) with OSM-verified coordinates and no invented photos. Picker shows only addable spots with the note "Only restaurants, hotels and municipalities can be added for now."; the province map still shows all 27.

**Acceptance criteria.**
- The picker shows only Restaurant, Hotel and Municipality spots.
- Posting a stop of another category via the API fails with `422`.
- The province map still shows all spots.
- Turning the constant off restores today's behaviour with no other edits.

**Open questions for the client.**
- Should "Municipality" be a destination record (a town entry) or a grouping level? If it is a destination,
  what does its detail page show?
- Should the hidden categories stay visible-but-disabled, or disappear from the picker entirely?
- Do they want restaurants and hotels seeded as **real** places (needs verified data and photos), or clearly
  labelled sample data for testing?

---

## R-03 — More formal UI

**Client request.** Make the interface look a little more formal; it currently reads as "too simple".

**Direction.** Keep the LAKBAY palette and warmth, but tighten the structure so it reads as a product rather
than a prototype. No new colours; no decorative noise.

**Concrete proposals.**
1. **Typography rhythm** — one consistent scale (display / h1 / h2 / h3 / body / caption) applied on every
   screen; tighten heading-to-body spacing so blocks group correctly.
2. **Section structure** — a small uppercase eyebrow label above each section heading, and a consistent
   divider treatment instead of ad-hoc gaps.
3. **Cards** — one border radius and one border colour everywhere; remove the mixed border/shadow usage;
   align image aspect ratios (16:9) so grids look deliberate.
4. **Forms** — label above field, helper text slot always reserved (no layout jump when an error appears),
   consistent field height, primary action full width on phones.
5. **Navigation** — quieter inactive tab labels, a clear active indicator, and a consistent page header
   (back + title) across detail screens.
6. **States** — the same loading / empty / error visual language everywhere, instead of per-screen variants.
7. **Density** — slightly more generous vertical rhythm on list screens; fewer competing elements per card.
8. **Micro-interaction** — restrained press/focus feedback only; everything respects
   `prefers-reduced-motion`.

**Acceptance criteria.**
- One review pass at 360px and 390px shows no screen that looks structurally different from the others.
- No raw colour values outside `src/theme/variables.css`.
- Contrast, focus and 44px targets remain compliant (the existing audit thresholds).
- Screenshots before/after for the main screens in `.agents/screens/`.

**Implemented.** Structural pass only, palette unchanged: shared `PageHeader`, `SectionHeading` (uppercase eyebrow + divider), `InlineMessage`, skeleton primitives, one card radius/border/elevation, 44px field height with a reserved helper slot, quieter inactive tabs with a sky active indicator, and one loading/empty/error language. 285 frontend tests, build and lint green, zero raw colours outside `variables.css`. Before/after screenshots in `.agents/screens/r3-before/` and `r3-after/` (390px and 360px).

**R-03b (second pass).** The first pass was structural only and the client saw "no difference" while reviewing at desktop width. The second pass added a real desktop composition: `.ll-page-shell` (max 1160px), a 64px app bar with in-app navigation, a display heading at 42px with a shared page title block, two-column heroes, two-column profile/create layouts, and cards with 16:9 images plus hover lift. Mobile keeps the tab bar. 285 tests, build, lint green; zero axe contrast violations at 390 and 1440; no overflow at 360/390/768/1024/1440. Screenshots in `.agents/screens/r3b-before/` and `r3b-after/`.

**Open question for the client.**
- Do they want the brand to stay warm/tropical (current), or shift toward a more corporate/formal look?
  This decides whether we only tighten structure or also re-balance the palette.

---

## Suggested order

1. **R-01** — smallest, self-contained, and it touches accounts, so do it before more test accounts exist.
2. **R-02** — unlocks the client's testing flow; needs a short answer on the Municipality question.
3. **R-03** — do last, so the polish pass covers the new form fields and the new picker at once.

## Impact summary

| Area | R-01 | R-02 | R-03 |
| --- | --- | --- | --- |
| Database | new user columns (ALTER, no reset) | none | none |
| Backend API | register / me / profile schemas | itinerary validation + a filter flag | none |
| Frontend | register + profile forms | stop picker + province hint | theme-wide pass |
| Tests | auth + profile suites | itinerary + picker suites | screenshot review |
| Risk | data migration on real accounts | low (one constant) | low (visual only) |

## Decisions needed before implementation

1. Middle name required or optional?
2. Suffix: dropdown or free text?
3. "Municipality" as a destination record, or a grouping level?
4. Restaurants/hotels: real verified places, or clearly labelled sample data?
5. Formal UI: keep the tropical palette, or shift toward corporate?
---

## R-04 — Search a specific place inside a province and add it to the itinerary

**Client request.** After choosing a province (e.g. Bohol), the user should be able to search for the **exact
place they want** - a particular restaurant, for example - and add *that* to the itinerary, not only the spots
the app already lists.

**Where search exists today (verified).**
- `PlaceSearch` (OpenStreetMap **Nominatim**) is mounted on **one screen only**: the Explore map at `/map`.
- The itinerary `StopPicker` searches **our own destination list** (the seeded spots of that province).
- `ProvincePage` has **no search field at all**.

So the flow the client describes **does not exist yet**.

**Why it is not a small change.** An itinerary stop currently stores `destination_id`, a foreign key to a row in
`destinations`. An arbitrary searched place has no row, so it cannot be a stop without either creating rows for
user searches or allowing a stop to carry its own name and coordinates.

**Two options.**

| | A. Private custom stop (recommended) | B. Promote to a shared destination |
| --- | --- | --- |
| How | `itinerary_items` gains nullable `place_name`, `place_address`, `latitude`, `longitude`; `destination_id` becomes nullable. Search Nominatim inside the province, "Add to itinerary" stores the place on that user's trip only. | A geocoded place becomes a `destinations` row (category `Place`) visible to everyone. |
| Data quality | No effect on the shared directory. | Every user search enters public data; needs moderation or it fills with typos and duplicates. |
| Effort | ALTER on `itinerary_items` + picker UI + validation. | New endpoint + moderation rules + duplicate detection. |
| Risk | Low, but the itinerary schema change needs a migration script (no reset). | High: public data becomes user-generated without a review flow. |
| Maps | The stop still gets a pin (it has coordinates). | Same, plus it appears in the province list for everyone. |

**Recommendation: A.** It matches "for testing" and does not pollute the shared directory.

**Also needed either way.**
1. A **search field on the province page**, scoped to that province's map viewport, so the user can find a place
   without leaving the province.
2. The **itinerary picker** gets two result groups: "Spots in <Province>" (the curated list) and
   "Other places (OpenStreetMap search)". The second group is what fulfils this request.
3. Add-to-itinerary from a search result creates the stop, shows it on the itinerary map, and keeps the
   province lock (a place outside the province is rejected).
4. Attribution: Nominatim results must credit OpenStreetMap, and the search must stay debounced and rate-limited.

**Acceptance criteria.**
- Inside Bohol, typing a restaurant name returns OSM results and one can be added to a Bohol trip.
- The added stop appears in the itinerary list and on the map with a pin.
- A place outside the province cannot be added.
- Curated spots keep working exactly as today.
- No database reset; existing trips survive.

**R-03b (second pass).** The first pass was structural only and the client saw "no difference" while reviewing at desktop width. The second pass added a real desktop composition: `.ll-page-shell` (max 1160px), a 64px app bar with in-app navigation, a display heading at 42px with a shared page title block, two-column heroes, two-column profile/create layouts, and cards with 16:9 images plus hover lift. Mobile keeps the tab bar. 285 tests, build, lint green; zero axe contrast violations at 390 and 1440; no overflow at 360/390/768/1024/1440. Screenshots in `.agents/screens/r3b-before/` and `r3b-after/`.

**Implemented — both A and B.** A: `itinerary_items` gained `place_name`, `place_address`, `latitude`, `longitude` and a nullable `destination_id` (table rebuilt inside one transaction; 3 itineraries / 8 items preserved). B: `POST /api/destinations` (auth) creates an `unverified` spot, rejecting out-of-province coordinates (422) and likely duplicates within ~50 m (409). Province bounds are a documented heuristic: min/max of the province's destinations plus 0.75 deg. Search lives on the province page and in the picker, with OSM attribution. Backend 189 tests, frontend 299.

**Known gap.** Path B defaults the new spot to category `Place`, which is NOT in the R-02 addable allow-list, so a saved spot appears in the directory but cannot be added to an itinerary. Decide: add `Place` to `ITINERARY_ADDABLE_CATEGORIES`, or let the user pick an addable category when saving.

**Original open question (answered by implementing both).**
- Option **A** (private stops, nothing added to the public directory) or option **B** (searched places become
  shared destinations everyone can see)?

---

## R-05 — Modern travel-app layout

**Client request.** Match the reference travel-app layout: big headings, rounded search pill, quick-action tiles,
horizontal image carousels, thumbnail list rows, soft elevation. Keep the hamburger menu; no bottom navigation.

**Implemented.**
- Tokens: `--ll-radius-2xl` 24, `--ll-surface-radius` 20, `--ll-thumb-radius` 16, `--ll-thumb-size` 88/96,
  `--ll-tile-size` 64, `--ll-hover-lift` -2px, and re-tuned `--ll-shadow-1/2/3` (palette-derived).
- One card recipe (white, radius 20, shadow-1, no hard border), one 88px-thumb row, one 4:3 carousel card.
- Provinces home: heading + search pill + region chips + six icon quick-actions + province carousel + recommended
  rows with "See all" section links.
- Province / destination detail / itineraries / profile: rounded surfaces, thumbnails, 52px primary pills.
- Header keeps the hamburger; desktop quick links are quiet pills. `ion-tab-bar` count is 0.
- 299 frontend tests, build and lint green, 0 raw colours outside `variables.css`, 0 axe contrast violations at
  390 and 1440. Screenshots in `.agents/screens/ref-before/` and `ref-after/`.

**Note.** The Explore map's control strip is still docked below the map; a corner overlay previously intercepted
marker taps and would cover the popup and attribution.