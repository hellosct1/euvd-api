#!/usr/bin/env bash

curl -fsS "https://euvdservices.enisa.europa.eu/api/search?fromScore=8&toScore=10&exploited=true&text=remote&size=100" | jq .