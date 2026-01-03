<?php

declare(strict_types=1);

namespace MWGuerra\DockerLocal\Config;

class ConfigValidator
{
    private array $errors = [];

    private array $warnings = [];

    /**
     * Required configuration keys.
     */
    private array $requiredKeys = [
        'version',
        'projects_path',
    ];

    /**
     * Valid configuration structure with types.
     */
    private array $schema = [
        'version' => 'string',
        'projects_path' => 'string',
        'docker_files_path' => 'string',
        'editor' => 'string',
        'default_php_version' => 'string',
        'mysql' => [
            'version' => 'string',
            'port' => 'integer',
        ],
        'postgres' => [
            'port' => 'integer',
        ],
        'redis' => [
            'port' => 'integer',
        ],
        'minio' => [
            'api_port' => 'integer',
            'console_port' => 'integer',
        ],
        'mailpit' => [
            'web_port' => 'integer',
            'smtp_port' => 'integer',
        ],
        'reverb' => [
            'port' => 'integer',
            'project_name' => 'string',
            'app_id' => 'string',
            'app_key' => 'string',
            'app_secret' => 'string',
            'scaling_enabled' => 'boolean',
        ],
    ];

    /**
     * Validate configuration array.
     */
    public function validate(array $config): bool
    {
        $this->errors = [];
        $this->warnings = [];

        $this->validateRequiredKeys($config);
        $this->validateTypes($config, $this->schema);
        $this->validatePaths($config);
        $this->validatePorts($config);

        return empty($this->errors);
    }

    /**
     * Validate required keys exist.
     */
    private function validateRequiredKeys(array $config): void
    {
        foreach ($this->requiredKeys as $key) {
            if (! array_key_exists($key, $config)) {
                $this->errors[] = "Missing required configuration key: {$key}";
            }
        }
    }

    /**
     * Validate types recursively.
     */
    private function validateTypes(array $config, array $schema, string $prefix = ''): void
    {
        foreach ($schema as $key => $expectedType) {
            $fullKey = $prefix ? "{$prefix}.{$key}" : $key;

            if (! array_key_exists($key, $config)) {
                continue; // Optional keys are allowed
            }

            $value = $config[$key];

            if (is_array($expectedType)) {
                if (! is_array($value)) {
                    $this->errors[] = "Configuration key '{$fullKey}' must be an object";

                    continue;
                }
                $this->validateTypes($value, $expectedType, $fullKey);
            } else {
                $actualType = gettype($value);
                if (! $this->isValidType($value, $expectedType)) {
                    $this->errors[] = "Configuration key '{$fullKey}' must be of type {$expectedType}, got {$actualType}";
                }
            }
        }
    }

    /**
     * Validate paths are accessible.
     */
    private function validatePaths(array $config): void
    {
        $pathResolver = new PathResolver();

        // Check projects_path
        if (isset($config['projects_path'])) {
            $projectsPath = $pathResolver->resolve($config['projects_path']);
            if (! is_dir($projectsPath)) {
                $this->warnings[] = "Projects directory does not exist: {$projectsPath}";
            }
        }

        // Check docker_files_path
        if (isset($config['docker_files_path'])) {
            $dockerPath = $pathResolver->resolve($config['docker_files_path']);
            if (! is_dir($dockerPath)) {
                $this->warnings[] = "Docker files directory does not exist: {$dockerPath}";
            }
        }
    }

    /**
     * Validate port numbers are in valid range.
     */
    private function validatePorts(array $config): void
    {
        $portKeys = [
            'mysql.port',
            'postgres.port',
            'redis.port',
            'minio.api_port',
            'minio.console_port',
            'mailpit.web_port',
            'mailpit.smtp_port',
            'reverb.port',
        ];

        foreach ($portKeys as $key) {
            $port = $this->getNestedValue($config, $key);
            if ($port !== null && ! $this->isValidPort($port)) {
                $this->errors[] = "Invalid port number for '{$key}': {$port} (must be 1-65535)";
            }
        }

        // Check for port conflicts
        $this->checkPortConflicts($config);
    }

    /**
     * Check for port conflicts.
     */
    private function checkPortConflicts(array $config): void
    {
        $ports = [];
        $portKeys = [
            'mysql.port' => 'MySQL',
            'postgres.port' => 'PostgreSQL',
            'redis.port' => 'Redis',
            'minio.api_port' => 'MinIO API',
            'minio.console_port' => 'MinIO Console',
            'mailpit.web_port' => 'Mailpit Web',
            'mailpit.smtp_port' => 'Mailpit SMTP',
            'reverb.port' => 'Reverb WebSocket',
        ];

        foreach ($portKeys as $key => $name) {
            $port = $this->getNestedValue($config, $key);
            if ($port !== null) {
                if (isset($ports[$port])) {
                    $this->errors[] = "Port conflict: {$name} and {$ports[$port]} both use port {$port}";
                } else {
                    $ports[$port] = $name;
                }
            }
        }
    }

    /**
     * Check if value matches expected type.
     */
    private function isValidType(mixed $value, string $expectedType): bool
    {
        return match ($expectedType) {
            'string' => is_string($value),
            'integer' => is_int($value),
            'boolean' => is_bool($value),
            'array' => is_array($value),
            default => true,
        };
    }

    /**
     * Check if port number is valid.
     */
    private function isValidPort(mixed $port): bool
    {
        return is_int($port) && $port >= 1 && $port <= 65535;
    }

    /**
     * Get nested value from array using dot notation.
     */
    private function getNestedValue(array $array, string $key): mixed
    {
        $keys = explode('.', $key);
        $value = $array;

        foreach ($keys as $k) {
            if (! is_array($value) || ! array_key_exists($k, $value)) {
                return null;
            }
            $value = $value[$k];
        }

        return $value;
    }

    /**
     * Get validation errors.
     */
    public function getErrors(): array
    {
        return $this->errors;
    }

    /**
     * Get validation warnings.
     */
    public function getWarnings(): array
    {
        return $this->warnings;
    }

    /**
     * Check if validation passed (no errors).
     */
    public function isValid(): bool
    {
        return empty($this->errors);
    }

    /**
     * Check if there are warnings.
     */
    public function hasWarnings(): bool
    {
        return ! empty($this->warnings);
    }
}
