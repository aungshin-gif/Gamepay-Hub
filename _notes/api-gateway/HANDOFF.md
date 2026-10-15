# API Gateway project: handoff for the next AI session

Written 2026-10-15 at the end of a long chat. **Read this whole file before doing anything.**
Also read `/CLAUDE.md` (GamePay Hub store rules): everything there still applies (reply in Burmese,
mentor tone, no PR unless the owner says "Pr", never ask for secrets, etc.).

This file contains **no secrets** and must stay that way. Keys, passwords and admin usernames are held
by the owner only. If you need one, tell the owner *where to paste it themselves*; never ask them to
post it in chat.

---

## 1. Who the owner is and how to work with them

- Burmese speaker, "vibe coder": cares about the mental model and the result, not syntax.
- Works mostly from a **tablet/phone**, sends **screenshots**, types fast with typos. Read generously.
- **Reply in Burmese**, mentor / co-founder tone. Explain the *why*. One step at a time; do not dump
  huge walls of instructions. When they are stuck, shrink the task to **one action** and ask for a screenshot.
- They get frustrated when many things go wrong in a row (this happened: Railway errors, paste bugs).
  Acknowledge it in one line, then give the single next action.
- **Be honest about uncertainty.** Say "I can't see your screen / I haven't verified this" rather than guess.
  The owner explicitly asked for "precise answers"; label guesses as guesses.
- The Claude cloud sandbox **cannot reach** Railway, the Gateway, DeepSeek or gamepayhub.shop
  (WebFetch fails with ENOTFOUND). `WebSearch` works. You cannot click the owner's dashboards for them:
  give exact steps and let them do it.
- Owner pastes secrets into screenshots by accident. Warn politely ("crop/cover the key"), and
  recommend rotating anything that appeared in chat.

## 2. The two projects

| | Project A: GamePay Hub | Project B: API Gateway (this file) |
|---|---|---|
| What | Digital-products store for Myanmar customers | Own LLM API gateway to issue limited-quota API keys |
| Where | This repo (static site on GitHub Pages + Supabase) | Railway (no code in this repo) + notes here |
| Doc | `/CLAUDE.md` | this file |

They will be linked: Project B should get a **token-usage page** on the GamePay site (see section 7).

## 3. Goal of Project B (owner's words, condensed)

1. Run **their own gateway** (new-api) so *they* can mint API keys with per-key limits.
2. Use it for themselves: a chatbot, VS Code, Termux scripts.
3. **Team project**: give each member a key worth about **1M tokens of DeepSeek flash** as a giveaway.
4. **The owner decided NOT to resell** (after reading the compliance terms and upstream terms).
   Giveaway / own use only. Do not drift back to "selling tokens" without the owner raising it.
5. Build a **web page** on a new URL: user pastes their key, sees **limit, used, left**, picks a model.
6. Produce a **PDF book** about the whole journey so another vibe coder can clone it (see `BOOK_BRIEF.md`).

## 4. Current state (verified from the owner's screenshots on 2026-10-15)

### Infrastructure
- **Railway** project named `perceptive-laughter`, deployed from the community template
  **`new-api-template`** (railway.com/deploy/new-api-template). It runs three services:
  `new-api` (the gateway), `MySQL`, `Redis`, with volumes `new-api-volume` and `mysql-volume`.
- Railway account is on a **"Limited Trial: 30 days or $5.00"** banner. Usage is billed per use;
  three services may burn the $5 faster than a single VPS would. **Not yet verified**: monthly cost.
  A usage limit should be set in Railway.
- Gateway public URL (Railway-generated): `https://new-api-production-6f0d.up.railway.app`
  (the very first deployment used `...447a...`; it was deleted and redeployed after the owner
  lost the root password). Custom domain `api.gamepayhub.shop` is **planned, not done**
  (Railway "Custom Domain" + a CNAME at Hostinger DNS).
- Gateway software: **new-api** (QuantumNous), UI shows version `v1.0.0-rc.44`. License AGPL-3.0.

### Gateway configuration
- Setup wizard done: usage mode **External operations** (multi-user, billing and quota control).
- A **root admin** exists (credentials kept by the owner). Sidebar then shows an ADMIN section:
  Channels, Models, Users, Redemption Codes, Subscriptions, System Info, Task Plugins, System Settings.
- **Compliance terms confirmed** by the owner (System Settings -> Billing & Payment -> Payment Gateway).
  This unlocked redemption codes / payment / subscription / invitation rewards. The terms include:
  lawful authorization for upstream APIs/keys, no unauthorized resale or trafficking, owner bears all
  legal responsibility. (The confirm box needs 4 text fields typed exactly; a typo "deloyment" blocked it once.)
- **Channel**: type DeepSeek, name `DeepSeek`, Base URL left empty (built in), group `default`,
  Single Key mode, models fetched with *Fetch from Upstream*: `deepseek-flash`, `deepseek-v4-pro`.
