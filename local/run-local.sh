#!/usr/bin/env bash
# Local iteration: spin up the same Postgres + Odoo the CI workflow uses, install
# the module with demo data, run the seed, and start the server. Then run your
# capture script against http://localhost:8069 as many times as you like while
# you tune it. Nothing here touches CI.
#
# Usage, from the module repo root:
#   ODOO_VERSION=17.0 MODULE_NAME=my_addon \
#     /path/to/odoo-screenshots/local/run-local.sh up
#   # edit screenshots/capture.mjs, then repeatedly:
#   BASE_URL=http://localhost:8069 OUT_DIR=./shots node screenshots/capture.mjs
#   # when done:
#   ... run-local.sh down
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${MODULE_NAME:?set MODULE_NAME to the addon directory name}"
: "${ODOO_VERSION:=17.0}"
export ODOO_VERSION MODULE_NAME
export MODULE_PATH="${MODULE_PATH:-$(pwd)}"
COMPOSE=("docker" "compose" "-f" "$HERE/docker-compose.yml" "-p" "odoo-shots-$MODULE_NAME")

cmd="${1:-up}"
case "$cmd" in
  up)
    "${COMPOSE[@]}" up -d db
    echo "Installing $MODULE_NAME with demo data..."
    "${COMPOSE[@]}" run --rm odoo odoo -d screenshots -i "$MODULE_NAME" --stop-after-init
    if [ -f "$MODULE_PATH/screenshots/seed.py" ]; then
      echo "Seeding..."
      "${COMPOSE[@]}" run --rm -T odoo odoo shell -d screenshots --no-http < "$MODULE_PATH/screenshots/seed.py"
    fi
    "${COMPOSE[@]}" up -d odoo
    echo "Odoo starting on http://localhost:8069 (login admin / admin)."
    ;;
  down)
    "${COMPOSE[@]}" down -v
    ;;
  logs)
    "${COMPOSE[@]}" logs -f odoo
    ;;
  *)
    echo "Usage: run-local.sh [up|down|logs]" >&2; exit 1;;
esac
