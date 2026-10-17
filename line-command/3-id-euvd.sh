#!/usr/bin/env bash
# =============================================================================
# Recherche d'une vulnérabilité spécifique par ID — /api/enisaid
# Usage : ./3-id-euvd.sh
# =============================================================================

echo "Recherche d'une vulnérabilité spécifique par ID EUVD"
echo "Résultat au format JSON"

curl -fsS "https://euvdservices.enisa.europa.eu/api/enisaid?id=EUVD-2025-4893" | jq .