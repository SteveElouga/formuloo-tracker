#!/bin/sh
# Formuloo Tracker — configuration GitHub (protection des branches main/develop).
# À lancer SUR TA MACHINE (le pont cloud ne permet pas les opérations Git fiables).
#
# Prérequis :
#   - gh CLI installé (macOS : brew install gh) et authentifié : gh auth login
#   - dépôt GitHub créé, avec main et develop poussés sur origin
#
# Note : dépôt PUBLIC ⇒ protection de branches GRATUITE (E1 appliqué côté serveur).
#   (Sur un dépôt privé en plan gratuit, l'appel échouerait en 403 → il faudrait GitHub Pro.)
set -eu

REPO_PATH="${1:-}"   # ex. "steve/formuloo-tracker" (owner/nom)
if [ -z "$REPO_PATH" ]; then
  echo "Usage : sh scripts/setup-github.sh <owner>/<repo>"
  echo "Exemple : sh scripts/setup-github.sh steve/formuloo-tracker"
  exit 1
fi

protect() {
  br="$1"
  echo "→ Protection de '$br'…"
  if gh api -X PUT "repos/$REPO_PATH/branches/$br/protection" \
       -H "Accept: application/vnd.github+json" --input - >/dev/null 2>&1 <<'JSON'
{
  "required_status_checks": { "strict": true, "contexts": [] },
  "enforce_admins": true,
  "required_pull_request_reviews": { "required_approving_review_count": 0 },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
  then
    echo "  ✓ '$br' protégée : PR obligatoire, branche à jour requise (rebase), historique linéaire, force-push & suppression interdits."
  else
    echo "  ✖ Échec sur '$br'. Dépôt privé en plan gratuit ? La protection nécessite GitHub Pro ou un dépôt public."
    echo "    En attendant, E1 repose sur les hooks locaux (.githooks : install via scripts/install-hooks.sh)."
  fi
}

protect main
protect develop
echo "Terminé. (En FT-1 : ajoute le job CI 'garde-fous' aux 'required status checks'.)"
