-- Top 10 des vulnérabilités les plus sévères exploitées
SELECT id, base_score, epss, vendors, substr(description, 1, 80) AS desc
FROM vulnerabilities
WHERE exploited_since IS NOT NULL
  AND base_score >= 9.0
ORDER BY base_score DESC, epss DESC
LIMIT 10;

-- Toutes les vulnérabilités Microsoft publiées en 2025
SELECT id, base_score, date_published, substr(description, 1, 80) AS desc
FROM vulnerabilities
WHERE vendors LIKE '%Microsoft%'
  AND date_published LIKE '2025%'
ORDER BY base_score DESC;

-- Distribution des vulnérabilités par niveau de sévérité
SELECT
    CASE
        WHEN base_score >= 9  THEN 'Critique (9–10)'
        WHEN base_score >= 7  THEN 'Élevé (7–8.9)'
        WHEN base_score >= 4  THEN 'Moyen (4–6.9)'
        WHEN base_score >= 0  THEN 'Faible (0–3.9)'
        ELSE 'Non évalué'
    END AS niveau,
    COUNT(*) AS nb
FROM vulnerabilities
GROUP BY niveau
ORDER BY nb DESC;

-- Mise à jour incrémentale : récupérer les nouvelles entrées depuis une date
SELECT id, date_published, vendors, base_score
FROM vulnerabilities
WHERE date_published >= date('now', '-7 days')
ORDER BY date_published DESC;