- **Model pricing** (Models -> model -> Pricing tab -> **Expression** tab, Visual editor, tier `base`, per token, USD per 1M):
  - `deepseek-flash`: **Input 1.2 / Output 1.2** (uniform on purpose, see section 5)
  - `deepseek-v4-pro`: **Input 1.32 / Output 3.96** (DeepSeek peak prices)
  - Cache price fields left off (cache hits are billed at the normal input price: safer).
  - Do **not** use the "Per-token (deprecated)" tab.
  - Before pricing was set, unpriced models showed a placeholder **Input 75 / Output 75 USD per 1M**
    and Playground said "Model Price Not Configured".
- Quota unit: **$1 = 500,000 quota units**. The root user started with a large default balance
  ($200 shown; now $209.97 after the owner redeemed a $10 code to test redemption).
  That balance is an internal ledger number, **not real money**.
- Redemption code system tested: admin created a code ("Karinas", $10), redeemed it in Wallet. Works.
  "Online topup" (Epay/Stripe/...) is not configured and not needed.

### DeepSeek side (real money)
- Account topped up **$2.00** with the owner's Visa card (works from Myanmar). Balance about **$1.99**.
- "Balance alert" is **disabled** (should be enabled).
- Usage dashboard lags **up to 5 minutes**. Verified: Gateway and DeepSeek counts matched
  (3 requests / 1,239 tokens at the time of checking).
- Official DeepSeek prices seen on `api-docs.deepseek.com/quick_start/pricing` (USD per 1M tokens):

| | flash off-peak | flash **peak** | pro off-peak | pro **peak** |
|---|---|---|---|---|
| input, cache hit | 0.003 | 0.006 | 0.022 | 0.044 |
| input, cache miss | 0.15 | **0.3** | 0.66 | **1.32** |
| output | 0.6 | **1.2** | 1.98 | **3.96** |

  Off-peak is half of peak. Peak = 01:00-04:00 and 06:00-10:00 UTC, Mon-Fri, excluding Chinese
  public holidays (= 07:30-10:30 and 12:30-16:30 Myanmar time). Model name to use is `deepseek-flash`
  (legacy `deepseek-v4-flash` still accepted). flash defaults to **thinking mode**: reasoning tokens are
  billed as output (a "hi" used 35 completion tokens, 25 of them reasoning). Prices change; re-check the page.

### Tested end to end
- Gateway Playground (uses the logged-in session; **needs no API key**, which is why deleting the key did not stop it).
- Termux `curl` against `/v1/chat/completions` with a capped test key: worked, 66 tokens.
- A small **Python chat script that shells out to curl** (`chat.py`, full source in `BOOK_BRIEF.md`) works:
  67 tokens = $0.000080; 1,186 tokens = $0.001423, which matches 1.2 $/M. Plain Python `urllib` failed
  with `IncompleteRead` against the Railway edge; using `curl` fixed it.

## 5. Key concepts the owner now understands (keep explanations consistent)

Three limits stack; **the smallest wins**:

```
(1) DeepSeek real balance   <- the only real money, the true ceiling
(2) Gateway user balance    <- internal ledger per user (root = ~$200 default; admin can edit)
(3) Per-API-key quota       <- what we give each member
```

- Playground / UI uses the **user session** and spends the **user balance**. External apps use an
  **API key** and spend the key quota (and the user balance behind it).
- Gateway deducts at **our configured price**, not DeepSeek's. Quota = tokens x price. We price at
  DeepSeek's *peak* price so we never lose money; off-peak and cache hits leave a cushion.
- **"1M tokens" giveaway**: Gateway limits are in dollars. Setting flash input = output = 1.2 makes
  **quota $1.2 = exactly 1M tokens (input+output)**; $0.6 = 500K; $3.6 = 3M.
  Worst case real cost is $1.2 per 1M (all output, peak); typical is less. Downside: input-heavy users burn quota faster than true cost.
- Credit = a wallet so many users can share one upstream key without overspending. For one owner it is invisible.
- Per-member keys beat handing out the DeepSeek key: DeepSeek per-key spend caps were **not found**
  (unverified), the Gateway gives caps, revocation, per-key logs, and hides the upstream key.
- Without a Gateway the owner alone could just put the DeepSeek key straight into VS Code.
  The Gateway is worth it only for distributing limited access to others.

## 6. Create API Key form (seen 2026-10-15)

Fields: **Name**, **Group** (pick `default`), **Expiration Time** (Never / 1M / 1 Day / 1H / date),
**Quantity** (creates several keys with random suffixes), **Quota (USD)** (default 10 - change it!),
**Unlimited Quota** toggle (leave off), collapsed **Advanced Settings** (access restrictions; contents
**not yet inspected**, likely model limits and IP rules). For a 1M-token member key: Quota **1.2**,
model limit `deepseek-flash` only (so they cannot use the 3x pricier pro), optional expiry.
Member needs: Base URL `https://<gateway>/v1`, the key, model `deepseek-flash`.

