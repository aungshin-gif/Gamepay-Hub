# GamePay Hub: project notes for Claude

A digital-products store (AI tools, streaming, VPN, game top-ups) for Myanmar customers.
Static site on **GitHub Pages** + **Supabase** backend. Domain: `gamepayhub.shop` (DNS at Hostinger).
The owner works in Burmese, mostly from phone screenshots, and "vibe codes" (cares about the
mental model and the result, not syntax).

## How to work with the owner
- Reply in **Burmese**, in a mentor / co-founder tone. Explain the *why*. Do not dump huge files.
- Flag edge cases, security risks and breaking changes. Never invent APIs or endpoints; if a doc
  or schema is needed, ask.
- Visual changes: say what you checked and **what you could not check** (real-device look,
  frame rate). Test in Playwright and look at screenshots before reporting.
- When the owner sends several corrections, do them together in one commit.
- **Never ask the owner to paste secrets** (Resend API key, service keys) into chat.

## Git / release workflow
- Work on the branch the session assigns, commit with a clear message, push with `git push -u origin <branch>`.
- **Do not open a PR unless the owner says "Pr"** (or asks for one). Then open it into **`mainu`**.
  The owner merges it; GitHub Pages deploys from **`mainu`** (`.github/workflows/jekyll-gh-pages.yml`), about 1 minute later.
  (`static.yml` also exists but only triggers on a `main` branch, which this repo does not use.)
- After a PR is merged, restart the branch from the latest base before more work:
  `git fetch origin mainu && git checkout -B <branch> origin/mainu`. Check for unmerged commits first
  (`git log origin/mainu..HEAD`); an earlier reset dropped commits twice.
- A PR that was merged cannot take new commits: follow-up work needs a new PR.
- PR descriptions: what changed, testing, not verified. A PR can be merged within seconds of being opened.

## Files
| File | What it is |
|---|---|
| `index.html` (~8.6k lines) | The whole customer site: markup, product catalog (JS objects), all logic |
| `styles.css` | Customer styles (many appended override blocks; later rules win) |
| `shinpayhubcld.html` + `admin.css` | Admin dashboard. **Bump `admin.css?v=N`** in the `<link>` whenever admin.css changes |
| `supabase/schema.sql` | Full schema; keep it in sync with the live database |
| `supabase/migrations/*.sql` | One file per DB change (date-prefixed) |
| `supabase/email-templates/` | Branded Confirm-signup / Reset-password emails (pasted into Supabase by the owner) |
| `assets/` | Flat folder of logos and images |

## Design language
"Soft lavender glassmorphism with violet accents": white / pale lavender pages, frosted-glass cards,
rounded 14 to 22px corners, soft purple shadows.
Palette: Royal violet `#6231c8` (buttons, links), Amethyst `#7a35c7`, Orchid `#a87ce0`, Lavender mist `#efe7ff` / `#f4f0fa`,
page tint `#f6f3fd`, border `#e3d9f6`, ink `#2a1a55`, muted `#7d7390`.
Mobile first: at ≤767px the top header is hidden and a floating glass bottom nav (Store / Orders / News / Account) is used.

## Adding a new product (all six steps, or ordering breaks)
1. Product object in `index.html` (`name`, `category`, `plans[]`, optional `benefits` box using the `ICONS` map).
   Plan fields: `name`, `label`, `type`, `tier`, `duration`, `price`, `ownMail`, `warranty`, `format`, `note`.
2. Rows in the **live** `public.catalog_plans` table.
3. The same rows in the `supabase/schema.sql` seed.
4. A migration file in `supabase/migrations/`.
5. A line in `CATALOG_MANIFEST` in `shinpayhubcld.html` (one-line compact JSON).
6. The logo in `assets/` (flat folder).

`create_order` prices orders **on the server** from `catalog_plans`, looked up by `plan_name`.
The name must match `index.html` **character for character** (en dash `–`, and it embeds the price).
Tier badge colours live in `.plan-tier-badge[data-tier=...]` and `#orderView .plan-option[data-tier=...]`;
`TIER_LABEL` exists in two places.

## Backend (Supabase, project ref `sekntmukqliznwilsxox`, Free plan)
- Orders require a logged-in account: client gate `requireLoginFor()` plus a server-side guard inside `create_order`.
- Customers read their own rows by RLS; admins via `is_admin()`. Many RPCs are `SECURITY DEFINER`; `admin_*` functions check `is_admin()` inside.
- **Applying SQL**: the Supabase MCP `apply_migration` / `DELETE` calls have been cancelled before. Give the owner the SQL to paste in the SQL Editor, then verify with a read-only query.
- Email: Supabase Auth custom SMTP through **Resend** (sender `hello@gamepayhub.shop`), DKIM/SPF verified, DMARC `p=none`. OTP length is 6; templates use `{{ .Token }}`, `{{ .ConfirmationURL }}`, `{{ .Email }}`.
  The Gmail sender avatar cannot be changed without BIMI (needs DMARC enforcement and a VMC/CMC certificate).
