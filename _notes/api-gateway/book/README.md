# Book build

`build.py` writes `book.html`; `render.js` turns it into `book.pdf` (Playwright Chromium).
Fonts are loaded from `node_modules/@fontsource` **next to build.py**, which is not committed.
Run `npm install @fontsource/noto-sans-myanmar @fontsource/inter @fontsource/jetbrains-mono` in this folder first.
If you skip it, Chromium silently falls back to a pixel font for Burmese (this happened once: check with `pdffonts book.pdf`, it must list NotoSansMyanmar).
