<?php

declare(strict_types=1);

namespace MWGuerra\DockerLocal\Config;

use InvalidArgumentException;
use RuntimeException;

class ConfigManager
{
    private array $config = [];

    private PathResolver $pathResolver;

    private string $configPath;

    private bool $loaded = false;

    public function __construct(?PathResolver $pathResolver = null)
    {
        $this->pathResolver = $pathResolver ?? new PathResolver();
        $this->configPath = $this->pathResolver->getConfigDirectory() . '/config.json';
    }

    /**
     * Load configuration from file.
     */
    public function load(): self
    {
        if ($this->loaded) {
            return $this;
        }

        if (file_exists($this->configPath)) {
            $content = file_get_contents($this->configPath);
            if ($content === false) {
                throw new RuntimeException("Failed to read config file: {$this->configPath}");
            }

            $decoded = json_decode($content, true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                throw new RuntimeException('Invalid JSON in config file: ' . json_last_error_msg());
            }

            $this->config = $decoded ?? [];
        }

        $this->loaded = true;

        return $this;
    }

    /**
     * Get a configuration value using dot notation.
     */
    public function get(string $key, mixed $default = null): mixed
    {
        $this->load();

        $keys = explode('.', $key);
        $value = $this->config;

        foreach ($keys as $k) {
            if (! is_array($value) || ! array_key_exists($k, $value)) {
                return $default;
            }
            $value = $value[$k];
        }

        // Resolve paths if the value contains ~ or environment variables
        if (is_string($value) && $this->isPath($value)) {
            $value = $this->pathResolver->resolve($value);
        }

        return $value;
    }

    /**
     * Set a configuration value using dot notation.
     */
    public function set(string $key, mixed $value): self
    {
        $this->load();

        $keys = explode('.', $key);
        $current = &$this->config;

        foreach ($keys as $i => $k) {
            if ($i === count($keys) - 1) {
                $current[$k] = $value;
            } else {
                if (! isset($current[$k]) || ! is_array($current[$k])) {
                    $current[$k] = [];
                }
                $current = &$current[$k];
            }
        }

        return $this;
    }

    /**
     * Check if a configuration key exists.
     */
    public function has(string $key): bool
    {
        $this->load();

        $keys = explode('.', $key);
        $value = $this->config;

        foreach ($keys as $k) {
            if (! is_array($value) || ! array_key_exists($k, $value)) {
                return false;
            }
            $value = $value[$k];
        }

        return true;
    }

    /**
     * Save configuration to file.
     */
    public function save(): self
    {
        $directory = dirname($this->configPath);

        if (! is_dir($directory)) {
            if (! mkdir($directory, 0755, true)) {
                throw new RuntimeException("Failed to create config directory: {$directory}");
            }
        }

        $json = json_encode($this->config, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
        if ($json === false) {
            throw new RuntimeException('Failed to encode config as JSON');
        }

        if (file_put_contents($this->configPath, $json) === false) {
            throw new RuntimeException("Failed to write config file: {$this->configPath}");
        }

        return $this;
    }

    /**
     * Get the projects directory path.
     */
    public function getProjectsPath(): string
    {
        return $this->get('projects_path', $this->pathResolver->getDefaultProjectsDirectory());
    }

    /**
     * Get the docker files directory path (user config location).
     */
    public function getDockerFilesPath(): string
    {
        return $this->get('docker_files_path', $this->pathResolver->getConfigDirectory());
    }

    /**
     * Resolve a docker file path using hybrid resolution.
     * Checks user override first, falls back to package default.
     */
    public function resolveDockerFile(string $relativePath): string
    {
        // Check user override first
        $userPath = $this->getDockerFilesPath() . '/' . $relativePath;
        if (file_exists($userPath)) {
            return $userPath;
        }

        // Fall back to package default
        return $this->pathResolver->getDefaultDockerDirectory() . '/' . $relativePath;
    }

    /**
     * Check if user has an override for a docker file.
     */
    public function hasUserOverride(string $relativePath): bool
    {
        $userPath = $this->getDockerFilesPath() . '/' . $relativePath;

        return file_exists($userPath);
    }

    /**
     * Get the configuration file path.
     */
    public function getConfigPath(): string
    {
        return $this->configPath;
    }

    /**
     * Get the path resolver instance.
     */
    public function getPathResolver(): PathResolver
    {
        return $this->pathResolver;
    }

    /**
     * Get all configuration as array.
     */
    public function all(): array
    {
        $this->load();

        return $this->config;
    }

    /**
     * Check if configuration file exists.
     */
    public function exists(): bool
    {
        return file_exists($this->configPath);
    }

    /**
     * Initialize with default configuration.
     */
    public function initializeDefaults(): self
    {
        $this->config = [
            'version' => '2.0.0',
            'projects_path' => '~/projects',
            'docker_files_path' => '~/.config/docker-local',
            'editor' => 'code',
            'default_php_version' => '8.4',
            'mysql' => [
                'version' => '9.1',
                'port' => 3306,
            ],
            'postgres' => [
                'port' => 5432,
            ],
            'redis' => [
                'port' => 6379,
            ],
            'minio' => [
                'api_port' => 9000,
                'console_port' => 9001,
            ],
            'mailpit' => [
                'web_port' => 8025,
                'smtp_port' => 1025,
            ],
        ];

        $this->loaded = true;

        return $this;
    }

    /**
     * Check if a string looks like a path that needs resolution.
     */
    private function isPath(string $value): bool
    {
        return str_contains($value, '~') || str_contains($value, '$');
    }
}
