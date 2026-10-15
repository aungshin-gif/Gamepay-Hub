# Brief: the PDF book about the API Gateway project

For the next AI session. The owner wants a **paid-book-quality PDF in Burmese** that teaches another
"vibe coder" to build the same thing. Read `HANDOFF.md` first (facts live there; this file is the spec).

**Do not invent facts.** Every number/step must come from `HANDOFF.md`, this file, or something you
verify. Mark anything unverified as "မစစ်ရသေးပါ (unverified)" in the book. Never include a real key,
password, admin username or screenshot with a key.

## 1. Reader and promise

- Reader: a Burmese vibe coder who has never run a server. Mental models first, jargon explained on first use.
- Promise: after reading, they can **clone this project**: own LLM gateway on Railway, DeepSeek connected,
  per-member keys with limits, correct pricing math, safe habits, and a usage page.
- Tone: friendly mentor ("co-founder"), honest about mistakes. Short paragraphs, many callout boxes.

## 2. What the owner asked the book to contain

1. How the owner started this project.
2. Which **platforms** were used (and why each one).
3. **How the owner instructed Claude** (the working method; real prompts and screenshots-first habit; see section 4).
4. **Templates** that were written for them, and **what a "template" is**. (Ask the owner which meaning,
   or cover all four: Railway one-click template, the new-api pricing presets/templates, prompt templates,
   and `CLAUDE.md`/`HANDOFF.md` as a "memory template" for AI sessions.)
5. Possible **security errors** and things to watch for.
6. **Pricing / credit math** (how to compute prices and quotas).
7. **How to add models and how to buy model access** (DeepSeek top-up, OpenAI notes, aggregators, Channel form).
8. A complete, ordered **clone guide**, plus **troubleshooting** table, **glossary**, **checklists**.

## 3. Visual design (important to the owner)

"UI: tables, graphs, soft + bright colour tones, like a paid book."

- Reuse the GamePay language: soft lavender glassmorphism, violet accents.
  Palette: royal violet `#6231c8`, amethyst `#7a35c7`, orchid `#a87ce0`, lavender mist `#efe7ff` / `#f4f0fa`,
  page tint `#f6f3fd`, border `#e3d9f6`, ink `#2a1a55`, muted `#7d7390`. Add 2-3 bright accents
  (mint `#2fbe8c`, amber `#f2a93b`, coral `#e2568c`) for status/graph series only.
- Cover page, table of contents, **chapter opener pages** (big number + one-line promise), running header/footer with page numbers.
- Components: callout boxes (Tip, Warning, Mistake we made, Why), numbered step cards, **comparison tables**,
  flow/architecture diagrams (inline SVG), **graphs** (inline SVG or Chart.js rendered to PNG): see section 5 for required graphs.
- Rounded corners 14-22 px, soft purple shadows, generous whitespace, no dense walls of text.
- Page size A5 or 6x9 in "book" feel (or A4 if tables need it). Keep code blocks readable (monospace, light background).

## 4. How the owner worked with Claude (use as the "method" chapter)

Real pattern across the project (use anonymised examples, no secrets):
- Owner sends **screenshots** instead of describing; Claude reads them and gives **one next action**.
- Owner asks "why / how does it work" questions mid-task; Claude answers with a small diagram first, then steps.
- Owner pushes back ("I don't understand your calculation"); Claude re-explains with a simpler analogy (bus-fare style, worked numbers).
- Owner makes product decisions (decided **not to resell**; chose giveaway to a team) and Claude adapts the plan.
- Rules that made it safe: never paste secrets in chat; ask for a screenshot before guessing; label uncertainty;
  keep a `CLAUDE.md` + `HANDOFF.md` so a new chat can continue; test every step with a tiny real request.
- Good prompt templates to include: "Explain this like a mental model first, then steps", "Tell me what you verified and what you did not",
  "Give me one action only", "Here is my screenshot, what is next?", "Write a handoff file for the next chat".
- Mistakes the method caught: exposed key in screenshot, wrong model price, wrong login mode, wrong paste target (see HANDOFF section 9).

## 5. Required tables and graphs (build from the numbers below)