- Storage: public `chat-images` bucket (customers upload under `<user id>/`, admins under `admin/`, 8MB).
- Chat messages including passwords are stored as plain text (RLS limits who can read them). Suggest customers change the password after receiving an account.

## Behaviours that were hard-won (do not undo)
- **Public data is read through `supabasePublic`** (no saved session): `stock_overrides`, `product_overrides`, `hero_banners`, `news_posts`.
  `gphFetch` gives API calls a 10s limit (uploads excluded) and `gphAuthLock` waits at most 3s for the auth lock.
  Without these, one stalled token refresh on a phone froze every request (skeleton cards forever).
- **Auth popups** ("Check your email!", password-reset "Enter code") are remembered for 8 minutes (`gph_pending_auth` in localStorage), so leaving to read the email and returning reopens the right step. Closing with X clears it.
- **Order tracking, Order journey box** has three phases (`data-phase`): `track` (stepper), `count` (30s digital countdown, `JOURNEY_COUNTDOWN_MS`),
  `chat` (a hand-off card with "Open order chat"). The completion time is stored per order (`gph_order_done_<token>`); orders completed earlier skip the countdown.
- **Order chat** supports images both ways (`messages.image_url`, migration `20261011_order_chat_images.sql`; text still works without it).
  The admin "template" button sends `[Account details]` + `Label: value` lines; **only admin messages** are drawn as a card with a copy button per line.
- Signup: the submit button goes busy and ignores repeat taps (repeat taps used to trip the email rate limit).
- Mobile "My account" for guests opens the login modal.

## Intro animation (first visit of a session)
SVG line-art logo on a plain white page, drawn by CSS animation (no images, no WebGL): ~11.2s, then fades into the site. The strokes draw slowly (about 5s; the owner likes this speed), the d-pad pops in, the title is fully in at ~8.2s and then **holds for about 3s** (the owner first asked for 4s, then set it back to 3s). Timings live in `styles.css` (`--dl` / `--dur`, `ilText`) and the `setTimeout(leave, ...)` in `index.html`; keep them in step.
Shown once per browser session (`sessionStorage gph_intro_seen`); `?intro=1` forces it; tap or any key skips; skipped for
reduced-motion and data-saver; hard failsafe removes it at 16s.
The owner's design requirements: **white background**; **soft purple glass, semi-3D** (not fully 3D) strokes; the arrow points **up and to the right**;
the **H leans left toward the G** and is larger; the G's inner arm hooks **down**; the **four d-pad buttons** are detailed glossy glass buttons placed high next to the arrow.
Each stroke is seven stacked layers (depth, rim, glass, inner light, core, broad + crisp highlight) for a crisp UHD glass look.
Earlier attempts the owner rejected: marbled liquid paint, dew drops / bubbles, colourful gradients, a raster logo.

## Testing (nothing in the repo; set up in the scratchpad)
- Serve with `python3 -m http.server 8123` (it dies between commands; restart it inline).
- Playwright is in `/opt/node-tools`, Chromium at `/opt/pw-browsers/chromium`. Stub `**/supabase-js@2` with a fake client for UI tests;
  for real-library behaviour (timeouts, locks) `npm install @supabase/supabase-js` into a scratch folder and serve its `dist/umd/supabase.js`.
- The sandbox cannot reach Supabase or `gamepayhub.shop`. Use the Supabase MCP tools (read-only SQL, logs, advisors) for the live database.
- Animations: seek with `document.getAnimations()` (`pause()` + `currentTime`) to take deterministic frames.

## Gotchas
- A global `button { color }` rule can beat component styles: use `!important` on text colour inside custom buttons (it bit the chat button and copy buttons).
- SVG gradients with `objectBoundingBox` units vanish on perfectly vertical or horizontal strokes (zero-size box): use `gradientUnits="userSpaceOnUse"`.
- `font:` shorthand with `inherit` as the family is invalid and drops the whole declaration.
- Strict GLSL ES 1.00 rejects float-vs-int comparisons (`x<1` must be `x<1.`).
- `@supabase/supabase-js@2` is loaded **unpinned** from the CDN; pinning a version is a worthwhile follow-up.
- Leaked-password protection needs the Supabase Pro plan, so it is off.

## Order slip (receipt-printer preview)
The preview opens at the top of the page (`window.scrollTo(0,0)` in the Review Order handler). The slip paper is a layered CSS texture.
Printer sound is synthesised with Web Audio (no files), starts only from the customer's own tap, stops on leave / background tab, and a speaker button
mutes it per device (`gph_slip_sound` = `0`). It is on by default.
