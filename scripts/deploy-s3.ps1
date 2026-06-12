# Deploy the DataWidget-W2P microsite to S3 under the /datawidget-w2p subpath
# served via existing CloudFront distribution E39WJRUVOH25A4.
#
# Source files in the repo stay Railway-compatible (asset hrefs start with /_astro,
# /manifest.json, etc.). This script stages a copy, rewrites those paths to
# /datawidget-w2p/_astro, /datawidget-w2p/manifest.json, etc., then syncs to S3
# under the matching key prefix so CloudFront forwards requests 1:1.
#
# Usage:
#   .\scripts\deploy-s3.ps1 -BucketName lp-datawidget-w2p-microsite
#
# Optional:
#   -DistributionId E39WJRUVOH25A4   CloudFront distribution to invalidate
#   -PathPrefix     datawidget-w2p   S3 key prefix and CloudFront behavior path
#   -SkipInvalidation                Skip the CloudFront invalidation step

param(
  [Parameter(Mandatory = $true)][string]$BucketName,
  [string]$DistributionId   = 'E39WJRUVOH25A4',
  [string]$PathPrefix       = 'datawidget-w2p',
  [switch]$SkipInvalidation
)

$ErrorActionPreference = 'Stop'

$repoRoot   = Split-Path -Parent $PSScriptRoot
$stamp      = Get-Date -Format yyyyMMddHHmmss
$stagingDir = Join-Path $env:TEMP "datawidget-w2p-deploy-$stamp"

Write-Host "Repo:    $repoRoot"
Write-Host "Staging: $stagingDir"
Write-Host "Bucket:  s3://$BucketName/$PathPrefix/"
Write-Host "Distrib: $DistributionId"
Write-Host ""

# Files/folders shipped to S3. Everything else (server.js, Dockerfile, railway.toml,
# package*.json, .git, scripts, README, llms.txt-style internals) stays out.
$includes = @(
  'index.html',
  'manifest.json',
  'robots.txt',
  'sitemap.xml',
  'og-image.svg',
  'llms.txt',
  '_astro'
)

New-Item -ItemType Directory -Path $stagingDir | Out-Null
foreach ($entry in $includes) {
  $src = Join-Path $repoRoot $entry
  if (Test-Path $src) {
    Copy-Item -Path $src -Destination $stagingDir -Recurse
  } else {
    Write-Warning "Missing source (skipped): $entry"
  }
}

# Rewrite absolute-from-root asset references so the browser, sitting at
# https://<cf-domain>/datawidget-w2p/, fetches assets under the same subpath.
$prefixSlash  = "/$PathPrefix"
$rewriteFiles = @(
  (Join-Path $stagingDir 'index.html'),
  (Join-Path $stagingDir 'manifest.json')
)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
foreach ($f in $rewriteFiles) {
  if (-not (Test-Path $f)) { continue }
  # Read as UTF-8 explicitly: PS 5.1's Get-Content -Raw (no -Encoding) defaults
  # to the system ANSI code page and mangles multi-byte UTF-8 (em-dash etc).
  $c = [System.IO.File]::ReadAllText($f, $utf8NoBom)
  $c = $c -replace '(["''])/_astro/',                ('$1' + $prefixSlash + '/_astro/')
  $c = $c -replace '(["''])/manifest\.json(["''])',  ('$1' + $prefixSlash + '/manifest.json$2')
  $c = $c -replace '"start_url"\s*:\s*"/"',          ('"start_url": "' + $prefixSlash + '/"')
  [System.IO.File]::WriteAllText($f, $c, $utf8NoBom)
}

$s3Target = "s3://$BucketName/$PathPrefix/"

# Three sync passes, each with a different Cache-Control. --delete is scoped per
# pass by the include/exclude filters, so we only prune stale files of the matching
# type. Mirrors the per-route headers the Express server sets today.
Write-Host "[1/3] _astro/* -> immutable, 1y"
aws s3 sync $stagingDir $s3Target `
  --delete `
  --exclude '*' --include '_astro/*' `
  --cache-control 'public, max-age=31536000, immutable'
if ($LASTEXITCODE -ne 0) { throw "Sync (_astro) failed." }

Write-Host ""
Write-Host "[2/3] *.html -> no-cache"
aws s3 sync $stagingDir $s3Target `
  --delete `
  --exclude '*' --include '*.html' `
  --cache-control 'no-store, no-cache, must-revalidate, max-age=0' `
  --content-type 'text/html; charset=utf-8'
if ($LASTEXITCODE -ne 0) { throw "Sync (html) failed." }

Write-Host ""
Write-Host "[3/3] other static -> 1h"
aws s3 sync $stagingDir $s3Target `
  --delete `
  --exclude '*' `
  --include '*.json' --include '*.txt' --include '*.xml' --include '*.svg' `
  --cache-control 'public, max-age=3600'
if ($LASTEXITCODE -ne 0) { throw "Sync (other) failed." }

if (-not $SkipInvalidation) {
  Write-Host ""
  Write-Host "Invalidating CloudFront $DistributionId /$PathPrefix/*"
  aws cloudfront create-invalidation `
    --distribution-id $DistributionId `
    --paths "/$PathPrefix/*"
  if ($LASTEXITCODE -ne 0) { throw "CloudFront invalidation failed." }
}

Remove-Item -Recurse -Force $stagingDir

Write-Host ""
Write-Host "Deploy complete. Smoke-test once the invalidation finishes:"
Write-Host "  curl -I https://<cloudfront-domain>/$PathPrefix/"
Write-Host "  curl -I https://<cloudfront-domain>/$PathPrefix/_astro/index@_@astro.GXeN1xiA.css"
