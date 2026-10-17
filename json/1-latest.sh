#!/usr/bin/env bash
# Dernières vulnérabilités publiées — /api/lastvulnerabilities


curl -fsS https://euvdservices.enisa.europa.eu/api/lastvulnerabilities | jq .