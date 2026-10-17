#!/usr/bin/env bash
# =============================================================================
# Recherche d'une vulnérabilité spécifique par ID CVE — /api/search
# Usage : ./3-id-cve.sh
# =============================================================================

set -euo pipefail

echo "Recherche d'une vulnérabilité spécifique par ID CVE"
echo "Résultat au format  HTML"


curl -fsS "https://euvd.enisa.europa.eu/vulnerability/CVE-2024-0864" 

