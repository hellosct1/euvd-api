#!/usr/bin/env bash
# =============================================================================
# 2-search-remote.sh — Recherche de vulnérabilités remote sur l'API EUVD
# Usage : ./2-search-remote.sh [--fromScore=<0-10>] [--toScore=<0-10>] [--exploited=true|false] [--text=<terme>] [--size=<n>]
# Exemple : ./2-search-remote.sh --fromScore=8 --toScore=10 --exploited=true --text=remote --size=100
# =============================================================================

set -euo pipefail

readonly BASE_URL="https://euvdservices.enisa.europa.eu"

print_help() {
        cat <<EOF
Usage : $0 [options]

Options :
    --fromScore=<0-10>     Score CVSS minimum
    --toScore=<0-10>       Score CVSS maximum
    --exploited=true|false Filtre les vulnerabilites exploitees
    --text=<terme>         Terme recherche dans les vulnerabilites
    --size=<n>             Nombre de resultats (defaut : 100)
    --help, -h             Affiche cette aide

Exemples :
    $0 --fromScore=8 --toScore=10 --exploited=true --text=remote --size=100
EOF
}

FROM_SCORE="8"
TO_SCORE="10"
EXPLOITED="true"
TEXT="remote"
SIZE="100"

for arg in "$@"; do
    case "$arg" in
        --help|-h)
            print_help
            exit 0
            ;;
        --fromScore=*) FROM_SCORE="${arg#*=}" ;;
        --toScore=*)   TO_SCORE="${arg#*=}" ;;
        --exploited=*) EXPLOITED="${arg#*=}" ;;
        --text=*)      TEXT="${arg#*=}" ;;
        --size=*)      SIZE="${arg#*=}" ;;
        *)
            echo "Argument inconnu : $arg" >&2
            print_help >&2
            exit 1
            ;;
    esac
done


QUERY="size=${SIZE}"
[[ -n "$FROM_SCORE" ]] && QUERY+="&fromScore=${FROM_SCORE}"
[[ -n "$TO_SCORE"   ]] && QUERY+="&toScore=${TO_SCORE}"
[[ -n "$EXPLOITED" ]] && QUERY+="&exploited=${EXPLOITED}"
[[ -n "$TEXT"      ]] && QUERY+="&text=${TEXT}"

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

