#!/bin/sh
# Formuloo Tracker — installe les hooks Git versionnés (.githooks). Idempotent.
# Usage : sh scripts/install-hooks.sh   (à exécuter une fois après le clone)
set -eu

root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$root" ]; then
  echo "✖ Ce dossier n'est pas un dépôt Git. Lance d'abord : git init -b main"
  exit 1
fi
cd "$root"

if [ ! -d .githooks ]; then
  echo "✖ Dossier .githooks introuvable."
  exit 1
fi

chmod +x .githooks/* 2>/dev/null || true
git config core.hooksPath .githooks

echo "✓ Hooks Git installés (core.hooksPath = .githooks)."
echo "  Actifs : pre-commit (branche + secrets), commit-msg (Conventional Commits), pre-push (branche + rebase)."
echo "  Règles complètes : MEMORY.md"
