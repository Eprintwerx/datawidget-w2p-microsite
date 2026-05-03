# DataWidget® for Web-to-Print — marketing microsite

Patented (U.S. Patents 12,482,026 + 10,102,557) embeddable mailing-list builder marketed to web-to-print platforms, postcard SaaS, EDDM tools, multi-channel orchestration platforms, and franchise marketing tools.

Mirrors the family pattern: full LP topbar + footer, anti-CLS inlined CSS, scroll-padding-top, display=optional fonts, comprehensive JSON-LD (SoftwareApplication, Organization, WebSite/SearchAction, BreadcrumbList, FAQPage, HowTo), trademark sweep (DataWidget® + LeadsPlease®).

## Tabs

1. **Use DataWidget® for Web-to-Print** — overview, three-panel UI, integration steps, testimonial, Experian/Equifax data attribution
2. **Try It** — live Banner widget embed + full backend integration code samples (conclusionurl webhook XML, get_list polling, CSV download, skin/datasetkey config)
3. **Use Cases** — six deployment patterns (postcard SaaS, EDDM, real-estate, franchise, orchestration, B2B ABM) + 6-Q FAQ
4. **Prices** — two-tier ($499/mo Standard, custom Enterprise) + per-record from affiliate XML, no order minimum
5. **Get Started** — affiliate-code application form (Stripe-ready) + spec/support links

## Live working example

The Banner widget at `https://datawidget-banner-production.up.railway.app/widget?affiliatecode=banner` is iframed into the Try It tab as the live demo.

## Local dev

```bash
PORT=4325 node server.js
# → http://localhost:4325
```

## Deploy

Railway via Dockerfile + `railway.toml`. Healthcheck at `/health`.

Production target: `web-to-print.datawidget.com` (DNS pending).
