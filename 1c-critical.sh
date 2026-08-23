#!/usr/bin/env bash
# Vulnérabilités critiques (score CVSS élevé) — /api/criticalvulnerabilities
# Dépendances : curl, jq

set -euo pipefail

readonly BASE_URL="https://euvdservices.enisa.europa.eu"

response=$(curl -sf "${BASE_URL}/api/criticalvulnerabilities")

printf "| %-22s | %5s | %3s | %6s | %-20s | %-40s | %-60s |\n" \
    "ID EUVD" "Score" "Ver" "EPSS%" "Publié" "CVE / GHSA" "Description"
printf "| %-22s | %5s | %3s | %6s | %-20s | %-40s | %-60s |\n" \
    "----------------------" "-----" "---" "------" "--------------------" "----------------------------------------" "------------------------------------------------------------"

echo "$response" | jq -r '.[] |
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
