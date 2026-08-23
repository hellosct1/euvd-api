 
#!/usr/bin/env bash
# =============================================================================
# euvd-query.sh — Interrogation de l'API EUVD (ENISA)
# Usage : ./euvd-query.sh [option]
# Dépendances : curl, jq
# =============================================================================

set -euo pipefail

readonly BASE_URL="https://euvdservices.enisa.europa.eu"

# Vérification des dépendances
check_deps() {
    for dep in curl jq; do
        if ! command -v "$dep" &>/dev/null; then
            echo "[ERREUR] $dep est requis mais non installé." >&2
            exit 1
        fi
    done
}

# Affichage coloré
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_vuln() {
    local json="$1"
    echo "$json" | jq -r '.[] | 
        "\n\(.id // "N/A") — Score: \(.baseScore // "N/A") (\(.baseScoreVersion // "?"))" +
        "\n  Description : \(.description // "N/A" | .[0:120])..." +
        "\n  Publié      : \(.datePublished // "N/A")" +
        "\n  EPSS        : \(.epss // 0)%" +
        "\n  Alias CVE   : \(.aliases // "N/A" | gsub("\n"; ", "))"'
}

# --- Fonctions par endpoint ---

cmd_latest() {
    echo -e "${CYAN}=== Dernières vulnérabilités ===${NC}"
    local response
    response=$(curl -sf "${BASE_URL}/api/lastvulnerabilities")
    print_vuln "$response"
}

cmd_exploited() {
    echo -e "${RED}=== Vulnérabilités activement exploitées ===${NC}"
    local response
    response=$(curl -sf "${BASE_URL}/api/exploitedvulnerabilities")
    print_vuln "$response"
}

cmd_critical() {
    echo -e "${YELLOW}=== Vulnérabilités critiques ===${NC}"
    local response
    response=$(curl -sf "${BASE_URL}/api/criticalvulnerabilities")
    print_vuln "$response"
}

cmd_search() {
    local vendor="${1:-}"
    local product="${2:-}"
    local min_score="${3:-7}"
    local exploited="${4:-false}"
    local size="${5:-20}"

    echo -e "${GREEN}=== Recherche : vendor=${vendor} product=${product} score>=${min_score} exploited=${exploited} ===${NC}"

    local url="${BASE_URL}/api/vulnerabilities?fromScore=${min_score}&size=${size}"
    [[ -n "$vendor"   ]] && url+="&vendor=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${vendor}'))")"
    [[ -n "$product"  ]] && url+="&product=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${product}'))")"
    [[ "$exploited" == "true" ]] && url+="&exploited=true"

    local response
    response=$(curl -sf "$url")
    local total
    total=$(echo "$response" | jq -r '.total')
    echo "Total trouvé : $total"
    echo "$response" | jq -r '.items[] | "  \(.id) | Score: \(.baseScore) | \(.description | .[0:80])..."'
}

cmd_by_euvd_id() {
    local id="${1:?Usage: $0 euvdid <EUVD-XXXX-XXXXX>}"
    echo -e "${CYAN}=== Détail EUVD : ${id} ===${NC}"
    curl -sf "${BASE_URL}/api/enisaid?id=${id}" | jq '.'
}

cmd_by_cve_id() {
    local cve="${1:?Usage: $0 cve <CVE-XXXX-XXXXX>}"
    echo -e "${CYAN}=== Détail CVE : ${cve} ===${NC}"
    curl -sf "${BASE_URL}/api/vulnerability?id=${cve}" | jq '.'
}

cmd_by_advisory_id() {
    local adv="${1:?Usage: $0 advisory <advisory-id>}"
    echo -e "${CYAN}=== Advisory : ${adv} ===${NC}"
    curl -sf "${BASE_URL}/api/advisory?id=${adv}" | jq '.'
}

usage() {
    cat <<EOF
Usage: $0 <commande> [arguments]

Commandes disponibles :
  latest                          Affiche les 8 dernières vulnérabilités
  exploited                       Affiche les 8 dernières exploitées
  critical                        Affiche les 8 dernières critiques
  search [vendor] [product] [score_min] [exploited] [size]
                                  Recherche filtrée
  euvdid <EUVD-XXXX-XXXXX>        Détail par ID EUVD
  cve <CVE-XXXX-XXXXX>            Détail par ID CVE
  advisory <advisory-id>          Détail d'un avis de sécurité

Exemples :
  $0 latest
  $0 exploited
  $0 search Microsoft Windows 9 true 50
  $0 euvdid EUVD-2025-13580
  $0 cve CVE-2024-0864
  $0 advisory cisco-sa-ata19x-multi-RDTEqRsy
EOF
}

# --- Main ---
check_deps

case "${1:-help}" in
    latest)   cmd_latest ;;
    exploited) cmd_exploited ;;
    critical) cmd_critical ;;
    search)   cmd_search "${2:-}" "${3:-}" "${4:-7}" "${5:-false}" "${6:-20}" ;;
    euvdid)   cmd_by_euvd_id "${2:-}" ;;
    cve)      cmd_by_cve_id "${2:-}" ;;
    advisory) cmd_by_advisory_id "${2:-}" ;;
    *)        usage ;;
esac