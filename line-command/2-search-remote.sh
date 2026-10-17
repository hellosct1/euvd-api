#!/usr/bin/env bash
# =============================================================================
# Recherche de vulnérabilités pour des vulnérabilités à distance — /api/search
# Usage : ./2-search-remote.sh
# =============================================================================


echo "Recherche de vulnérabilités pour des vulnérabilités à distance (remote)"
echo "Résultat au format JSON"

curl -fsS "https://euvdservices.enisa.europa.eu/api/search?fromScore=8&toScore=10&exploited=true&text=remote&size=100" | jq .