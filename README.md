# odoo-screenshots

Shared CI for capturing Odoo module screenshots. One reusable GitHub Actions
workflow spins up Postgres + Odoo, installs an addon with demo data, runs an
optional seed script, then drives a Playwright script to take the shots. The
PNGs come back as a build artifact, or get committed straight into the module
repo so the App Store description and README stay current.

Both Mettle & Byte modules use this. The only per-module difference is the
Playwright script that drives the UI.

## What lives where

- **This repo**: the reusable workflow (`.github/workflows/screenshots.yml`) and
  the shared `local/docker-compose.yml` for local iteration. Generic, no
  module-specific code.
- **Each module repo**:
  - `screenshots/capture.mjs` (required): the Playwright script. Reads
    `BASE_URL` and `OUT_DIR` from the environment and writes named PNGs.
  - `screenshots/seed.py` (optional): an Odoo-shell script that creates the
    exact state to photograph (an out-of-stock published product, sample
    records, group members). Skipped if absent.
  - `.github/workflows/screenshots.yml`: a thin `workflow_dispatch` wrapper that
    calls this reusable workflow.

## Using it from a module repo

Add `.github/workflows/screenshots.yml`:

```yaml
name: Screenshots
on:
  workflow_dispatch:
    inputs:
      odoo_version:
        description: "Odoo version (blank = read from manifest)"
        type: string
        default: ""
      commit:
        description: "Commit PNGs into static/description/screenshots"
        type: boolean
        default: false
permissions:
  contents: write
jobs:
  shots:
    uses: mettle-and-byte/odoo-screenshots/.github/workflows/screenshots.yml@main
    with:
      module_name: my_addon
      odoo_version: ${{ inputs.odoo_version }}
      commit: ${{ inputs.commit }}
    secrets: inherit
```

Run it from the Actions tab, pick the branch (the branch's Odoo version is read
from `__manifest__.py`), and choose whether to commit or just download the
artifact.

## Iterating locally

From the module repo root, with Docker running:

```bash
ODOO_VERSION=17.0 MODULE_NAME=my_addon \
  /path/to/odoo-screenshots/local/run-local.sh up

# tune the script, re-run as often as you like:
BASE_URL=http://localhost:8069 OUT_DIR=./shots node screenshots/capture.mjs

/path/to/odoo-screenshots/local/run-local.sh down
```

Same containers, same install, same seed as CI, so what you see locally is what
the workflow captures.

## Writing a capture script

`capture.mjs` gets `BASE_URL` and `OUT_DIR`. Log in as `admin` / `admin`, drive
the UI, and save PNGs into `OUT_DIR` with stable names (those names are what the
description and README reference). Use the shared helpers pattern in the existing
module scripts as a starting point.
