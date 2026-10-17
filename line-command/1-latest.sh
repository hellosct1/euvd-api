#!/usr/bin/env bash

# =============================================================================
# Dernières vulnérabilités publiées — /api/lastvulnerabilities
# Usage : ./1-latest.sh
# =============================================================================


echo "Dernières vulnérabilités publiées"
echo "Résultat au format JSON"

curl -fsS https://euvdservices.enisa.europa.eu/api/lastvulnerabilities | jq .