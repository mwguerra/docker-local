<?php

declare(strict_types=1);

namespace MWGuerra\DockerLocal;

use MWGuerra\DockerLocal\Config\ConfigManager;
use MWGuerra\DockerLocal\Config\ConfigValidator;
use MWGuerra\DockerLocal\Config\PathResolver;

class DockerLocal
{
    private ConfigManager $config;

    private PathResolver $pathResolver;

    private ConfigValidator $validator;

    public function __construct(
        ?ConfigManager $config = null,
        ?PathResolver $pathResolver = null,
        ?ConfigValidator $validator = null
    ) {
        $this->pathResolver = $pathResolver ?? new PathResolver();
        $this->config = $config ?? new ConfigManager($this->pathResolver);
        $this->validator = $validator ?? new ConfigValidator();
    }

    /**
     * Get the configuration manager.
     */
    public function getConfig(): ConfigManager
    {
        return $this->config;
    }

    /**
     * Get the path resolver.
     */
    public function getPathResolver(): PathResolver
    {
        return $this->pathResolver;
    }

    /**
     * Get the configuration validator.
     */
    public function getValidator(): ConfigValidator
    {
        return $this->validator;
    }

    /**
     * Check if the environment is initialized.
     */
    public function isInitialized(): bool
    {
        return $this->config->exists();
    }

    /**
     * Get package version.
     */
    public function getVersion(): string
    {
        return '2.0.0';
    }

    /**
     * Output configuration for bash scripts.
     * This is used by bin/docker-local to get paths.
     */
    public function outputBashConfig(): void
    {
        $this->config->load();

        echo 'PACKAGE_DIR=' . escapeshellarg($this->pathResolver->getPackageDirectory()) . "\n";
        echo 'CONFIG_DIR=' . escapeshellarg($this->pathResolver->getConfigDirectory()) . "\n";
        echo 'PROJECTS_DIR=' . escapeshellarg($this->config->getProjectsPath()) . "\n";
        echo 'DOCKER_FILES_DIR=' . escapeshellarg($this->config->getDockerFilesPath()) . "\n";
        echo 'RESOURCES_DIR=' . escapeshellarg($this->pathResolver->getResourcesDirectory()) . "\n";
        echo 'DEFAULT_DOCKER_DIR=' . escapeshellarg($this->pathResolver->getDefaultDockerDirectory()) . "\n";
    }

    /**
     * Output a specific configuration value for bash.
     */
    public function outputConfigValue(string $key): void
    {
        $this->config->load();
        $value = $this->config->get($key);

        if ($value === null) {
            exit(1);
        }

        if (is_array($value)) {
            echo json_encode($value);
        } else {
            echo $value;
        }
    }

    /**
     * Resolve a docker file path and output it.
     */
    public function outputDockerFilePath(string $relativePath): void
    {
        $path = $this->config->resolveDockerFile($relativePath);
        echo $path;
    }
}
