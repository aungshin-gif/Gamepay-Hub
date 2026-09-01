# GamePay Hub Professional Storefront

A clean, responsive, dependency-free storefront for GamePay Hub.

## Included

- 41 original products and 169 original plans preserved
- Responsive two-column mobile catalog
- Search and dynamic category filters
- Product details and plan selection on one page
- Dynamic plan filters only when relevant
- Required account validation based on product type
- Required custom-amount validation and live totals
- Payment selection with a separate Copy Number action
- Final order review before Telegram
- Real clipboard copy with a safe fallback
- Order reference ID and Telegram fallback link
- Browser Back/Forward support through URL hashes
- Session draft preservation during the current browser session
- Accessible buttons, labels, focus states, and zoom support
- Reduced-motion support
- Graceful initials fallback for missing images

## File structure

```text
gamepay-hub-professional/
├── index.html
├── css/
│   └── styles.css
├── js/
│   ├── product-data.js
│   └── app.js
├── assets/
│   └── README.md
├── GITHUB_UPLOAD_GUIDE_MM.md
└── README.md
```

## Edit store information

- Products, plans, prices and payment data: `js/product-data.js`
- Telegram usernames and channel: bottom of `js/product-data.js`
- Layout and page content: `index.html`
- Colors, spacing and responsive design: `css/styles.css`
- Checkout and Telegram behavior: `js/app.js`

## Run locally

Double-clicking `index.html` works for normal browsing. For the most accurate clipboard behavior, serve the folder through a local web server or deploy it to GitHub Pages/Vercel.

## Deployment

No build command or framework is required. Upload the complete folder contents to a GitHub repository and deploy it as a static site.
