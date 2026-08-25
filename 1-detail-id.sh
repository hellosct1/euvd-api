#!/usr/bin/env bash
# Détail complet de la dernière vulnérabilité critique — /api/enisaid

set -euo pipefail

readonly BASE_URL="https://euvdservices.enisa.europa.eu"

first_id=$(curl -sf "${BASE_URL}/api/criticalvulnerabilities" | jq -r '.[0].id')
response=$(curl -sf "${BASE_URL}/api/enisaid?id=${first_id}")

echo "Détail complet de la dernière vulnérabilité critique"

# Résultat
printf "| %-20s | %s |\n" "Champ" "Valeur"
printf "| %-20s | %s |\n" "--------------------" "------------------------------------------------------------"

echo "$response" | jq -r '
    "ID EUVD\t\(.id // "N/A")",
    "Score CVSS\t\(.baseScore // "N/A") (\(.baseScoreVersion // "?"))",
    "Vecteur CVSS\t\(.baseScoreVector // "N/A")",
    "EPSS\t\(.epss // 0)%",
    "Exploité depuis\t\(.exploitedSince // "non signalé")",
    "Assigneur\t\(.assigner // "N/A")",
    "Publié\t\(.datePublished // "N/A")",
    "Mis à jour\t\(.dateUpdated // "N/A")",
    "CVE / GHSA\t\(.aliases // "" | split("\n") | map(select(startswith("CVE-") or startswith("GHSA-"))) | join(", "))",
    "Vendeurs\t\([.enisaIdVendor[]?.vendor.name] | join(", "))",
    "Produits\t\([.enisaIdProduct[]? | "\(.product.name) \(.product_version)"] | join(" | ") | .[0:80])",
    "Description\t\(.description // "" | gsub("\n";" ") | .[0:80])"
' | \
while IFS=$'\t' read -r key val; do
    printf "| %-20s | %-60s |\n" "$key" "$val"
done
