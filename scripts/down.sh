#!/usr/bin/env bash
# COST CONTROL: destroy one cloud (or all). Run after every working session.
# Usage: ./scripts/down.sh aws|azure|dns|all
set -euo pipefail
cd "$(dirname "$0")/.."

down() {
  echo ">>> terraform destroy: $1 (5s to Ctrl-C)"; sleep 5
  terraform -chdir="terraform/$1" destroy -auto-approve
}

case "${1:-}" in
  aws|azure|dns) down "$1" ;;
  all) down dns || true; down aws; down azure ;;
  *) echo "usage: $0 aws|azure|dns|all"; exit 1 ;;
esac
echo ">>> Verify in each console that nothing is left billing."
