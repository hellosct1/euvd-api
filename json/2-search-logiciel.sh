#!/usr/bin/env bash


curl -fsS "https://euvdservices.enisa.europa.eu/api/search?vendor=Drupal&fromDate=2025-01-01&toDate=2025-12-31&size=100" | jq .