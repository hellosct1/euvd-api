#!/usr/bin/env bash

# =============================================================================
# Recherche de vulnérabilités avec un score EPSS élevé — /api/search
# Usage : ./2-search-epss.sh
# =============================================================================


echo "Vulnérabilités avec un score EPSS élevé"
echo "Résultat au format JSON"

curl -fsS "https://euvdservices.enisa.europa.eu/api/search?fromEpss=50&exploited=true&size=100" | jq . 

