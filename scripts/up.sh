#!/usr/bin/env bash
# Bring up one cloud (or all). Usage: ./scripts/up.sh aws|azure|dns|all
set -euo pipefail
cd "$(dirname "$0")/.."

up() {
  echo ">>> terraform apply: $1"
  terraform -chdir="terraform/$1" init -upgrade -input=false
  terraform -chdir="terraform/$1" apply -auto-approve
  echo ">>> $1 outputs:"
  terraform -chdir="terraform/$1" output
}

case "${1:-}" in
  aws|azure|dns) up "$1" ;;
  all) up azure; up aws ;;
  *) echo "usage: $0 aws|azure|dns|all"; exit 1 ;;
esac
