#!/usr/bin/env bash
# =============================================================================
# Recherche d'une vulnérabilité spécifique par ID — /api/advisory
# Usage : ./3-id-advisory.sh
# =============================================================================


echo "Recherche d'une vulnérabilité spécifique par ID"
echo "Résultat au format JSON"

curl -fsS "https://euvdservices.enisa.europa.eu/api/advisory?id=cisco-sa-ata19x-multi-RDTEqRsy" | jq 

