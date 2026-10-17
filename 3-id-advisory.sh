#!/usr/bin/env bash
# =============================================================================
# Détail d'un advisory EUVD par ID
# Usage   : ./3-id-advisory.sh [--id=cisco-sa-ata19x-multi-RDTEqRsy]
# =============================================================================

set -euo pipefail

readonly BASE_URL="https://euvdservices.enisa.europa.eu"

ID="cisco-sa-ata19x-multi-RDTEqRsy"

for arg in "$@"; do
    case "$arg" in
        --id=*) ID="${arg#*=}" ;;
        *)
            echo "Argument inconnu : $arg" >&2
            echo "Usage : $0 [--id=<advisory-id>]" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$ID" ]]; then
    echo "Erreur : l'identifiant advisory ne peut pas être vide." >&2
    echo "Usage : $0 [--id=<advisory-id>]" >&2
    exit 1
fi

echo "URL : ${BASE_URL}/api/advisory?id=${ID}"
curl -fsS --retry 3 --get --data-urlencode "id=${ID}" \
    "${BASE_URL}/api/advisory" | jq .