**Architecture diagram**
`Member app / VS Code / Termux --(sk-key)--> Gateway (new-api on Railway) --(real key)--> DeepSeek`
plus Playground (login session) as a side path, MySQL + Redis + volumes beside the gateway.

**Three-limits stack diagram**: DeepSeek real balance > Gateway user balance > per-key quota ("smallest wins").

**Table: DeepSeek prices (USD per 1M tokens, seen 2026-10-15)**

| | flash off-peak | flash peak | pro off-peak | pro peak |
|---|---|---|---|---|
| input, cache hit | 0.003 | 0.006 | 0.022 | 0.044 |
| input, cache miss | 0.15 | 0.3 | 0.66 | 1.32 |
| output | 0.6 | 1.2 | 1.98 | 3.96 |

Peak = 01:00-04:00 and 06:00-10:00 UTC, Mon-Fri, excl. Chinese holidays (Myanmar time: 07:30-10:30 and 12:30-16:30).
Add the disclaimer: prices change; re-read the official page (`api-docs.deepseek.com/quick_start/pricing`).

**Graph 1: cost of 1M tokens by input/output mix** (flash, peak): 100% input = $0.30, 50/50 = $0.75, 100% output = $1.20,
with a horizontal line at the Gateway charge **$1.20** (uniform price) to show the safety margin. Repeat for off-peak (half).

**Graph 2: quota needed for N tokens** at uniform price 1.2 $/M: 300K = 0.36, 500K = 0.60, 1M = 1.20, 3M = 3.60.
(Earlier chat table used 50/50 blended pricing 0.75 $/M; the **final decision is uniform 1.2** - use that.)

**Graph 3: how many members can $X of DeepSeek money fund** (worst case $1.2 per 1M-token member; real use is lower).
E.g. $1.99 funds 1 member at worst case; $6 funds 5.

**Worked formula box**
- Gateway quota unit: $1 = 500,000 units. Charge = (input tokens x input price + output tokens x output price) / 1,000,000.
- Legacy rule of thumb from the docs examples (unverified): model ratio = input $/1M / 2; completion ratio = output / input.
- Real measured example: 67 tokens -> $0.000080; 1,186 tokens -> $0.001423 at 1.2 $/M.
- Why 1.2: it equals DeepSeek flash's **highest** price (output, peak), so we never undercharge.
- Thinking mode: a "hi" cost 35 completion tokens of which 25 were reasoning.

**Table: where each limit shows up** (Playground vs API key vs user balance vs DeepSeek).

**Table: platforms used** - Railway (hosting, template deploy), new-api (gateway), DeepSeek Platform (model + billing),
Termux (phone terminal for tests), GitHub (repo + Pages), Hostinger (domain DNS), Supabase (GamePay backend), Claude Code (the AI helper).
For each: what it is, why chosen, cost, a gotcha.

**Table: security checklist** (before / after going live): rotate exposed keys; unique strong admin password in a manager;
disable open sign-up; 2FA; per-member quota and model limit; expiry; balance alert; Railway usage limit; never paste keys in chat/screenshots;
check provider terms before sharing or reselling (OpenAI forbids API-key trading and account resale; the Gateway's own compliance terms
also forbid unauthorized resale); keep upstream key only inside the gateway.

**Table: troubleshooting** (symptom -> cause -> fix), from HANDOFF section 9, plus: "Model Price Not Configured" -> set price;
"Playground works but my key does not" -> key vs session; "DeepSeek shows fewer requests" -> up to 5 min lag.

## 6. Suggested chapter outline

0. Cover, how to read this book, disclaimer (not legal advice; prices change)
1. The story: why a gateway? (GamePay Hub background; the idea to give members limited AI access)
2. Mental models: tokens, keys, gateway, credits, the three limits (diagrams)
3. The toolbox (platform table)
4. Build it, step by step (Railway template -> setup wizard -> channel -> pricing -> keys -> tests), each step with "what you should see"
5. Prices and credit math (tables, graphs, worked examples, how to pick the giveaway quota)
6. Adding models and buying access (DeepSeek top-up, OpenAI notes, aggregators, Channel form fields, Fetch from Upstream, model redirects)
7. Talking to Claude: the working method and prompt templates; what a "template" is
8. Security and the mistakes we made
9. Giving keys to a team + the usage page idea (design, unverified endpoint, test plan)
10. Appendices: glossary, command cheat sheet, checklists, troubleshooting, the `chat.py` script, further reading

