<?php

declare(strict_types=1);

use MWGuerra\DockerLocal\Config\ConfigManager;
use MWGuerra\DockerLocal\Config\PathResolver;

describe('ConfigManager', function () {
    beforeEach(function () {
        $this->tempDir = null;
    });

    afterEach(function () {
        if ($this->tempDir !== null) {
            cleanupTempDir($this->tempDir);
        }
    });

    describe('get()', function () {
        it('returns default value when config file does not exist', function () {
            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn('/nonexistent');
            $pathResolver->shouldReceive('getHomeDirectory')->andReturn('/home/test');
            $pathResolver->shouldReceive('getDefaultProjectsDirectory')->andReturn('/home/test/projects');

            $config = new ConfigManager($pathResolver);

            expect($config->get('nonexistent', 'default'))->toBe('default');
        });

        it('returns value from config file', function () {
            $this->tempDir = createTempConfig([
                'projects_path' => '/custom/projects',
            ]);

            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn($this->tempDir);

            $config = new ConfigManager($pathResolver);

            expect($config->get('projects_path'))->toBe('/custom/projects');
        });

        it('supports dot notation for nested values', function () {
            $this->tempDir = createTempConfig([
                'mysql' => [
                    'port' => 3307,
                    'version' => '8.0',
                ],
            ]);

            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn($this->tempDir);

            $config = new ConfigManager($pathResolver);

            expect($config->get('mysql.port'))->toBe(3307);
            expect($config->get('mysql.version'))->toBe('8.0');
        });

        it('returns default for non-existent nested key', function () {
            $this->tempDir = createTempConfig([
                'mysql' => ['port' => 3306],
            ]);

            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn($this->tempDir);

            $config = new ConfigManager($pathResolver);

            expect($config->get('mysql.nonexistent', 'default'))->toBe('default');
            expect($config->get('nonexistent.key', 'default'))->toBe('default');
        });

        it('resolves paths containing tilde', function () {
            $this->tempDir = createTempConfig([
                'projects_path' => '~/my-projects',
            ]);

            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn($this->tempDir);
            $pathResolver->shouldReceive('resolve')
                ->with('~/my-projects')
                ->andReturn('/home/user/my-projects');

            $config = new ConfigManager($pathResolver);

            expect($config->get('projects_path'))->toBe('/home/user/my-projects');
        });
    });

    describe('set()', function () {
        it('sets a simple value', function () {
            $this->tempDir = createTempConfig([]);

            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn($this->tempDir);

            $config = new ConfigManager($pathResolver);
            $config->set('editor', 'vim');

            expect($config->get('editor'))->toBe('vim');
        });

        it('sets nested values using dot notation', function () {
            $this->tempDir = createTempConfig([]);

            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn($this->tempDir);

            $config = new ConfigManager($pathResolver);
            $config->set('mysql.port', 3307);

            expect($config->get('mysql.port'))->toBe(3307);
        });

        it('creates intermediate objects for nested keys', function () {
            $this->tempDir = createTempConfig([]);

            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn($this->tempDir);

            $config = new ConfigManager($pathResolver);
            $config->set('deeply.nested.value', 'test');

            expect($config->get('deeply.nested.value'))->toBe('test');
        });
    });

    describe('has()', function () {
        it('returns true for existing key', function () {
            $this->tempDir = createTempConfig(['key' => 'value']);

            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn($this->tempDir);

            $config = new ConfigManager($pathResolver);

            expect($config->has('key'))->toBeTrue();
        });

        it('returns false for non-existing key', function () {
            $this->tempDir = createTempConfig([]);

            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn($this->tempDir);

            $config = new ConfigManager($pathResolver);

            expect($config->has('nonexistent'))->toBeFalse();
        });

        it('works with nested keys', function () {
            $this->tempDir = createTempConfig([
                'mysql' => ['port' => 3306],
            ]);

            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn($this->tempDir);

            $config = new ConfigManager($pathResolver);

            expect($config->has('mysql.port'))->toBeTrue();
            expect($config->has('mysql.host'))->toBeFalse();
        });
    });

    describe('save()', function () {
        it('saves configuration to file', function () {
            $this->tempDir = sys_get_temp_dir() . '/docker-local-test-' . uniqid();
            mkdir($this->tempDir, 0755, true);

            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn($this->tempDir);

            $config = new ConfigManager($pathResolver);
            $config->set('test', 'value');
            $config->save();

            $savedContent = json_decode(file_get_contents($this->tempDir . '/config.json'), true);
            expect($savedContent['test'])->toBe('value');
        });

        it('creates directory if it does not exist', function () {
            $this->tempDir = sys_get_temp_dir() . '/docker-local-test-' . uniqid();

            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn($this->tempDir);

            $config = new ConfigManager($pathResolver);
            $config->set('test', 'value');
            $config->save();

            expect(is_dir($this->tempDir))->toBeTrue();
            expect(file_exists($this->tempDir . '/config.json'))->toBeTrue();
        });
    });

    describe('getProjectsPath()', function () {
        it('returns configured projects path', function () {
            $this->tempDir = createTempConfig([
                'projects_path' => '/custom/projects',
            ]);

            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn($this->tempDir);
            $pathResolver->shouldReceive('getDefaultProjectsDirectory')->andReturn('/home/test/projects');
            // Absolute paths don't need resolution
            $pathResolver->shouldReceive('resolve')->andReturnUsing(fn($path) => $path);

            $config = new ConfigManager($pathResolver);

            expect($config->getProjectsPath())->toBe('/custom/projects');
        });

        it('returns default when not configured', function () {
            $this->tempDir = createTempConfig([]);

            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn($this->tempDir);
            $pathResolver->shouldReceive('getHomeDirectory')->andReturn('/home/test');
            $pathResolver->shouldReceive('getDefaultProjectsDirectory')->andReturn('/home/test/projects');

            $config = new ConfigManager($pathResolver);

            expect($config->getProjectsPath())->toBe('/home/test/projects');
        });
    });

    describe('resolveDockerFile()', function () {
        it('returns user override path when it exists', function () {
            $this->tempDir = sys_get_temp_dir() . '/docker-local-test-' . uniqid();
            mkdir($this->tempDir, 0755, true);
            touch($this->tempDir . '/docker-compose.yml');

            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn($this->tempDir);
            $pathResolver->shouldReceive('getDefaultDockerDirectory')->andReturn('/package/resources/docker');

            $config = new ConfigManager($pathResolver);
            $config->set('docker_files_path', $this->tempDir);

            $result = $config->resolveDockerFile('docker-compose.yml');

            expect($result)->toBe($this->tempDir . '/docker-compose.yml');
        });

        it('falls back to package default when user override does not exist', function () {
            $this->tempDir = createTempConfig([]);

            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn($this->tempDir);
            $pathResolver->shouldReceive('getDefaultDockerDirectory')->andReturn('/package/resources/docker');

            $config = new ConfigManager($pathResolver);

            $result = $config->resolveDockerFile('docker-compose.yml');

            expect($result)->toBe('/package/resources/docker/docker-compose.yml');
        });
    });

    describe('initializeDefaults()', function () {
        it('sets default configuration values', function () {
            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn('/tmp');
            $pathResolver->shouldReceive('resolve')->andReturnUsing(fn($path) => str_replace('~', '/home/test', $path));

            $config = new ConfigManager($pathResolver);
            $config->initializeDefaults();

            expect($config->get('version'))->toBe('2.0.0');
            // projects_path has tilde resolved
            expect($config->get('projects_path'))->toBe('/home/test/projects');
            expect($config->get('mysql.port'))->toBe(3306);
            expect($config->get('postgres.port'))->toBe(5432);
            expect($config->get('redis.port'))->toBe(6379);
        });

        it('sets default reverb configuration values', function () {
            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn('/tmp');
            $pathResolver->shouldReceive('resolve')->andReturnUsing(fn($path) => str_replace('~', '/home/test', $path));

            $config = new ConfigManager($pathResolver);
            $config->initializeDefaults();

            expect($config->get('reverb.port'))->toBe(6001);
            expect($config->get('reverb.project_name'))->toBe('myapp');
            expect($config->get('reverb.app_id'))->toBe('my-app-id');
            expect($config->get('reverb.app_key'))->toBe('my-app-key');
            expect($config->get('reverb.app_secret'))->toBe('my-app-secret');
            expect($config->get('reverb.scaling_enabled'))->toBeFalse();
        });
    });

    describe('exists()', function () {
        it('returns true when config file exists', function () {
            $this->tempDir = createTempConfig(['test' => 'value']);

            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn($this->tempDir);

            $config = new ConfigManager($pathResolver);

            expect($config->exists())->toBeTrue();
        });

        it('returns false when config file does not exist', function () {
            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn('/nonexistent');

            $config = new ConfigManager($pathResolver);

            expect($config->exists())->toBeFalse();
        });
    });

    describe('all()', function () {
        it('returns all configuration as array', function () {
            $this->tempDir = createTempConfig([
                'key1' => 'value1',
                'key2' => 'value2',
            ]);

            $pathResolver = Mockery::mock(PathResolver::class);
            $pathResolver->shouldReceive('getConfigDirectory')->andReturn($this->tempDir);

            $config = new ConfigManager($pathResolver);

            expect($config->all())->toBe([
                'key1' => 'value1',
                'key2' => 'value2',
            ]);
        });
    });
});