## 7. Next steps, in priority order

1. **Security clean-up** (nothing leaks until these are done):
   - A DeepSeek key appeared in a screenshot early on. The owner said they re-created keys; **verify**
     on DeepSeek's API keys page that only the key used by the Channel remains (use the *Last used* column).
   - A Gateway test key (capped at $1.2) was pasted into chat. **Delete it** and issue real member keys fresh.
   - Check **System Settings -> Authentication**: disable open public sign-up if members do not need accounts
     (an accidental self sign-up once created a normal user "ID 2" instead of root).
   - Enable 2FA under "Security & Access" if available. Keep the root password in a password manager.
2. DeepSeek: **enable Balance alert**; top up before handing out keys (keys issued x $1.2 worst case must stay under the balance).
3. Check Gateway **Usage Logs** vs DeepSeek Usage match for a fresh test (was already matching once).
4. Inspect **Advanced Settings** on Create API Key; issue **one** member key, test it, then the rest.
5. Set a **Railway usage limit** and watch the $5 trial; decide Railway vs a small VPS (2 GB RAM is probably
   enough but new-api publishes no minimum; unverified).
6. Optional: custom domain `api.gamepayhub.shop`.
7. **Token usage page** (owner's wish): user enters their key, page shows limit / used / left, with a bar.
   - **Unverified and must be tested first**: whether new-api lets a plain API key read its own balance.
     Candidates seen only from memory, not confirmed: `GET /api/usage/token/` and
     `GET /v1/dashboard/billing/subscription` + `/v1/dashboard/billing/usage`. Give the owner a `curl` to try in Termux.
     Some gateways require an *admin* token for balance lookups; **never put an admin token in a public web page.**
   - If a per-key endpoint works, a static page on the GamePay site (GitHub Pages) can call it from the browser
     (check CORS). If it needs an admin token, the page needs a tiny server-side proxy instead (e.g. a Supabase Edge
     Function holding the secret). Use the GamePay design language (see `/CLAUDE.md`).
   - Owner idea: user picks a model, enters an "access key", and sees remaining quota decrease as they use it.
8. Other providers (OpenAI etc.) are possible as extra Channels. **Reselling/trading keys breaks OpenAI's
   Services Agreement** (sections about account resale and API-key trading); Myanmar was listed as a supported
   country when checked. Owner is not reselling, but still advise reading each provider's terms.
9. The PDF book: see `BOOK_BRIEF.md`.

## 8. Where to keep things (the owner asked "one repo or two?")

Recommendation given: keep the API-project notes **in this repo** (`_notes/api-gateway/`) because the
GamePay `CLAUDE.md` is auto-loaded by every session and the usage page will live on the same domain,
so relative links keep working. Two caveats:
- GitHub Pages publishes this whole repo from `mainu` (Jekyll, source `./`). Jekyll **skips folders that start with
  `_`**, so `_notes/` is not served on the website; the repo itself may still be public, so never commit secrets.
- Anything outside `_notes/` (including a `.md` in the root) is published. `/CLAUDE.md` itself is probably public already.
If the usage page grows into a real app (backend, build step), move it to its own repo/subdomain and keep notes here.

## 9. Mistakes and gotchas already hit (do not repeat)

- Pasted `cat > chat.py` into the **running** chat prompt (`You:`): it became chat input. Only paste at `~ $`.
- Termux single-line paste sometimes inserts `[200~ ... ~` and breaks the command: type short commands by hand.
- Plain Python `urllib` hit `IncompleteRead` on the Railway edge; shelling out to `curl` works.
- Compliance confirm box: four fields must match exactly; one-letter typo blocks it.
- Logging in with **Sign up** instead of **Login** created a normal user (ID 2) and hid the ADMIN menu.
- Deploying a deleted project's old `/new/template/...` URL gives Railway's "Oh No! the train derailed"; start fresh from the dashboard.
- Saving `Input 0 / Output 0` would make a model free. Never save a pricing form with zeros.
- Do not save pricing from the deprecated Per-token tab (its Completion price toggle is off and shows default $15).
- Asking the AI inside chat "how do I switch models?" does nothing; model is set by the client (`MODEL` in `chat.py`, or the model picker).
- Quota in `chat.py` cost line is hard-coded 1.2 and wrong for the pro model.

## 10. Open questions for the owner (ask once, early)

- Did they already delete the old DeepSeek key and the Gateway test key?
- How many team members, and what quota each (300K / 500K / 1M)?
- Railway trial vs staying on Railway after the trial?
- Which "template" meaning for the book (Railway template, prompt templates, CLAUDE.md memory file, or all)?
