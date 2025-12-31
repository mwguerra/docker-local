<?php

declare(strict_types=1);

use MWGuerra\DockerLocal\Config\PathResolver;

describe('PathResolver', function () {
    beforeEach(function () {
        $this->resolver = new PathResolver();
        $this->originalHome = getenv('HOME');
        $this->originalXdg = getenv('XDG_CONFIG_HOME');
    });

    afterEach(function () {
        // Restore original environment
        if ($this->originalHome !== false) {
            putenv("HOME={$this->originalHome}");
        }
        if ($this->originalXdg !== false) {
            putenv("XDG_CONFIG_HOME={$this->originalXdg}");
        } else {
            putenv('XDG_CONFIG_HOME');
        }
    });

    describe('resolve()', function () {
        it('expands tilde to home directory', function () {
            $home = getenv('HOME');
            $result = $this->resolver->resolve('~/projects');

            expect($result)->toBe($home . '/projects');
        });

        it('expands standalone tilde to home directory', function () {
            $home = getenv('HOME');
            $result = $this->resolver->resolve('~');

            expect($result)->toBe($home);
        });

        it('expands environment variables with $ syntax', function () {
            putenv('TEST_VAR=/custom/path');
            $result = $this->resolver->resolve('$TEST_VAR/subdir');

            expect($result)->toBe('/custom/path/subdir');

            putenv('TEST_VAR'); // cleanup
        });

        it('expands environment variables with ${} syntax', function () {
            putenv('TEST_VAR=/another/path');
            $result = $this->resolver->resolve('${TEST_VAR}/subdir');

            expect($result)->toBe('/another/path/subdir');

            putenv('TEST_VAR'); // cleanup
        });

        it('leaves unset environment variables unchanged', function () {
            $result = $this->resolver->resolve('$NONEXISTENT_VAR/subdir');

            expect($result)->toBe('$NONEXISTENT_VAR/subdir');
        });

        it('returns absolute paths unchanged', function () {
            $result = $this->resolver->resolve('/absolute/path');

            expect($result)->toBe('/absolute/path');
        });

        it('returns relative paths unchanged', function () {
            $result = $this->resolver->resolve('relative/path');

            expect($result)->toBe('relative/path');
        });

        it('handles multiple environment variables', function () {
            putenv('VAR1=/first');
            putenv('VAR2=/second');
            $result = $this->resolver->resolve('$VAR1$VAR2');

            expect($result)->toBe('/first/second');

            putenv('VAR1');
            putenv('VAR2');
        });
    });

    describe('getHomeDirectory()', function () {
        it('returns HOME environment variable when set', function () {
            putenv('HOME=/home/testuser');
            $resolver = new PathResolver();

            expect($resolver->getHomeDirectory())->toBe('/home/testuser');
        });

        it('falls back to USERPROFILE on Windows', function () {
            $originalHome = getenv('HOME');
            putenv('HOME');
            putenv('USERPROFILE=C:\\Users\\testuser');

            $resolver = new PathResolver();
            $result = $resolver->getHomeDirectory();

            // Restore
            if ($originalHome !== false) {
                putenv("HOME={$originalHome}");
            }
            putenv('USERPROFILE');

            // Paths are normalized to forward slashes
            expect($result)->toBe('C:/Users/testuser');
        });
    });

    describe('getConfigDirectory()', function () {
        it('uses XDG_CONFIG_HOME when set', function () {
            putenv('XDG_CONFIG_HOME=/custom/config');
            $resolver = new PathResolver();

            expect($resolver->getConfigDirectory())->toBe('/custom/config/docker-local');
        });

        it('falls back to ~/.config when XDG_CONFIG_HOME is not set', function () {
            putenv('XDG_CONFIG_HOME');
            $resolver = new PathResolver();
            $home = $resolver->getHomeDirectory();

            expect($resolver->getConfigDirectory())->toBe($home . '/.config/docker-local');
        });
    });

    describe('getPackageDirectory()', function () {
        it('returns the package root directory', function () {
            $packageDir = $this->resolver->getPackageDirectory();

            expect($packageDir)->toBeString();
            expect(file_exists($packageDir . '/composer.json'))->toBeTrue();
        });
    });

    describe('getResourcesDirectory()', function () {
        it('returns the resources directory', function () {
            $resourcesDir = $this->resolver->getResourcesDirectory();
            $packageDir = $this->resolver->getPackageDirectory();

            expect($resourcesDir)->toBe($packageDir . '/resources');
        });
    });

    describe('getDefaultDockerDirectory()', function () {
        it('returns the docker resources directory', function () {
            $dockerDir = $this->resolver->getDefaultDockerDirectory();
            $resourcesDir = $this->resolver->getResourcesDirectory();

            expect($dockerDir)->toBe($resourcesDir . '/docker');
        });
    });

    describe('getStubsDirectory()', function () {
        it('returns the stubs directory', function () {
            $stubsDir = $this->resolver->getStubsDirectory();
            $packageDir = $this->resolver->getPackageDirectory();

            expect($stubsDir)->toBe($packageDir . '/stubs');
        });
    });

    describe('getDefaultProjectsDirectory()', function () {
        it('returns home/projects', function () {
            $projectsDir = $this->resolver->getDefaultProjectsDirectory();
            $home = $this->resolver->getHomeDirectory();

            expect($projectsDir)->toBe($home . '/projects');
        });
    });

    describe('exists()', function () {
        it('returns true for existing paths', function () {
            expect($this->resolver->exists('/tmp'))->toBeTrue();
        });

        it('returns false for non-existing paths', function () {
            expect($this->resolver->exists('/nonexistent/path/12345'))->toBeFalse();
        });

        it('resolves paths before checking', function () {
            // Create a temp file in home
            $home = getenv('HOME');
            $testFile = $home . '/.docker-local-test-' . uniqid();
            touch($testFile);

            // Use tilde path - should resolve ~ to home and find the file
            $result = $this->resolver->exists('~/' . basename($testFile));
            unlink($testFile);

            expect($result)->toBeTrue();
        });
    });

    describe('ensureDirectory()', function () {
        it('creates directory if it does not exist', function () {
            $tempDir = sys_get_temp_dir() . '/docker-local-test-' . uniqid();

            expect(is_dir($tempDir))->toBeFalse();

            $result = $this->resolver->ensureDirectory($tempDir);

            expect($result)->toBeTrue();
            expect(is_dir($tempDir))->toBeTrue();

            rmdir($tempDir);
        });

        it('returns true if directory already exists', function () {
            expect($this->resolver->ensureDirectory('/tmp'))->toBeTrue();
        });

        it('creates nested directories', function () {
            $tempDir = sys_get_temp_dir() . '/docker-local-test-' . uniqid() . '/nested/path';

            $result = $this->resolver->ensureDirectory($tempDir);

            expect($result)->toBeTrue();
            expect(is_dir($tempDir))->toBeTrue();

            // Cleanup
            rmdir($tempDir);
            rmdir(dirname($tempDir));
            rmdir(dirname(dirname($tempDir)));
        });
    });

    describe('platform detection', function () {
        it('returns a valid platform name', function () {
            $platform = $this->resolver->getPlatform();

            expect($platform)->toBeIn(['linux', 'macos', 'windows', 'wsl']);
        });

        it('isLinux returns boolean', function () {
            expect($this->resolver->isLinux())->toBeBool();
        });

        it('isMacOS returns boolean', function () {
            expect($this->resolver->isMacOS())->toBeBool();
        });

        it('isWindows returns boolean', function () {
            expect($this->resolver->isWindows())->toBeBool();
        });

        it('isWSL returns boolean', function () {
            expect($this->resolver->isWSL())->toBeBool();
        });

        it('exactly one primary platform is detected', function () {
            $platforms = [
                $this->resolver->isLinux(),
                $this->resolver->isMacOS(),
                $this->resolver->isWindows(),
            ];

            // Exactly one should be true
            expect(count(array_filter($platforms)))->toBe(1);
        });
    });

    describe('normalizePath()', function () {
        it('converts backslashes to forward slashes', function () {
            $result = $this->resolver->normalizePath('C:\\Users\\test\\projects');

            expect($result)->toBe('C:/Users/test/projects');
        });

        it('leaves forward slashes unchanged', function () {
            $result = $this->resolver->normalizePath('/home/user/projects');

            expect($result)->toBe('/home/user/projects');
        });

        it('handles mixed slashes', function () {
            $result = $this->resolver->normalizePath('C:\\Users/test\\projects/app');

            expect($result)->toBe('C:/Users/test/projects/app');
        });
    });
});
