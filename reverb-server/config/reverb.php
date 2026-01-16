<?php

/**
 * Reverb Configuration for docker-local
 *
 * This standalone Reverb server supports multiple applications.
 * Apps are loaded from /data/apps.json which is managed by docker-local CLI.
 */

// Load apps from JSON file (mounted from docker-local config)
$appsFile = env('REVERB_APPS_FILE', '/data/apps.json');
$apps = [];

if (file_exists($appsFile)) {
    $appsData = json_decode(file_get_contents($appsFile), true) ?? [];
    foreach ($appsData as $appConfig) {
        $apps[] = [
            'key' => $appConfig['key'] ?? '',
            'secret' => $appConfig['secret'] ?? '',
            'app_id' => $appConfig['app_id'] ?? '',
            'options' => [
                'host' => env('REVERB_HOST', '0.0.0.0'),
                'port' => env('REVERB_PORT', 6001),
                'scheme' => env('REVERB_SCHEME', 'http'),
                'useTLS' => env('REVERB_SCHEME', 'http') === 'https',
            ],
            'allowed_origins' => $appConfig['allowed_origins'] ?? ['*'],
            'ping_interval' => env('REVERB_APP_PING_INTERVAL', 60),
            'activity_timeout' => env('REVERB_APP_ACTIVITY_TIMEOUT', 30),
            'max_message_size' => env('REVERB_APP_MAX_MESSAGE_SIZE', 10000),
        ];
    }
}

// If no apps configured, add a default app for development
if (empty($apps)) {
    $apps[] = [
        'key' => env('REVERB_APP_KEY', 'docker-local-key'),
        'secret' => env('REVERB_APP_SECRET', 'docker-local-secret'),
        'app_id' => env('REVERB_APP_ID', 'docker-local'),
        'options' => [
            'host' => env('REVERB_HOST', '0.0.0.0'),
            'port' => env('REVERB_PORT', 6001),
            'scheme' => env('REVERB_SCHEME', 'http'),
            'useTLS' => env('REVERB_SCHEME', 'http') === 'https',
        ],
        'allowed_origins' => ['*'],
        'ping_interval' => env('REVERB_APP_PING_INTERVAL', 60),
        'activity_timeout' => env('REVERB_APP_ACTIVITY_TIMEOUT', 30),
        'max_message_size' => env('REVERB_APP_MAX_MESSAGE_SIZE', 10000),
    ];
}

return [
    'default' => env('REVERB_SERVER', 'reverb'),

    'servers' => [
        'reverb' => [
            'host' => env('REVERB_SERVER_HOST', '0.0.0.0'),
            'port' => env('REVERB_SERVER_PORT', 6001),
            'hostname' => env('REVERB_HOST', 'ws.localhost'),
            'options' => [
                'tls' => [],
            ],
            'max_request_size' => env('REVERB_MAX_REQUEST_SIZE', 10_000),
            'scaling' => [
                'enabled' => env('REVERB_SCALING_ENABLED', false),
                'channel' => env('REVERB_SCALING_CHANNEL', 'reverb'),
                'server' => [
                    'url' => env('REDIS_URL'),
                    'host' => env('REDIS_HOST', 'redis'),
                    'port' => env('REDIS_PORT', '6379'),
                    'username' => env('REDIS_USERNAME'),
                    'password' => env('REDIS_PASSWORD'),
                    'database' => env('REDIS_DB', '0'),
                ],
            ],
            'pulse_ingest_interval' => env('REVERB_PULSE_INGEST_INTERVAL', 15),
            'telescope_ingest_interval' => env('REVERB_TELESCOPE_INGEST_INTERVAL', 15),
        ],
    ],

    'apps' => $apps,
];
