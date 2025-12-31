<?php

declare(strict_types=1);

namespace MWGuerra\DockerLocal\Config;

class PathResolver
{
    /**
     * Check if running on Windows.
     */
    public function isWindows(): bool
    {
        return PHP_OS_FAMILY === 'Windows';
    }

    /**
     * Check if running on macOS.
     */
    public function isMacOS(): bool
    {
        return PHP_OS_FAMILY === 'Darwin';
    }

    /**
     * Check if running on Linux.
     */
    public function isLinux(): bool
    {
        return PHP_OS_FAMILY === 'Linux';
    }

    /**
     * Check if running in WSL (Windows Subsystem for Linux).
     */
    public function isWSL(): bool
    {
        if (!$this->isLinux()) {
            return false;
        }

        // Check for WSL indicators
        if (file_exists('/proc/version')) {
            $version = file_get_contents('/proc/version');
            return $version !== false && (
                stripos($version, 'microsoft') !== false ||
                stripos($version, 'WSL') !== false
            );
        }

        return false;
    }

    /**
     * Get the current platform name.
     */
    public function getPlatform(): string
    {
        if ($this->isWSL()) {
            return 'wsl';
        }
        if ($this->isWindows()) {
            return 'windows';
        }
        if ($this->isMacOS()) {
            return 'macos';
        }
        return 'linux';
    }

    /**
     * Normalize path separators for the current platform.
     */
    public function normalizePath(string $path): string
    {
        // Always use forward slashes (works on all platforms including Windows)
        return str_replace('\\', '/', $path);
    }

    /**
     * Resolve a path by expanding ~ and environment variables.
     */
    public function resolve(string $path): string
    {
        // Expand ~ to home directory
        if (str_starts_with($path, '~/')) {
            $path = $this->getHomeDirectory() . substr($path, 1);
        } elseif ($path === '~') {
            $path = $this->getHomeDirectory();
        }

        // Expand environment variables like $HOME, $USER, etc.
        $path = preg_replace_callback('/\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?/', function (array $matches): string {
            $envValue = getenv($matches[1]);
            return $envValue !== false ? $envValue : $matches[0];
        }, $path) ?? $path;

        return $this->normalizePath($path);
    }

    /**
     * Get the user's home directory.
     */
    public function getHomeDirectory(): string
    {
        // Try HOME first (Unix, WSL, Git Bash on Windows)
        $home = getenv('HOME');
        if ($home !== false && $home !== '') {
            return $this->normalizePath($home);
        }

        // Windows fallback
        $userProfile = getenv('USERPROFILE');
        if ($userProfile !== false && $userProfile !== '') {
            return $this->normalizePath($userProfile);
        }

        // Try HOMEDRIVE + HOMEPATH (Windows)
        $homeDrive = getenv('HOMEDRIVE');
        $homePath = getenv('HOMEPATH');
        if ($homeDrive !== false && $homePath !== false) {
            return $this->normalizePath($homeDrive . $homePath);
        }

        // Last resort
        return $this->isWindows() ? 'C:/Users/Default' : '/tmp';
    }

    /**
     * Get the configuration directory following platform conventions.
     * - Linux/macOS/WSL: XDG Base Directory Specification (~/.config/docker-local)
     * - Windows: %APPDATA%\docker-local (but we recommend WSL)
     */
    public function getConfigDirectory(): string
    {
        // Check XDG first (works on all Unix-like systems)
        $xdgConfig = getenv('XDG_CONFIG_HOME');
        if ($xdgConfig !== false && $xdgConfig !== '') {
            return $this->normalizePath($xdgConfig . '/docker-local');
        }

        // Windows native (not recommended - use WSL instead)
        if ($this->isWindows()) {
            $appData = getenv('APPDATA');
            if ($appData !== false && $appData !== '') {
                return $this->normalizePath($appData . '/docker-local');
            }
        }

        // Default to XDG-style path
        return $this->normalizePath($this->getHomeDirectory() . '/.config/docker-local');
    }

    /**
     * Get the package directory (where the Composer package is installed).
     */
    public function getPackageDirectory(): string
    {
        // Go up from src/Config to package root
        return dirname(__DIR__, 2);
    }

    /**
     * Get the resources directory within the package.
     */
    public function getResourcesDirectory(): string
    {
        return $this->getPackageDirectory() . '/resources';
    }

    /**
     * Get the default docker files directory within the package.
     */
    public function getDefaultDockerDirectory(): string
    {
        return $this->getResourcesDirectory() . '/docker';
    }

    /**
     * Get the stubs directory within the package.
     */
    public function getStubsDirectory(): string
    {
        return $this->getPackageDirectory() . '/stubs';
    }

    /**
     * Get the default projects directory.
     */
    public function getDefaultProjectsDirectory(): string
    {
        return $this->getHomeDirectory() . '/projects';
    }

    /**
     * Check if a path exists.
     */
    public function exists(string $path): bool
    {
        return file_exists($this->resolve($path));
    }

    /**
     * Ensure a directory exists, creating it if necessary.
     */
    public function ensureDirectory(string $path, int $permissions = 0755): bool
    {
        $resolvedPath = $this->resolve($path);

        if (is_dir($resolvedPath)) {
            return true;
        }

        return mkdir($resolvedPath, $permissions, true);
    }
}
