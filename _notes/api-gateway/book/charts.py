# Hand-built SVG charts and diagrams for the book. Palette matches GamePay Hub.
V, A, O = "#6231c8", "#7a35c7", "#a87ce0"
MIST, TINT, BORDER, INK, MUTED = "#efe7ff", "#f6f3fd", "#e3d9f6", "#2a1a55", "#7d7390"
MINT, AMBER, CORAL = "#2fbe8c", "#f2a93b", "#e2568c"


def bar_chart(cats, series, ymax, yticks, w=560, h=270, line=None, prefix="$", fmt="{:.2f}"):
    """Grouped bar chart. series = [(name, color, [values])]."""
    ml, mr, mt, mb = 52, 14, 34, 46
    pw, ph = w - ml - mr, h - mt - mb
    out = [f'<svg viewBox="0 0 {w} {h}" xmlns="http://www.w3.org/2000/svg" class="chart">']
    out.append(f'<rect x="0" y="0" width="{w}" height="{h}" rx="16" fill="{TINT}"/>')
    for t in yticks:
        y = mt + ph - ph * t / ymax
        out.append(f'<line x1="{ml}" y1="{y:.1f}" x2="{w-mr}" y2="{y:.1f}" stroke="{BORDER}" stroke-width="1"/>')
        out.append(f'<text x="{ml-8}" y="{y+4:.1f}" text-anchor="end" font-size="10" fill="{MUTED}">{prefix}{t:g}</text>')
    n, m = len(cats), len(series)
    gw = pw / n
    bw = min(46, gw * 0.7 / m)
    for i, c in enumerate(cats):
        gx = ml + gw * i + gw / 2
        for j, (name, col, vals) in enumerate(series):
            v = vals[i]
            bh = ph * v / ymax
            x = gx - (bw * m) / 2 + bw * j
            y = mt + ph - bh
            out.append(f'<rect x="{x+1:.1f}" y="{y:.1f}" width="{bw-2:.1f}" height="{bh:.1f}" rx="6" fill="{col}"/>')
            out.append(f'<text x="{x+bw/2:.1f}" y="{y-6:.1f}" text-anchor="middle" font-size="10" font-weight="700" fill="{INK}">{prefix}{fmt.format(v)}</text>')
        out.append(f'<text x="{gx:.1f}" y="{h-mb+18}" text-anchor="middle" font-size="11" fill="{INK}">{c}</text>')
    if line:
        val, label, col = line
        y = mt + ph - ph * val / ymax
        out.append(f'<line x1="{ml}" y1="{y:.1f}" x2="{w-mr}" y2="{y:.1f}" stroke="{col}" stroke-width="2" stroke-dasharray="6 4"/>')
        out.append(f'<text x="{ml+8}" y="{y-6:.1f}" text-anchor="start" font-size="10.5" font-weight="700" fill="{col}">{label}</text>')
    lx = ml
    for name, col, _ in series:
        out.append(f'<rect x="{lx}" y="10" width="12" height="12" rx="4" fill="{col}"/>')
        out.append(f'<text x="{lx+18}" y="20" font-size="10.5" fill="{INK}">{name}</text>')
        lx += 18 + 7.2 * len(name) + 24
    out.append('</svg>')
    return "".join(out)


def stacked_hbar(parts, total_label, w=560, h=130):
    """Single horizontal stacked bar. parts = [(label, value, color)]"""
    tot = sum(p[1] for p in parts)
    x0, bw, y, bh = 24, w - 48, 52, 34
    out = [f'<svg viewBox="0 0 {w} {h}" xmlns="http://www.w3.org/2000/svg" class="chart">',
           f'<rect width="{w}" height="{h}" rx="16" fill="{TINT}"/>']
    x = x0
    for label, v, col in parts:
        pw = bw * v / tot
        out.append(f'<rect x="{x:.1f}" y="{y}" width="{pw-3:.1f}" height="{bh}" rx="8" fill="{col}"/>')
        out.append(f'<text x="{x+pw/2-1.5:.1f}" y="{y+22}" text-anchor="middle" font-size="13" font-weight="700" fill="#fff">{v}</text>')
        out.append(f'<text x="{x+pw/2-1.5:.1f}" y="{y+bh+20}" text-anchor="middle" font-size="10.5" fill="{INK}">{label}</text>')
        x += pw
    out.append(f'<text x="{w/2}" y="30" text-anchor="middle" font-size="12" font-weight="700" fill="{INK}">{total_label}</text>')
    out.append('</svg>')
    return "".join(out)


def box(x, y, w, h, title, sub=None, fill="#fff", stroke=V, tcol=INK):
    s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="{fill}" stroke="{stroke}" stroke-width="2"/>'
    if sub:
        s += f'<text x="{x+w/2}" y="{y+h/2-3}" text-anchor="middle" font-size="12" font-weight="700" fill="{tcol}">{title}</text>'
        s += f'<text x="{x+w/2}" y="{y+h/2+14}" text-anchor="middle" font-size="9.5" fill="{MUTED}">{sub}</text>'
    else:
        s += f'<text x="{x+w/2}" y="{y+h/2+4}" text-anchor="middle" font-size="12" font-weight="700" fill="{tcol}">{title}</text>'
    return s


