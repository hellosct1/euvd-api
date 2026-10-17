#!/usr/bin/env bash
# =============================================================================
# Téléchargement des vulnérabilités EUVD par fournisseur
#
# Ce script télécharge toutes les pages correspondant au fournisseur demandé,
# sauvegarde les pages JSON puis les fusionne en un seul fichier.
#
# Argument requis : --vendor <nom> (ex. PHP)
# Usage  : ./7-euvd-dl-logiciel.sh --vendor <nom> [répertoire_sortie]
# Exemple: ./7-euvd-dl-logiciel.sh --vendor PHP
# Sortie : <dir>/euvd_<vendor>_YYYY-MM-DD.json
#          <dir>/pages/<vendor>/page_XXXX.json
#
# Dépendances : curl, jq
# =============================================================================

set -euo pipefail

readonly BASE_URL="https://euvdservices.enisa.europa.eu"
readonly PAGE_SIZE=100
readonly DATE=$(date +%Y-%m-%d)
readonly DELAY=1   # secondes entre chaque requête (respect du serveur)

VENDOR=""
OUTPUT_DIR=""
POSITIONAL_OUTPUT_DIR=""

usage() {
    printf 'Usage : %s --vendor <nom> [répertoire_sortie]\n' "$0"
    printf 'Argument obligatoire : --vendor <nom> (ex. PHP)\n'
    printf 'Répertoire par défaut : ../euvd-api-data/<vendor>\n'
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --vendor)
            if [[ "$#" -lt 2 || -z "$2" ]]; then
                echo "Erreur : --vendor nécessite un nom." >&2
                usage >&2
                exit 2
            fi
            VENDOR="$2"
            shift 2
            ;;
        --vendor=*)
            VENDOR="${1#*=}"
            if [[ -z "$VENDOR" ]]; then
                echo "Erreur : --vendor nécessite un nom." >&2
                usage >&2
                exit 2
            fi
            shift
            ;;
        --output)
            if [[ "$#" -lt 2 || -z "$2" ]]; then
                echo "Erreur : --output nécessite un répertoire." >&2
                usage >&2
                exit 2
            fi
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --output=*)
            OUTPUT_DIR="${1#*=}"
            if [[ -z "$OUTPUT_DIR" ]]; then
                echo "Erreur : --output nécessite un répertoire." >&2
                exit 2
            fi
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        --*)
            echo "Option inconnue : $1" >&2
            usage >&2
            exit 2
            ;;
        *)
            if [[ -n "$POSITIONAL_OUTPUT_DIR" ]]; then
                echo "Erreur : un seul répertoire de sortie peut être indiqué." >&2
                usage >&2
                exit 2
            fi
            POSITIONAL_OUTPUT_DIR="$1"
            shift
            ;;
    esac
done

if [[ -z "$VENDOR" ]]; then
    echo "Erreur : le fournisseur est obligatoire; utilisez --vendor <nom>." >&2
    usage >&2
    exit 2
fi

VENDOR_SLUG=$(printf '%s' "$VENDOR" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/_/g')
OUTPUT_DIR="${OUTPUT_DIR:-${POSITIONAL_OUTPUT_DIR:-data}}"
PAGES_DIR="${OUTPUT_DIR}/pages/${VENDOR_SLUG}"
FINAL_FILE="${OUTPUT_DIR}/euvd_${VENDOR_SLUG}_${DATE}.json"

mkdir -p "$PAGES_DIR"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

search_page() {
    local size="$1"
    local page="$2"
    local output_file="${3:-}"
    local -a request=(curl -fsS --retry 3 --get "${BASE_URL}/api/search"
        --data-urlencode "vendor=${VENDOR}"
        --data-urlencode "size=${size}"
        --data-urlencode "page=${page}")

    if [[ -n "$output_file" ]]; then
        "${request[@]}" --output "$output_file"
    else
        "${request[@]}"
    fi
}

# Obtenir le nombre total de vulnérabilités
log "Recherche du fournisseur : ${VENDOR}"
log "Interrogation initiale pour obtenir le total..."
first_page=$(search_page 1 0)
total=$(echo "$first_page" | jq -r '.total')
pages=$(( (total + PAGE_SIZE - 1) / PAGE_SIZE ))
log "Total : ${total} vulnérabilités — ${pages} pages à télécharger"

# Téléchargement page par page
downloaded=0
for ((page=0; page<pages; page++)); do
    page_file="${PAGES_DIR}/page_$(printf '%04d' "$page").json"

    if [[ -f "$page_file" ]]; then
        log "Page ${page} déjà présente, ignorée."
        continue
    fi

    log "Téléchargement page $((page+1))/${pages}..."
    search_page "$PAGE_SIZE" "$page" "$page_file"

    count=$(jq '.items | length' "$page_file")
    log "  -> ${count} entrées sauvegardées dans ${page_file}"
    downloaded=$((downloaded + count))

    sleep "$DELAY"
done

log "Téléchargement terminé. Fusion des pages..."

# Fusion de toutes les pages en un seul fichier JSON
if (( pages == 0 )); then
    printf '[]\n' > "$FINAL_FILE"
else
    jq -s '[.[].items[]]' "${PAGES_DIR}"/page_*.json > "$FINAL_FILE"
fi

final_count=$(jq 'length' "$FINAL_FILE")
log "Fichier final : ${FINAL_FILE} (${final_count} entrées)"
log "Terminé."
