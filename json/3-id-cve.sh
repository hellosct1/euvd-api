#!/usr/bin/env bash
curl -fsS "https://euvdservices.enisa.europa.eu/api/vulnerability?id=CVE-2024-0864" | jq .