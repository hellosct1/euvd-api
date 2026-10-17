#!/usr/bin/env bash
# =============================================================================
# Distribution des scores CVSS par fournisseur
# Usage : ./8-query-offline-score.sh <vendor> [fichier.json]
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

printf 'Répartition des scores CVSS pour le fournisseur : %s\n' "$VENDOR"

printf '| %-20s | %8s |\n' "Niveau" "Nombre"
printf '| %-20s | %8s |\n' "--------------------" "--------"
jq -r --arg vendor "$VENDOR" '
    [ .[]
      | select(any(.enisaIdVendor[]?.vendor.name;
          (ascii_downcase | contains($vendor | ascii_downcase))))
      | (.baseScore // -1) as $score
      | if $score >= 9 then "Critique (9–10)"
        elif $score >= 7 then "Élevé (7–8.9)"
        elif $score >= 4 then "Moyen (4–6.9)"
        elif $score >= 0 then "Faible (0–3.9)"
        else "Non évalué"
        end
    ]
    | sort
    | group_by(.)
    | map({niveau: .[0], nombre: length})
    | sort_by(-.nombre)[]
    | [.niveau, (.nombre | tostring)]
    | @tsv
' "$JSON_FILE" | while IFS=$'\t' read -r niveau nombre; do
    printf '| %-20s | %8s |\n' "$niveau" "$nombre"
done