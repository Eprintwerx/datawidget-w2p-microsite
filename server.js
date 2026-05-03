// Tiny static-file server for the DataWidget® for Web-to-Print marketing microsite.
const express = require('express');
const path = require('path');
const app = express();
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
