// Tiny static-file server for the DataWidget® for Web-to-Print marketing microsite.
const express = require('express');
const path = require('path');
const app = express();

// SEO guard — a *.railway.app host must never be indexed: Google was picking
// up the Railway-generated URL, competing with (and diluting) the canonical
// leadsplease.com / product-domain rankings. Custom domains are unaffected
// (checked per-request via the Host header). Remove only if this site is
// promoted to its canonical domain AND the Railway domain is deleted.
app.use(function railwayNoIndex(req, res, next) {
  const host = String(req.headers.host || '').toLowerCase().split(':')[0];
  if (host.endsWith('.railway.app')) {
    res.setHeader('X-Robots-Tag', 'noindex, nofollow');
    if (req.path === '/robots.txt') {
      // Crawl stays OPEN on the Railway host (#587): this URL is already in
      // Google's index (confirmed ranking), and a Disallow stops Googlebot
      // re-crawling, so it would never see the noindex and the stale listing
      // would linger. The X-Robots-Tag above is the protection; re-tighten to
      // Disallow only once the listing is confirmed gone.
      return res.type('text/plain').send('User-agent: *\nAllow: /\n');
    }
  }
  next();
});

const PORT = process.env.PORT || 8769;

function setCacheHeaders(res, filePath) {
  if (filePath.includes('/_astro/')) {
    res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
  } else if (filePath.endsWith('.html')) {
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0');
  } else {
    res.setHeader('Cache-Control', 'public, max-age=3600');
  }
}

app.get('/health', function (req, res) {
  res.json({ ok: true, service: 'datawidget-w2p-microsite', uptime_s: Math.round(process.uptime()) });
});

app.use(express.static(path.join(__dirname), {
  setHeaders: setCacheHeaders,
  extensions: ['html'],
  index: 'index.html',
}));

app.listen(PORT, function () {
  console.log('DataWidget® for W2P microsite on port ' + PORT);
  console.log('  http://localhost:' + PORT + '/');
});
