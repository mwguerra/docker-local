#!/usr/bin/env php
<?php

/**
 * CLI Helper for docker-local bash scripts.
 * This script outputs configuration values that can be sourced by bash.
 *
 * Usage:
 *   php cli-helper.php config          # Output all config as bash variables
 *   php cli-helper.php get <key>       # Get a specific config value
 *   php cli-helper.php resolve <path>  # Resolve a docker file path
 *   php cli-helper.php paths           # Output all paths
 */

declare(strict_types=1);

// Find autoloader
$autoloadPaths = [
    __DIR__ . '/../vendor/autoload.php',           // When in package
    __DIR__ . '/../../autoload.php',               // When installed via composer
    __DIR__ . '/../../../autoload.php',            // Global composer
];

$autoloaderFound = false;
foreach ($autoloadPaths as $autoloadPath) {
    if (file_exists($autoloadPath)) {
        require $autoloadPath;
        $autoloaderFound = true;
        break;
    }
}

if (! $autoloaderFound) {
    // Fallback: load classes manually for when autoloader isn't available yet
    require __DIR__ . '/Config/PathResolver.php';
    require __DIR__ . '/Config/ConfigManager.php';
    require __DIR__ . '/Config/ConfigValidator.php';
    require __DIR__ . '/DockerLocal.php';
}

use MWGuerra\DockerLocal\DockerLocal;

$app = new DockerLocal();
$command = $argv[1] ?? 'config';

switch ($command) {
    case 'config':
        $app->outputBashConfig();
        break;

    case 'get':
        if (! isset($argv[2])) {
            fwrite(STDERR, "Usage: cli-helper.php get <key>\n");
            exit(1);
        }
        $app->outputConfigValue($argv[2]);
        break;

    case 'resolve':
        if (! isset($argv[2])) {
            fwrite(STDERR, "Usage: cli-helper.php resolve <relative-path>\n");
            exit(1);
        }
        $app->outputDockerFilePath($argv[2]);
        break;

    case 'paths':
        $pathResolver = $app->getPathResolver();
        echo 'HOME=' . escapeshellarg($pathResolver->getHomeDirectory()) . "\n";
        echo 'CONFIG_DIR=' . escapeshellarg($pathResolver->getConfigDirectory()) . "\n";
        echo 'PACKAGE_DIR=' . escapeshellarg($pathResolver->getPackageDirectory()) . "\n";
        echo 'RESOURCES_DIR=' . escapeshellarg($pathResolver->getResourcesDirectory()) . "\n";
        echo 'DOCKER_DIR=' . escapeshellarg($pathResolver->getDefaultDockerDirectory()) . "\n";
        echo 'STUBS_DIR=' . escapeshellarg($pathResolver->getStubsDirectory()) . "\n";
        break;

    case 'initialized':
        exit($app->isInitialized() ? 0 : 1);

    case 'version':
        echo $app->getVersion() . "\n";
        break;

    case 'validate':
        $config = $app->getConfig();
        $validator = $app->getValidator();

        if (! $config->exists()) {
            echo "Config file not found\n";
            exit(1);
        }

        $config->load();
        $isValid = $validator->validate($config->all());

        if (! $isValid) {
            echo "Errors:\n";
            foreach ($validator->getErrors() as $error) {
                echo "  - {$error}\n";
            }
        }

        if ($validator->hasWarnings()) {
            echo "Warnings:\n";
            foreach ($validator->getWarnings() as $warning) {
                echo "  - {$warning}\n";
            }
        }

        exit($isValid ? 0 : 1);

    default:
        fwrite(STDERR, "Unknown command: {$command}\n");
        fwrite(STDERR, "Available commands: config, get, resolve, paths, initialized, version, validate\n");
        exit(1);
}
