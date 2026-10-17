#!/usr/bin/env bash
# =============================================================================
# 8-query-date.sh — Vulnérabilités d'un fournisseur publiées durant les 7 derniers jours
# Usage : ./8-query-date.sh <vendor> [fichier.json]
# Dépendance : jq
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DATA_ROOT="${SCRIPT_DIR}/data"
DATE="$(date +%Y-%m-%d)"

usage() {
    printf 'Usage : %s <vendor> [fichier.json]\n' "$0"
    printf 'Exemple : %s <vendor>\n' "$0"
    printf 'Fichier JSON par défaut : %s/euvd_<vendor>_%s.json\n' "$DATA_ROOT" "$DATE"
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

if [[ "$#" -lt 1 || -z "${1:-}" ]]; then
    echo "Erreur : le nom du fournisseur est obligatoire." >&2
    usage >&2
    exit 2
fi

if [[ "$#" -gt 2 ]]; then
    usage >&2
    exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Erreur : jq est requis mais n'est pas installé." >&2
    exit 1
fi

VENDOR="$1"
VENDOR_SLUG="$(printf '%s' "$VENDOR" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/_/g')"
DEFAULT_FILE="${DATA_ROOT}/euvd_${VENDOR_SLUG}_${DATE}.json"
JSON_FILE="${2:-$DEFAULT_FILE}"
if [[ ! -f "$JSON_FILE" ]]; then
    echo "Erreur : fichier EUVD introuvable : $JSON_FILE" >&2
    echo "Téléchargez d'abord les données avec ./7-euvd-dl-logiciel.sh --vendor $VENDOR." >&2
    exit 1
fi

printf 'Vulnérabilités publiées durant les 7 derniers jours pour : %s\n' "$VENDOR"
printf '| %-22s | %-26s | %-30s | %5s |\n' "ID EUVD" "Publié" "Vendeurs" "CVSS"
printf '| %-22s | %-26s | %-30s | %5s |\n' \
    "----------------------" "--------------------------" "------------------------------" "-----"

# datePublished est un texte du type "Feb 29, 2024, 12:56:23 PM"
jq -r --arg vendor "$VENDOR" '
    (now - 7 * 86400) as $limit
    | [ .[]
        | select(any(.enisaIdVendor[]?.vendor.name;
            (ascii_downcase | contains($vendor | ascii_downcase))))
        | . + {ts: (.datePublished | strptime("%b %d, %Y, %I:%M:%S %p") | mktime)}
        | select(.ts >= $limit)
      ]
    | sort_by(-.ts)[]
    | [(.id // "N/A"), .datePublished,
       ([.enisaIdVendor[]?.vendor.name] | unique | join(", ") | .[0:30]),
       ((.baseScore // "N/A") | tostring)]
    | @tsv
' "$JSON_FILE" | while IFS=$'\t' read -r id date vendors score; do
    printf '| %-22s | %-26s | %-30s | %5s |\n' "$id" "$date" "$vendors" "$score"
done