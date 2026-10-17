#!/usr/bin/env bash
# Vulnérabilités critiques (score CVSS élevé) — /api/criticalvulnerabilities

curl -fsS https://euvdservices.enisa.europa.eu/api/criticalvulnerabilities | jq .