#!/usr/bin/env bash
# =============================================================================
# 3-id-cve.sh — Détail d'une vulnérabilité EUVD par CVE
# Usage   : ./3-id-cve.sh [--id=CVE-2024-0864]
# =============================================================================

set -euo pipefail

readonly BASE_URL="https://euvdservices.enisa.europa.eu"

CVE="CVE-2024-0864"

for arg in "$@"; do
    case "$arg" in
        --id=*) CVE="${arg#*=}" ;;
        *)
            echo "Argument inconnu : $arg" >&2
            echo "Usage : $0 [--id=CVE-YYYY-NNNN]" >&2
            exit 1
            ;;
    esac
done

if [[ ! "$CVE" =~ ^CVE-[0-9]{4}-[0-9]{4,}$ ]]; then
    echo "Identifiant CVE invalide : $CVE" >&2
    exit 1
fi

echo "URL : ${BASE_URL}/api/search?text=${CVE}&size=100"
echo

search=$(curl -fsS --retry 3 -A 'euvd-api-check/1.0' --get \
    --data-urlencode "text=${CVE}" --data-urlencode "size=100" \
    "${BASE_URL}/api/search")
response=$(jq -c --arg cve "$CVE" \
    '[.items[]? | select(((.aliases // "") | split("\n")) | index($cve))] | first // empty' \
    <<<"$search")

if [[ -z "$response" ]]; then
    echo "Aucune correspondance exacte trouvée pour le CVE : ${CVE}" >&2
    exit 1
fi

# Extraction des champs principaux
echo "$response" | jq -r '
    "ID EUVD      : \(.id // "N/A")",
    "Score CVSS   : \(.baseScore // "N/A") (\(.baseScoreVersion // "?"))",
    "Vecteur      : \(.baseScoreVector // "N/A")",
    "EPSS         : \(.epss // 0)%",
    "Exploité dep.: \(.exploitedSince // "non signalé")",
    "Assigneur    : \(.assigner // "N/A")",
    "Publié       : \(.datePublished // "N/A")",
    "Mis à jour   : \(.dateUpdated // "N/A")",
    "Aliases      : \(.aliases // "" | gsub("\n"; "  "))"'

echo
echo "--- Vendeurs ---"
echo "$response" | jq -r '.enisaIdVendor[]?.vendor.name // empty' 2>/dev/null | sed 's/^/  /'

echo
echo "--- Produits ---"
echo "$response" | jq -r '.enisaIdProduct[]? | "  \(.product.name // "N/A")  v\(.product_version // "?")"' 2>/dev/null

echo
echo "--- Description ---"
echo "$response" | jq -r '.description // "N/A"'

echo
echo "--- Références ---"
echo "$response" | jq -r '.references // ""' | tr '\n' '\n' | grep -v '^$' | sed 's/^/  /'

