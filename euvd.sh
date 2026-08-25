#!/usr/bin/env bash
#
# euvd.sh - Client shell pour l'API EUVD (European Union Vulnerability Database)
#
# Documentation (non officielle) : https://github.com/bytew0lf/EUVD-API
# Base URL de l'API              : https://euvdservices.enisa.europa.eu/api
#
# Dépendances : curl, jq (optionnel, pour un affichage joli du JSON)
#
# Utilisation :
#   ./euvd.sh search [options]        Recherche avancée de vulnérabilités
#   ./euvd.sh last                    8 dernières vulnérabilités publiées
#   ./euvd.sh exploited               8 dernières vulnérabilités exploitées
#   ./euvd.sh critical                8 dernières vulnérabilités critiques
#   ./euvd.sh id <EUVD-ID>             Détails d'une vulnérabilité par son ID EUVD
#   ./euvd.sh advisory <ADVISORY-ID>   Détails d'une advisory par son ID
#   ./euvd.sh kev                      Dump complet des vulnérabilités exploitées connues (KEV)
#
# Options pour "search" :
#   -p, --product   <nom>      Nom du produit (ex: "Microsoft Windows")
#   -v, --vendor    <nom>      Nom du vendeur (ex: "Oracle")
#   -a, --assigner  <nom>      CNA assignant (ex: "oracle")
#   -t, --text      <texte>    Recherche texte libre dans la description
#   -f, --from-date <date>     Date de début (YYYY-MM-DD)
#   -T, --to-date   <date>     Date de fin (YYYY-MM-DD)
#   -s, --from-score <n>       Score CVSS minimum (0-10)
#   -S, --to-score   <n>       Score CVSS maximum (0-10)
#   -e, --exploited            Filtrer uniquement les vulnérabilités exploitées
#   -n, --size      <n>        Nombre de résultats par page (1-100, défaut 10)
#   -P, --page      <n>        Numéro de page (défaut 0)
#   -o, --output    <fichier>  Enregistrer le résultat JSON dans un fichier
#
# Exemples :
#   ./euvd.sh search -v Oracle -e -n 20
#   ./euvd.sh search -t "remote code execution" -s 9 -S 10
#   ./euvd.sh id EUVD-2024-45012
#   ./euvd.sh last -o dernieres.json
#
set -euo pipefail

BASE_URL="https://euvdservices.enisa.europa.eu/api"

# Détection de jq pour un affichage plus lisible (facultatif)
HAS_JQ=false
if command -v jq >/dev/null 2>&1; then
  HAS_JQ=true
fi

usage() {
  sed -n '2,33p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

# urlencode une chaîne (RFC 3986) en utilisant les fonctionnalités de curl
urlencode() {
  local str="$1"
  curl -Gso /dev/null -w "%{url_effective}" --data-urlencode "x=${str}" "http://localhost" | sed 's/^.*x=//'
}

# Effectue la requête HTTP et affiche/enregistre le résultat
do_request() {
  local url="$1"
  local output_file="${2:-}"

  local response
  local http_code

  response=$(curl -sS -w "\n%{http_code}" --request GET \
    --url "${url}" \
    --header 'accept: application/json')

  http_code=$(echo "${response}" | tail -n1)
  body=$(echo "${response}" | sed '$d')

  if [[ "${http_code}" -lt 200 || "${http_code}" -ge 300 ]]; then
    echo "Erreur HTTP ${http_code} lors de l'appel à l'API EUVD." >&2
    echo "${body}" >&2
    exit 1
  fi

  if [[ -n "${output_file}" ]]; then
    echo "${body}" > "${output_file}"
    echo "Résultat enregistré dans : ${output_file}"
  else
    if [[ "${HAS_JQ}" == true ]]; then
      echo "${body}" | jq .
    else
      echo "${body}"
    fi
  fi
}

cmd_search() {
  local product="" vendor="" assigner="" text=""
  local from_date="" to_date="" from_score="0" to_score="10"
  local from_epss="0" to_epss="100" exploited="false"
  local size="10" page="0" output_file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--product)     product="$2"; shift 2 ;;
      -v|--vendor)      vendor="$2"; shift 2 ;;
      -a|--assigner)    assigner="$2"; shift 2 ;;
      -t|--text)        text="$2"; shift 2 ;;
      -f|--from-date)   from_date="$2"; shift 2 ;;
      -T|--to-date)     to_date="$2"; shift 2 ;;
      -s|--from-score)  from_score="$2"; shift 2 ;;
      -S|--to-score)    to_score="$2"; shift 2 ;;
      --from-epss)      from_epss="$2"; shift 2 ;;
      --to-epss)        to_epss="$2"; shift 2 ;;
      -e|--exploited)   exploited="true"; shift ;;
      -n|--size)        size="$2"; shift 2 ;;
      -P|--page)        page="$2"; shift 2 ;;
      -o|--output)      output_file="$2"; shift 2 ;;
      -h|--help)        usage ;;
      *) echo "Option inconnue : $1" >&2; usage ;;
    esac
  done

  local url="${BASE_URL}/search?"
  url+="assigner=$(urlencode "${assigner}")"
  url+="&product=$(urlencode "${product}")"
  url+="&vendor=$(urlencode "${vendor}")"
  url+="&text=$(urlencode "${text}")"
  url+="&fromDate=${from_date}"
  url+="&toDate=${to_date}"
  url+="&fromScore=${from_score}"
  url+="&toScore=${to_score}"
  url+="&fromEpss=${from_epss}"
  url+="&toEpss=${to_epss}"
  url+="&exploited=${exploited}"
  url+="&page=${page}"
  url+="&size=${size}"

  do_request "${url}" "${output_file}"
}

cmd_last() {
  local output_file="${1:-}"
  do_request "${BASE_URL}/lastvulnerabilities" "${output_file}"
}

cmd_exploited() {
  local output_file="${1:-}"
  do_request "${BASE_URL}/exploitedvulnerabilities" "${output_file}"
}

cmd_critical() {
  local output_file="${1:-}"
  do_request "${BASE_URL}/criticalvulnerabilities" "${output_file}"
}

cmd_id() {
  local id="${1:-}"
  local output_file="${2:-}"
  if [[ -z "${id}" ]]; then
    echo "Usage : $0 id <EUVD-ID> [fichier_sortie]" >&2
    exit 1
  fi
  do_request "${BASE_URL}/enisaid?id=$(urlencode "${id}")" "${output_file}"
}

cmd_advisory() {
  local id="${1:-}"
  local output_file="${2:-}"
  if [[ -z "${id}" ]]; then
    echo "Usage : $0 advisory <ADVISORY-ID> [fichier_sortie]" >&2
    exit 1
  fi
  do_request "${BASE_URL}/advisory?id=$(urlencode "${id}")" "${output_file}"
}

cmd_kev() {
  local output_file="${1:-}"
  do_request "${BASE_URL}/kev/dump" "${output_file}"
}

main() {
  if [[ $# -lt 1 ]]; then
    usage
  fi

  local cmd="$1"
  shift

  case "${cmd}" in
    search)    cmd_search "$@" ;;
    last)      cmd_last "$@" ;;
    exploited) cmd_exploited "$@" ;;
    critical)  cmd_critical "$@" ;;
    id)        cmd_id "$@" ;;
    advisory)  cmd_advisory "$@" ;;
    kev)       cmd_kev "$@" ;;
    -h|--help) usage ;;
    *) echo "Commande inconnue : ${cmd}" >&2; usage ;;
  esac
}

main "$@"
