#!/usr/bin/env bash
# =============================================================================
# Téléchargement du dump KEV — /api/kev/dump
# Usage : ./7-euvd-download.sh
# =============================================================================

echo "Téléchargement du dump KEV"
echo "Résultat au format JSON"

curl -fsS  https://euvdservices.enisa.europa.eu/api/kev/dump -o euvd-kev.json