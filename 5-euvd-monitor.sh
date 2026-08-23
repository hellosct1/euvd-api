#!/usr/bin/env bash
# =============================================================================
# euvd-monitor.sh — Surveillance des nouvelles vulnérabilités exploitées EUVD
# Usage : ./euvd-monitor.sh [intervalle_secondes]
# =============================================================================

set -euo pipefail

readonly BASE_URL="https://euvdservices.enisa.europa.eu"
readonly INTERVAL="${1:-300}"   # 5 minutes par défaut
readonly STATE_FILE="/tmp/euvd_known_ids.txt"
readonly LOG_FILE="/var/log/euvd-monitor.log"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
}

get_exploited_ids() {
    curl -sf "${BASE_URL}/api/exploitedvulnerabilities" | \
        jq -r '.[].id' | sort
}

alert() {
    local id="$1"
    local details
    details=$(curl -sf "${BASE_URL}/api/enisaid?id=${id}" | \
        jq -r '"Score: \(.baseScore) | EPSS: \(.epss)% | \(.description | .[0:100])..."')
    log "[ALERTE] Nouvelle vulnérabilité exploitée : ${id}"
    log "         ${details}"
    # Décommenter pour envoyer un e-mail :
    # echo "Nouvelle EUVD exploitée: ${id} — ${details}" | mail -s "[EUVD ALERTE] ${id}" admin@example.com
}

log "Démarrage de la surveillance EUVD (intervalle: ${INTERVAL}s)"

# Initialisation
if [[ ! -f "$STATE_FILE" ]]; then
    get_exploited_ids > "$STATE_FILE"
    log "État initial enregistré ($(wc -l < "$STATE_FILE") entrées)"
fi

while true; do
    current_ids=$(get_exploited_ids)
    new_ids=$(comm -23 <(echo "$current_ids") "$STATE_FILE")

    if [[ -n "$new_ids" ]]; then
        while IFS= read -r id; do
            alert "$id"
        done <<< "$new_ids"
        echo "$current_ids" > "$STATE_FILE"
    else
        log "Aucune nouvelle vulnérabilité exploitée détectée."
    fi

    sleep "$INTERVAL"
done