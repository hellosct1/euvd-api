#!/usr/bin/env bash
# =============================================================================
# Recherche de l'état d'exploitation d'une vulnérabilité spécifique — /api/search
# Usage : ./4-check-euvd.sh
# =============================================================================

echo "Recherche de l'état d'exploitation d'une vulnérabilité spécifique"
echo "Résultat au format JSON"

set -euo pipefail
CVE="${1:?usage: check-euvd.sh CVE-YYYY-NNNN}"
if [[ ! "$CVE" =~ ^CVE-[0-9]{4}-[0-9]{4,}$ ]]; then
  echo "Identifiant CVE invalide: $CVE" >&2
  exit 1
fi

BASE_URL="https://euvdservices.enisa.europa.eu/api/search"
JSON=$(curl -fsS --retry 3 -A 'euvd-api-check/1.0' --get \
  --data-urlencode "text=$CVE" --data-urlencode "size=100" "$BASE_URL")
ENTRY=$(jq -c --arg cve "$CVE" \
  '[.items[]? | select(((.aliases // "") | split("\n")) | index($cve))] | first // empty' \
  <<<"$JSON")
if [[ -z "$ENTRY" ]]; then
  echo "EUVD ne trouve pas de correspondance exacte pour $CVE" >&2
  exit 1
fi

EXPLOITED_JSON=$(curl -fsS --retry 3 -A 'euvd-api-check/1.0' --get \
  --data-urlencode "text=$CVE" --data-urlencode "size=100" \
  --data-urlencode "exploited=true" "$BASE_URL")
ID=$(jq -r '.id // empty' <<<"$ENTRY")
SCORE=$(jq -r '.baseScore // -1' <<<"$ENTRY")
EXPLOITED=$(jq -r --arg cve "$CVE" \
  'if any(.items[]?; (((.aliases // "") | split("\n")) | index($cve)) != null) then "yes" else "no" end' \
  <<<"$EXPLOITED_JSON")
printf 'CVE=%s EUVD=%s CVSS=%s exploited=%s
' "$CVE" "$ID" "$SCORE" "$EXPLOITED"
if [ "$EXPLOITED" = "yes" ]; then
  echo "Blocage: vulnérabilité signalée comme exploitée" >&2
  exit 2
fi
