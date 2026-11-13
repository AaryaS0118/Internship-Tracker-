#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
dist_root="$project_root/dist"

rm -rf "$dist_root"
mkdir -p "$dist_root/server" "$dist_root/.openai"

# The Worker keeps the page as an embedded string. Rebuild that string from
# frontend.html so the published page cannot drift from the editable source.
node - "$project_root" <<'NODE'
const fs = require('fs');
const path = require('path');
const root = process.argv[2];
const workerPath = path.join(root, 'worker', 'index.js');
const pagePath = path.join(root, 'frontend.html');
const outPath = path.join(root, 'dist', 'server', 'index.js');
const worker = fs.readFileSync(workerPath, 'utf8');
const page = fs.readFileSync(pagePath, 'utf8');
const marker = 'const page = ';
const schemaMarker = '\nconst schema =';
const start = worker.indexOf(marker);
const end = worker.indexOf(schemaMarker, start);
if (start < 0 || end < 0) throw new Error('Could not locate embedded page markers');
fs.writeFileSync(outPath, marker + JSON.stringify(page) + ';' + worker.slice(end));
NODE

cp "$project_root/.openai/hosting.json" "$dist_root/.openai/hosting.json"

echo "Built $dist_root"
