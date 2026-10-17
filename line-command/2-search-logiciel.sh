#!/usr/bin/env bash
# =============================================================================
# Recherche de vulnérabilités pour un logiciel spécifique — /api/search
# Usage : ./2-search-logiciel.sh
# =============================================================================


echo "Vulnérabilités pour le logiciel Drupal"
echo "Résultat au format JSON"

curl -fsS "https://euvdservices.enisa.europa.eu/api/search?vendor=Drupal&fromDate=2025-01-01&toDate=2025-12-31&size=100" | jq .