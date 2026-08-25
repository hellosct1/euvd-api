<?php
/**
 * EuvdClient.php — Client PHP pour l'API EUVD de l'ENISA
 * Compatible PHP 8.0+
 * Dépendances : extension cURL
 */

declare(strict_types=1);

class EuvdClient
{
    private const BASE_URL  = 'https://euvdservices.enisa.europa.eu';
    private const TIMEOUT   = 30;
    private const USER_AGENT = 'EUVD-PHP-Client/1.0';

    private \CurlHandle $ch;

    public function __construct()
    {
        if (!extension_loaded('curl')) {
            throw new \RuntimeException('L\'extension cURL est requise.');
        }
        $this->ch = curl_init();
        curl_setopt_array($this->ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => self::TIMEOUT,
            CURLOPT_USERAGENT      => self::USER_AGENT,
            CURLOPT_HTTPHEADER     => ['Accept: application/json'],
            CURLOPT_SSL_VERIFYPEER => true,
            CURLOPT_SSL_VERIFYHOST => 2,
            CURLOPT_FOLLOWLOCATION => false,
        ]);
    }

    public function __destruct()
    {
        curl_close($this->ch);
    }

    // -------------------------------------------------------------------------
    // Méthode HTTP interne
    // -------------------------------------------------------------------------

    private function get(string $path, array $params = []): array
    {
        $url = self::BASE_URL . $path;
        if (!empty($params)) {
            $url .= '?' . http_build_query($params);
        }

        $maxRetries = 5;
        $delay      = 2; // secondes initiales

        for ($attempt = 1; $attempt <= $maxRetries; $attempt++) {
            curl_setopt($this->ch, CURLOPT_URL, $url);
            $response = curl_exec($this->ch);

            if ($response === false) {
                throw new \RuntimeException('Erreur cURL : ' . curl_error($this->ch));
            }

            $httpCode = curl_getinfo($this->ch, CURLINFO_HTTP_CODE);

            if ($httpCode === 200) {
                return json_decode($response, true, 512, JSON_THROW_ON_ERROR);
            }

            if (in_array($httpCode, [429, 503, 403], true) && $attempt < $maxRetries) {
                $wait = $delay * (2 ** ($attempt - 1)); // 2s, 4s, 8s, 16s
                fwrite(STDERR, "[retry {$attempt}/{$maxRetries}] HTTP {$httpCode} — attente {$wait}s pour {$url}\n");
                sleep($wait);
                continue;
            }

            throw new \RuntimeException("Erreur HTTP {$httpCode} pour {$url} (après {$attempt} tentative(s))");
        }

        throw new \RuntimeException("Échec après {$maxRetries} tentatives pour {$url}");
    }

    // -------------------------------------------------------------------------
    // Endpoints Frontpage
    // -------------------------------------------------------------------------

    /** Retourne les 8 dernières vulnérabilités publiées. */
    public function getLatestVulnerabilities(): array
    {
        return $this->get('/api/lastvulnerabilities');
    }

    /** Retourne les 8 dernières vulnérabilités activement exploitées. */
    public function getExploitedVulnerabilities(): array
    {
        return $this->get('/api/exploitedvulnerabilities');
    }

    /** Retourne les 8 dernières vulnérabilités critiques. */
    public function getCriticalVulnerabilities(): array
    {
        return $this->get('/api/criticalvulnerabilities');
    }

    // -------------------------------------------------------------------------
    // Endpoint Filtres & Scores
    // -------------------------------------------------------------------------

    /**
     * Recherche de vulnérabilités avec filtres combinés.
     *
     * Filtres acceptés : fromScore, toScore, fromEpss, toEpss,
     *   fromDate, toDate, product, vendor, assigner,
     *   exploited (bool), text, page (int), size (int max 100)
     *
     * @return array ['items' => [...], 'total' => int]
     */
    public function searchVulnerabilities(array $filters = []): array
    {
        $allowed = [
            'fromScore', 'toScore', 'fromEpss', 'toEpss',
            'fromDate',  'toDate',  'product',  'vendor',
            'assigner',  'exploited', 'text',   'page', 'size',
        ];
        $params = array_intersect_key($filters, array_flip($allowed));

        if (isset($params['exploited'])) {
            $params['exploited'] = $params['exploited'] ? 'true' : 'false';
        }

        return $this->get('/api/search', $params);
    }

    /**
     * Itère sur toutes les pages de résultats.
     * $callback reçoit : function(array $items, int $page, int $total): void
     */
    public function searchAll(array $filters, callable $callback, int $pageSize = 100): void
    {
        $filters['size'] = $pageSize;
        $filters['page'] = 0;

        do {
            $result = $this->searchVulnerabilities($filters);
            $items  = $result['items'] ?? [];
            $total  = (int)($result['total'] ?? 0);

            $callback($items, $filters['page'], $total);

            $filters['page']++;
            $fetched = $filters['page'] * $pageSize;
        } while ($fetched < $total && !empty($items));
    }

    // -------------------------------------------------------------------------
    // Endpoints Ressources spécifiques
    // -------------------------------------------------------------------------

    /** Retourne une vulnérabilité par son identifiant EUVD. Ex: "EUVD-2025-13580" */
    public function getByEuvdId(string $euvdId): array
    {
        return $this->get('/api/enisaid', ['id' => $euvdId]);
    }

    /** Retourne une vulnérabilité par son identifiant CVE. Ex: "CVE-2024-0864" */
    public function getByCveId(string $cveId): array
    {
        return $this->get('/api/vulnerability', ['id' => $cveId]);
    }

    /** Retourne un avis de sécurité par son identifiant. */
    public function getAdvisory(string $advisoryId): array
    {
        return $this->get('/api/advisory', ['id' => $advisoryId]);
    }
}