#!/usr/bin/env bash
# =============================================================================
# Recherche filtrée sur l'API EUVD 
# Help : ./2-search-logiciel.sh --help
# Usage : ./2-search-logiciel.sh [--vendor=<nom>] [--fromDate=YYYY-MM-DD] [--toDate=YYYY-MM-DD]
#                         [--size=<n>] [--fromEpss=<0-100>] [--exploited=true]
# Exemple : ./2-search-logiciel.sh --vendor=nodejs --fromDate=2026-01-01 --size=20
# Exemple : ./2-search-logiciel.sh --fromEpss=50 --exploited=true --size=100
# =============================================================================

set -euo pipefail

readonly BASE_URL="https://euvdservices.enisa.europa.eu"

print_help() {
        cat <<EOF
Usage : $0 [options]

Options :
    --vendor=<nom>         Filtre par nom d'editeur ou logiciel
    --fromDate=YYYY-MM-DD  Date de debut
    --toDate=YYYY-MM-DD    Date de fin
    --fromEpss=<0-100>     Score EPSS minimum
    --exploited=true       Filtre les vulnerabilities exploitees
    --size=<n>             Nombre de resultats (defaut : 10)
    --help, -h             Affiche cette aide

Exemples :
    $0 --vendor=nodejs --fromDate=2026-01-01 --size=20
    $0 --fromEpss=50 --exploited=true --size=100
EOF
}

VENDOR=""
FROM_DATE=""
TO_DATE=""
FROM_EPSS=""
EXPLOITED=""
SIZE="10"

for arg in "$@"; do
    case "$arg" in
        --help|-h)
            print_help
            exit 0
            ;;
        --vendor=*)    VENDOR="${arg#*=}" ;;
        --fromDate=*)  FROM_DATE="${arg#*=}" ;;
        --toDate=*)    TO_DATE="${arg#*=}" ;;
        --fromEpss=*)  FROM_EPSS="${arg#*=}" ;;
        --exploited=*) EXPLOITED="${arg#*=}" ;;
        --size=*)      SIZE="${arg#*=}" ;;
        *)
            echo "Argument inconnu : $arg" >&2
            print_help >&2
            exit 1
            ;;
    esac
done


QUERY="size=${SIZE}"
[[ -n "$VENDOR"    ]] && QUERY+="&vendor=${VENDOR}"
[[ -n "$FROM_DATE" ]] && QUERY+="&fromDate=${FROM_DATE}"
[[ -n "$TO_DATE"   ]] && QUERY+="&toDate=${TO_DATE}"
[[ -n "$FROM_EPSS" ]] && QUERY+="&fromEpss=${FROM_EPSS}"
[[ -n "$EXPLOITED" ]] && QUERY+="&exploited=${EXPLOITED}"

echo "URL : ${BASE_URL}/api/search?${QUERY}"

response=$(curl -sf "${BASE_URL}/api/search?${QUERY}" || true)

if [[ -z "$response" ]]; then
    echo "Aucune réponse reçue." >&2
    exit 1
fi

total=$(echo "$response" | jq -r '.total // 0')
echo "Total : ${total}"
echo

# Résultat
printf "| %-22s | %5s | %3s | %6s | %-20s | %-40s | %-60s |\n" \
    "ID EUVD" "Score" "Ver" "EPSS%" "Publié" "CVE / GHSA" "Description"
printf "| %-22s | %5s | %3s | %6s | %-20s | %-40s | %-60s |\n" \
    "----------------------" "-----" "---" "------" "--------------------" "----------------------------------------" "------------------------------------------------------------"

echo "$response" | jq -r '.items[] |
    [ .id,
      ( .baseScore // -1 | tostring ),
      ( .baseScoreVersion // "?" ),
      ( .epss // 0 | tostring ),
      ( .datePublished // "" | .[0:20] ),
      ( .aliases // "" | split("\n") | map(select(startswith("CVE-") or startswith("GHSA-"))) | join(", ") | .[0:40] ),
      ( .description // "" | gsub("\n";" ") | .[0:60] )
    ] | @tsv' | \
while IFS=$'\t' read -r id score ver epss date aliases desc; do
    printf "| %-22s | %5s | %3s | %6s | %-20s | %-40s | %-60s |\n" \
        "$id" "$score" "$ver" "$epss" "$date" "$aliases" "$desc"
done