## 7. Source of the Termux chat script (no key inside; it reads `GW_KEY`)

Run: `export GW_KEY="<your key>"` then `python chat.py` (optional `GW_MODEL=deepseek-v4-pro`). It shells out to `curl`
because Python `urllib` hit `IncompleteRead` on the Railway edge.

```python
import os, json, time, subprocess

URL = "https://<your-gateway>/v1/chat/completions"
KEY = os.environ["GW_KEY"]
MODEL = os.environ.get("GW_MODEL", "deepseek-flash")
PRICE = 1.2  # $ per 1M tokens (correct for flash with the uniform price)

def call(body):
    for i in range(3):
        p = subprocess.run(
            ["curl", "-s", "--max-time", "90", URL,
             "-H", "Authorization: Bearer " + KEY,
             "-H", "Content-Type: application/json",
             "-d", body],
            capture_output=True, text=True)
        if p.stdout.strip():
            try:
                return json.loads(p.stdout)
            except Exception:
                pass
        print("(retry...)", flush=True)
        time.sleep(2)
    return None

msgs = []
used = 0
print("Chat start. Type /exit to quit.")

while True:
    try:
        q = input("\nYou: ").strip()
    except EOFError:
        break
    if q == "/exit":
        break
    if not q:
        continue
    msgs.append({"role": "user", "content": q})
    print("(waiting...)", flush=True)
    t0 = time.time()
    d = call(json.dumps({"model": MODEL, "messages": msgs}))
    if not d or "choices" not in d:
        print("Error:", json.dumps(d)[:300] if d else "no response")
        msgs.pop()
        continue
    a = d["choices"][0]["message"]["content"]
    msgs.append({"role": "assistant", "content": a})
    t = d["usage"]["total_tokens"]
    used += t
    print("\nAI:", a)
    print(f"[{time.time()-t0:.1f}s | token {t} | total {used} | cost ~ ${used*PRICE/1e6:.6f}]")
```

## 8. How to build the PDF (tooling notes from this sandbox)

- Playwright + Chromium exist: `/opt/node-tools` (node modules) and `/opt/pw-browsers/chromium`.
  Plan: write the book as **HTML + CSS**, then `page.pdf()` with `printBackground: true`, `preferCSSPageSize: true`.
  The `pdf` skill is also available. Render pages to PNG and **look at them** before reporting (check page breaks, tables, graphs, Burmese text).
- **Burmese fonts**: the sandbox only had *Unifont* for Myanmar. You must **bundle a real Myanmar font**
  (e.g. Noto Sans Myanmar or Padauk). Try `npm install @fontsource/noto-sans-myanmar` in a scratch folder
  (availability unverified) and load the `.woff2` via `@font-face`; embed so the PDF does not depend on the viewer.
  Check shaping of stacked/medial characters in the rendered PNGs; wrong glyph order means wrong font/engine.
- Graphs: inline SVG you write yourself (deterministic) or Chart.js (cdnjs, pinned version) rendered in headless Chromium.
  Use the palette in section 3 and label axes in Burmese and numbers in Western digits.
- Save outputs under `_notes/api-gateway/book/` (source `book.html` + `book.pdf`). Keep the PDF reasonably small.
  If the PDF is large, tell the owner instead of committing it.
- Work in stages and show the owner: (1) outline + one sample chapter as PDF, (2) get feedback, (3) full book.
  Do not dump the whole book in one go.

## 9. Facts still unverified (say so in the book)

- Monthly Railway cost of this three-service template; minimum RAM for new-api.
- Whether a plain API key can read its own balance via the Gateway (needed for the usage page); which endpoint; CORS.
- What the Advanced Settings of Create API Key contain (model limit / IP rules).
- Whether DeepSeek offers per-key spend caps; DeepSeek's terms on sharing access with others.
- The "model ratio = input/2" rule (inferred from docs examples).
- Gateway "self-use mode" exact behaviour.
