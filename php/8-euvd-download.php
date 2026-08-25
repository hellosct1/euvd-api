<?php
/**
 * euvd-download.php — Téléchargement EUVD vers SQLite
 *
 * Usage : php euvd-download.php [--from-date=YYYY-MM-DD] [--output=euvd.sqlite]
 *
 * Dépendances PHP : cURL, PDO SQLite (php-sqlite3)
 */

declare(strict_types=1);

//require_once __DIR__ . '/EuvdClient.class.php';
require_once 'EuvdClient.class.php';

// -------------------------------------------------------------------------
// Parsing des arguments
// -------------------------------------------------------------------------
$opts     = getopt('', ['from-date::', 'output::', 'page-size::']);
$fromDate = $opts['from-date']  ?? null;
$dbFile   = $opts['output']     ?? __DIR__ . '/euvd_' . date('Y-m-d') . '.sqlite';
$pageSize = (int)($opts['page-size'] ?? 100);

// -------------------------------------------------------------------------
// Initialisation de la base SQLite
// -------------------------------------------------------------------------
$pdo = new PDO("sqlite:{$dbFile}", null, null, [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
]);

$pdo->exec("PRAGMA journal_mode=WAL");
$pdo->exec("PRAGMA synchronous=NORMAL");

$pdo->exec("
CREATE TABLE IF NOT EXISTS vulnerabilities (
    id                 TEXT PRIMARY KEY,
    description        TEXT,
    date_published     TEXT,
    date_updated       TEXT,
    base_score         REAL,
    base_score_version TEXT,
    base_score_vector  TEXT,
    aliases            TEXT,
    assigner           TEXT,
    epss               REAL,
    exploited_since    TEXT,
    references_urls    TEXT,
    vendors            TEXT,
    products           TEXT,
    raw_json           TEXT,
    imported_at        TEXT DEFAULT (datetime('now'))
)");

$pdo->exec("CREATE INDEX IF NOT EXISTS idx_base_score ON vulnerabilities(base_score)");
$pdo->exec("CREATE INDEX IF NOT EXISTS idx_date_pub   ON vulnerabilities(date_published)");
$pdo->exec("CREATE INDEX IF NOT EXISTS idx_epss       ON vulnerabilities(epss)");
$pdo->exec("CREATE INDEX IF NOT EXISTS idx_assigner   ON vulnerabilities(assigner)");

// -------------------------------------------------------------------------
// Préparation de l'insertion
// -------------------------------------------------------------------------
$stmt = $pdo->prepare("
INSERT OR REPLACE INTO vulnerabilities
    (id, description, date_published, date_updated, base_score,
     base_score_version, base_score_vector, aliases, assigner, epss,
     exploited_since, references_urls, vendors, products, raw_json)
VALUES
    (:id, :description, :date_published, :date_updated, :base_score,
     :base_score_version, :base_score_vector, :aliases, :assigner, :epss,
     :exploited_since, :references_urls, :vendors, :products, :raw_json)
");

// -------------------------------------------------------------------------
// Téléchargement et insertion
// -------------------------------------------------------------------------
$client    = new EuvdClient();
$filters   = ['size' => $pageSize];
if ($fromDate !== null) {
    $filters['fromDate'] = $fromDate;
}

$totalInserted = 0;
$startTime     = microtime(true);

echo "Démarrage du téléchargement EUVD vers {$dbFile}\n";
if ($fromDate) {
    echo "Filtre date : depuis le {$fromDate}\n";
}

$client->searchAll(
    $filters,
    function (array $items, int $page, int $total) use ($pdo, $stmt, &$totalInserted): void {
        $pdo->beginTransaction();
        foreach ($items as $vuln) {
            $vendors  = array_column(
                array_column($vuln['enisaIdVendor']  ?? [], 'vendor'),
                'name'
            );
            $products = array_column(
                array_column($vuln['enisaIdProduct'] ?? [], 'product'),
                'name'
            );

            $stmt->execute([
                ':id'                 => $vuln['id'] ?? null,
                ':description'        => $vuln['description'] ?? null,
                ':date_published'     => $vuln['datePublished'] ?? null,
                ':date_updated'       => $vuln['dateUpdated'] ?? null,
                ':base_score'         => isset($vuln['baseScore']) ? (float)$vuln['baseScore'] : null,
                ':base_score_version' => $vuln['baseScoreVersion'] ?? null,
                ':base_score_vector'  => $vuln['baseScoreVector'] ?? null,
                ':aliases'            => $vuln['aliases'] ?? null,
                ':assigner'           => $vuln['assigner'] ?? null,
                ':epss'               => isset($vuln['epss']) ? (float)$vuln['epss'] : null,
                ':exploited_since'    => $vuln['exploitedSince'] ?? null,
                ':references_urls'    => $vuln['references'] ?? null,
                ':vendors'            => implode(', ', $vendors),
                ':products'           => implode(', ', $products),
                ':raw_json'           => json_encode($vuln, JSON_UNESCAPED_UNICODE),
            ]);
            $totalInserted++;
        }
        $pdo->commit();

        $pct = $total > 0 ? round(($totalInserted / $total) * 100, 1) : 0;
        echo sprintf(
            "  Page %d — %d/%d entrées insérées (%s%%)\n",
            $page, $totalInserted, $total, $pct
        );
        usleep(500000); // 0.5s entre les pages
    },
    $pageSize
);

$elapsed = round(microtime(true) - $startTime, 1);
echo "\nTerminé : {$totalInserted} vulnérabilités insérées en {$elapsed}s\n";
echo "Base de données : {$dbFile}\n";

// Statistiques finales
$stats = $pdo->query("
    SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN base_score >= 9 THEN 1 ELSE 0 END) AS critiques,
        SUM(CASE WHEN exploited_since IS NOT NULL THEN 1 ELSE 0 END) AS exploitees,
        AVG(CASE WHEN base_score > 0 THEN base_score END) AS score_moyen
    FROM vulnerabilities
")->fetch();

echo "\n=== Statistiques de la base ===\n";
echo "  Total           : {$stats['total']}\n";
echo "  Critiques (>=9) : {$stats['critiques']}\n";
echo "  Exploitées      : {$stats['exploitees']}\n";
echo "  Score moyen     : " . round((float)$stats['score_moyen'], 2) . "\n";

?>