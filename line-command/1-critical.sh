#!/usr/bin/env bash

# =============================================================================
# Vulnérabilités critiques (score CVSS élevé) — /api/criticalvulnerabilities
# Usage : ./1-critical.sh
# =============================================================================

echo "Vulnérabilités critiques (score CVSS élevé)"
echo "Résultat au format JSON"

curl -fsS https://euvdservices.enisa.europa.eu/api/criticalvulnerabilities | jq .