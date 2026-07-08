# Nabbo Landing Page

Static landing page for [nabbo.app](https://nabbo.app), hosted on GitHub Pages.

## Setup

1. Push this folder to a GitHub repo (can be the same `nabbo` repo or a separate one)
2. Go to **Settings → Pages** in your GitHub repo
3. Under "Source", select:
   - Branch: `main`
   - Folder: `/docs/landing` (or move contents to root of a `gh-pages` branch)
4. If using a custom domain (nabbo.app), add a `CNAME` file and configure DNS

## Custom Domain (optional)

If you have `nabbo.app`:
1. Create a `CNAME` file in this folder with content: `nabbo.app`
2. Add these DNS records at your domain registrar:
   - A record → `185.199.108.153`
   - A record → `185.199.109.153`
   - A record → `185.199.110.153`
   - A record → `185.199.111.153`
   - CNAME `www` → `<your-username>.github.io`

## Structure

```
landing/
├── index.html      — Main landing page
├── privacy.html    — Privacy policy (linked from App Store)
├── terms.html      — Terms of service
└── README.md       — This file
```

## Updating

Edit the HTML files directly. No build step needed — it's all static HTML + CSS.
