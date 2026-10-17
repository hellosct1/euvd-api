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
| 2-logiciel.sh | Recherche un logiciel sur API EUVD  | 
| 3-id.sh | Détail vulnérabilité EUVD par ID | 
| 4-euvd-query.sh | Interrogation de API EUVD  | 
| 5-euvd-monitor.sh | Surveillance des nouvelles vulnérabilités exploitées EUVD | 
| 7-euvd-download.sh | Téléchargement complet de la base EUVD  | 




### Complet (full)



| Fichier | Description |
|---|---|
| euvd-cli.sh |  | 

Exécution

```bash
euvd-cli.sh
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
./euvd.sh last

# 8 dernières vulnérabilités exploitées
./euvd.sh exploited

# 8 dernières vulnérabilités critiques
./euvd.sh critical

# Recherche par logiciel, uniquement les vulnérabilités exploitées
./euvd.sh search -v nodejs -e -n 20

# Recherche texte libre avec score CVSS élevé
./euvd.sh search -t "remote code execution" -s 9 -S 10

# Détails d'une vulnérabilité par ID EUVD
./euvd.sh id EUVD-2024-45012

# Détails d'une advisory
./euvd.sh advisory oxas-adv-2024-0002

# Dump complet des vulnérabilités exploitées connues (CISA KEV + EU KEV)
./euvd.sh kev -o kev-dump.json

# Sauvegarder un résultat dans un fichier
./euvd.sh last -o dernieres.json
```




