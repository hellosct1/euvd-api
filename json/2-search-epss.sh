#!/usr/bin/env bash

curl -fsS "https://euvdservices.enisa.europa.eu/api/search?fromEpss=50&exploited=true&size=100" | jq . 