def arrow(x1, y1, x2, y2, label=None, col=A, dash=False, lx=None, ly=None):
    d = ' stroke-dasharray="6 4"' if dash else ''
    s = f'<defs><marker id="ah{abs(hash((x1,y1,x2,y2)))%9999}" markerWidth="9" markerHeight="9" refX="7" refY="4.5" orient="auto"><path d="M0,0 L9,4.5 L0,9 z" fill="{col}"/></marker></defs>'
    mid = f"ah{abs(hash((x1,y1,x2,y2)))%9999}"
    s += f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{col}" stroke-width="2.2"{d} marker-end="url(#{mid})"/>'
    if label:
        s += f'<text x="{lx if lx is not None else (x1+x2)/2}" y="{ly if ly is not None else (y1+y2)/2-7}" text-anchor="middle" font-size="9.5" fill="{col}" font-weight="700">{label}</text>'
    return s


def architecture():
    w, h = 560, 330
    o = [f'<svg viewBox="0 0 {w} {h}" xmlns="http://www.w3.org/2000/svg" class="chart">', f'<rect width="{w}" height="{h}" rx="16" fill="{TINT}"/>']
    o.append(box(18, 30, 150, 54, "VS Code", "base URL + sk-key"))
    o.append(box(18, 100, 150, 54, "Termux / curl", "base URL + sk-key"))
    o.append(box(18, 170, 150, 54, "Chat app", "Cherry Studio ..."))
    o.append(box(205, 70, 160, 110, "Gateway", "new-api on Railway", fill=MIST))
    o.append(box(402, 70, 140, 110, "DeepSeek", "ပိုက်ဆံအစစ်ရှိတဲ့နေရာ", fill="#fff", stroke=MINT))
    for yy in (57, 127, 197):
        o.append(arrow(168, yy, 205, 118 if yy != 197 else 140, col=A))
    o.append(arrow(365, 125, 402, 125, "real key", col=MINT, lx=383, ly=116))
    o.append(box(205, 215, 70, 40, "MySQL", None, fill="#fff", stroke=O))
    o.append(box(295, 215, 70, 40, "Redis", None, fill="#fff", stroke=O))
    o.append(f'<text x="285" y="275" text-anchor="middle" font-size="9.5" fill="{MUTED}">volumes = data မပျောက်အောင် သိမ်းတဲ့နေရာ</text>')
    o.append(box(18, 250, 150, 54, "Playground", "login session (key မလို)", fill="#fff", stroke=AMBER))
    o.append(arrow(168, 277, 215, 182, col=AMBER, dash=True))
    o.append(f'<text x="420" y="225" font-size="10" fill="{INK}" font-weight="700">Gateway မှာလုပ်တာ</text>')
    for i, t in enumerate(["1. key မှန်လား စစ်", "2. quota ကျန်လား စစ်", "3. သုံးသလောက် နှုတ်", "4. Usage Logs ထဲ မှတ်"]):
        o.append(f'<text x="420" y="{245+i*18}" font-size="10" fill="{INK}">{t}</text>')
    o.append('</svg>')
    return "".join(o)


def three_limits():
    w, h = 560, 250
    o = [f'<svg viewBox="0 0 {w} {h}" xmlns="http://www.w3.org/2000/svg" class="chart">', f'<rect width="{w}" height="{h}" rx="16" fill="{TINT}"/>']
    rows = [
        (24, 440, "① DeepSeek ထဲက ပိုက်ဆံအစစ်", "တကယ့် အမိုးအကာ · ဒါကုန်ရင် ဘာမှမလုပ်နိုင်တော့", MINT),
        (84, 360, "② Gateway user balance", "အတွင်းစာရင်း · admin ကိုယ်တိုင် ပြင်လို့ရ", A),
        (144, 270, "③ API key တစ်ခုချင်းရဲ့ quota", "member တစ်ယောက်ကို ပေးတဲ့ ပမာဏ", CORAL),
    ]
    for y, bw, t, s, col in rows:
        o.append(f'<rect x="60" y="{y}" width="{bw}" height="52" rx="14" fill="{col}"/>')
        o.append(f'<text x="76" y="{y+23}" font-size="13" font-weight="700" fill="#fff">{t}</text>')
        o.append(f'<text x="76" y="{y+41}" font-size="10" fill="#fff">{s}</text>')
    o.append(f'<text x="{w/2}" y="226" text-anchor="middle" font-size="12" font-weight="700" fill="{INK}">request တစ်ခုက ၃ ထပ်လုံးကို ကျော်ရမယ် · အသေးဆုံးတစ်ခုက ကန့်သတ်တယ်</text>')
    o.append('</svg>')
    return "".join(o)


def phone_wireframe():
    w, h = 560, 330
    o = [f'<svg viewBox="0 0 {w} {h}" xmlns="http://www.w3.org/2000/svg" class="chart">', f'<rect width="{w}" height="{h}" rx="16" fill="{TINT}"/>']
    o.append(f'<rect x="170" y="14" width="220" height="302" rx="26" fill="#fff" stroke="{V}" stroke-width="3"/>')
    o.append(f'<rect x="186" y="34" width="188" height="40" rx="12" fill="{MIST}"/><text x="280" y="59" text-anchor="middle" font-size="12" font-weight="700" fill="{INK}">Token Usage</text>')
    o.append(f'<rect x="186" y="86" width="188" height="30" rx="10" fill="#fff" stroke="{BORDER}"/><text x="198" y="106" font-size="10" fill="{MUTED}">sk-••••••••••••</text>')
    o.append(f'<rect x="186" y="124" width="188" height="30" rx="10" fill="#fff" stroke="{BORDER}"/><text x="198" y="144" font-size="10" fill="{INK}">Model: deepseek-flash</text>')
    o.append(f'<rect x="186" y="164" width="188" height="30" rx="15" fill="{V}"/><text x="280" y="184" text-anchor="middle" font-size="11" font-weight="700" fill="#fff">စစ်ကြည့်မယ်</text>')
    o.append(f'<rect x="186" y="208" width="188" height="14" rx="7" fill="{BORDER}"/><rect x="186" y="208" width="118" height="14" rx="7" fill="{MINT}"/>')
    o.append(f'<text x="186" y="242" font-size="10" fill="{INK}">ကန့်သတ်ချက်  1,000,000</text>')
    o.append(f'<text x="186" y="258" font-size="10" fill="{INK}">သုံးပြီး        380,000</text>')
    o.append(f'<text x="186" y="274" font-size="11" font-weight="700" fill="{V}">ကျန်            620,000</text>')
    o.append(f'<text x="400" y="228" font-size="9.5" fill="{MUTED}">← progress bar</text>')
    o.append(f'<text x="400" y="106" font-size="9.5" fill="{MUTED}">← member ရဲ့ key</text>')
    o.append(f'<text x="24" y="150" font-size="10" fill="{MUTED}">(ဥပမာပုံ · ဂဏန်းတွေက ပုံစံပြပဲ)</text>')
    o.append('</svg>')
    return "".join(o)


def timeline():
    w, h = 560, 170
    o = [f'<svg viewBox="0 0 {w} {h}" xmlns="http://www.w3.org/2000/svg" class="chart">', f'<rect width="{w}" height="{h}" rx="16" fill="{TINT}"/>']
    o.append(f'<line x1="40" y1="84" x2="{w-40}" y2="84" stroke="{O}" stroke-width="4" stroke-linecap="round"/>')
    ev = [("GamePay Hub", "store ရှိပြီး", V), ("စိတ်ကူး", "API token", A), ("ဆုံးဖြတ်", "ပြန်မရောင်း", CORAL),
          ("Railway", "gateway တက်", AMBER), ("စျေးသတ်မှတ်", "1.2 / 1.2", MINT), ("စမ်းသပ်", "Termux ✓", V)]
    n = len(ev)
    for i, (t, s, col) in enumerate(ev):
        x = 56 + i * (w - 112) / (n - 1)
        o.append(f'<circle cx="{x:.1f}" cy="84" r="11" fill="{col}" stroke="#fff" stroke-width="3"/>')
        yy = 52 if i % 2 == 0 else 124
        o.append(f'<text x="{x:.1f}" y="{yy}" text-anchor="middle" font-size="11" font-weight="700" fill="{INK}">{t}</text>')
        o.append(f'<text x="{x:.1f}" y="{yy+15}" text-anchor="middle" font-size="9.5" fill="{MUTED}">{s}</text>')
    o.append('</svg>')
    return "".join(o)


def credit_flow():
    w, h = 560, 120
    o = [f'<svg viewBox="0 0 {w} {h}" xmlns="http://www.w3.org/2000/svg" class="chart">', f'<rect width="{w}" height="{h}" rx="16" fill="{TINT}"/>']
    xs = [14, 154, 294, 434]
    labs = [("မေးတာ", "input tokens"), ("ဖြေတာ", "output tokens"), ("× စျေး", "$ / 1M token"), ("= ကျသင့်ငွေ", "key quota က နှုတ်")]
    cols = [V, A, AMBER, MINT]
    for x, (a, b), c in zip(xs, labs, cols):
        o.append(box(x, 30, 112, 56, a, b, stroke=c))
    for x in (126, 266, 406):
        o.append(f'<text x="{x+14}" y="64" text-anchor="middle" font-size="18" font-weight="700" fill="{INK}">+</text>' if x == 126 else
                 f'<text x="{x+14}" y="64" text-anchor="middle" font-size="18" font-weight="700" fill="{INK}">→</text>')
    o.append('</svg>')
    return "".join(o)
