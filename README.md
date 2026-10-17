# EUVD API

> **EUVD** (European Union Vulnerability Database, ENISA) 
> Site officiel https://euvdservices.enisa.europa.eu/api

## Remarque

Cette documentation d'API n'est pas officielle (source : dépôt communautaire
[bytew0lf/EUVD-API](https://github.com/bytew0lf/EUVD-API)). Se référer à
`https://euvd.enisa.europa.eu/apidoc` pour la documentation officielle, qui
peut évoluer.

Doc officiel : https://euvd.enisa.europa.eu/apidoc

## Fichiers 

### Echantillon (sample)

| Fichier | Description |
|---|---|
| 1-latest.sh | Dernières vulnérabilités publiées | 
| 1-exploited.sh | Vulnérabilités activement exploitées | 
| 1-critical.sh | les 8 dernières vulnérabilités critiques |
| 1-detail-id.sh | Détail complet de la dernière vulnérabilité critique | 
| 2-search-logiciel.sh | Recherche un logiciel sur API EUVD | 
| 2-search-epss.sh | Recherche EPSS et vulnérabilités exploitées sur l'API EUVD | 
| 2-search-remote.sh | Recherche de vulnérabilités remote sur l'API EUVD | 
| 3-id-euvd.sh | Détail d'une vulnérabilité EUVD par ID | 
| 3-id-cve.sh | Détail d'une vulnérabilité EUVD par CVE | 
| 3-id-advisory.sh | Détail d'un advisory EUVD par ID | 
| 4-euvd-query.sh | Interrogation de API EUVD | 
| 5-euvd-monitor.sh | Surveillance des nouvelles vulnérabilités exploitées EUVD | 
| 7-euvd-download-logiciel.sh | Téléchargement des vulnérabilités EUVD par fournisseur |
| 7-euvd-download-pages.sh | Téléchargement complet de la base EUVD | 
| 8-query-API-complet.sh | Interrogation de l'API EUVD (ENISA) | 
| 8-query-offline-date.sh | Vulnérabilités d'un fournisseur publiées durant les 7 derniers jours | 
| 8-query-offline-exploitees.sh | Top 10 des vulnérabilités sévères exploitées | 
| 8-query-offline-publies.sh | Vulnérabilités d'un fournisseur publiées en 2025 | 
| 8-query-offline-score.sh | Distribution des scores CVSS par fournisseur | 



### API EUVD



| Fichier | Description |
|---|---|
| euvd-cli.sh | Version client avec l'utilisation de l'API EUVD | 

Exécution

```bash
./euvd-cli.sh
```


#### Structure d'une entrée EUVD (fichier euvd.sh)

Chaque vulnérabilité exposée par l'API contient les champs suivants :

| Champ | Description |
|---|---|
| `id` | Identifiant EUVD unique (ex. `EUVD-2025-13580`) |
| `description` | Description textuelle de la vulnérabilité |
| `datePublished` | Date de première publication |
| `dateUpdated` | Date de dernière mise à jour |
| `baseScore` | Score CVSS (−1 si non disponible) |
| `baseScoreVersion` | Version CVSS utilisée (3.1 ou 4.0) |
| `baseScoreVector` | Vecteur CVSS complet |
| `aliases` | CVE, GHSA et autres identifiants associés |
| `assigner` | Organisation ayant assigné la vulnérabilité |
| `epss` | Score EPSS (probabilité d'exploitation en %) |
| `exploitedSince` | Date de première exploitation active connue |
| `enisaIdProduct` | Produits affectés (nom + version) |
| `enisaIdVendor` | Éditeurs/vendeurs affectés |
| `references` | Liens vers les sources et correctifs |


> Site communautaire https://github.com/bytew0lf/EUVD-API


#### Exemples — Shell

Quelques exemples d'utilisations 

```bash
# 8 dernières vulnérabilités publiées
./euvd-cli.sh last

# 8 dernières vulnérabilités exploitées
./euvd-cli.sh exploited

# 8 dernières vulnérabilités critiques
./euvd-cli.sh critical

# Recherche par logiciel, uniquement les vulnérabilités exploitées
./euvd-cli.sh search -v nodejs -e -n 20

# Recherche texte libre avec score CVSS élevé
./euvd-cli.sh search -t "remote code execution" -s 9 -S 10

# Détails d'une vulnérabilité par ID EUVD
./euvd-cli.sh id EUVD-2024-45012

# Détails d'une advisory
./euvd-cli.sh advisory oxas-adv-2024-0002

# Dump complet des vulnérabilités exploitées connues (CISA KEV + EU KEV)
./euvd-cli.sh kev -o kev-dump.json

# Sauvegarder un résultat dans un fichier
./euvd-cli.sh last -o dernieres.json
```

(R) Hello / Hello-design - 2026



