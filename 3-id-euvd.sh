#!/usr/bin/env bash
# =============================================================================
# 3-id.sh — Détail d'une vulnérabilité EUVD par ID
# Usage   : ./3-id.sh --id=EUVD-2025-13580
# =============================================================================

set -euo pipefail

readonly BASE_URL="https://euvdservices.enisa.europa.eu"

ID=""

for arg in "$@"; do
    case "$arg" in
        --id=*) ID="${arg#*=}" ;;
        *)
            echo "Argument inconnu : $arg" >&2
            echo "Usage : $0 --id=<EUVD-XXXX-XXXXX>" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$ID" ]]; then
    echo "Erreur : --id est obligatoire." >&2
    echo "Usage : $0 --id=<EUVD-XXXX-XXXXX>" >&2
    exit 1
fi

echo "URL : ${BASE_URL}/api/enisaid?id=${ID}"
echo

response=$(curl -sf "${BASE_URL}/api/enisaid?id=${ID}" || true)

if [[ -z "$response" ]]; then
    echo "Aucune réponse reçue pour l'ID : ${ID}" >&2
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

