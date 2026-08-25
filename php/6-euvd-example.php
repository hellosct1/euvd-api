<?php
/**
 * euvd-example.php — Exemples d'utilisation de EuvdClient
 */

require_once __DIR__ . '/EuvdClient.php';

$client = new EuvdClient();

// --- Exemple 1 : Dernières vulnérabilités exploitées ---
echo "=== Vulnérabilités exploitées récentes ===\n";
$exploited = $client->getExploitedVulnerabilities();
foreach ($exploited as $vuln) {
    printf(
        "[%s] Score: %s | EPSS: %s%% | %s\n",
        $vuln['id'] ?? 'N/A',
        $vuln['baseScore'] ?? 'N/A',
        $vuln['epss'] ?? '0',
        substr($vuln['description'] ?? '', 0, 80) . '...'
    );
}

// --- Exemple 2 : Recherche filtrée ---
echo "\n=== Recherche : Microsoft, score >= 9, exploitées ===\n";
$result = $client->searchVulnerabilities([
    'vendor'    => 'Microsoft',
    'fromScore' => 9.0,
    'exploited' => true,
    'size'      => 10,
]);
echo "Total trouvé : " . $result['total'] . "\n";
foreach ($result['items'] ?? [] as $vuln) {
    printf("  %s | %s\n", $vuln['id'], substr($vuln['description'] ?? '', 0, 60) . '...');
}

// --- Exemple 3 : Détail par CVE ---
echo "\n=== Détail CVE-2024-0864 ===\n";
$cveDetail = $client->getByCveId('CVE-2024-0864');
echo json_encode($cveDetail, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE) . "\n";

// --- Exemple 4 : Itération sur toutes les pages ---
echo "\n=== Toutes les vulnérabilités critiques 2025 (itération) ===\n";
$totalCount = 0;
$client->searchAll(
    ['fromScore' => 9.0, 'fromDate' => '2025-01-01', 'toDate' => '2025-12-31'],
    function (array $items, int $page, int $total) use (&$totalCount): void {
        echo "Page $page / " . ceil($total / 100) . " — " . count($items) . " entrées\n";
        $totalCount += count($items);
    }
);
echo "Total récupéré : $totalCount\n";