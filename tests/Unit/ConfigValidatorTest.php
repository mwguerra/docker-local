<?php

declare(strict_types=1);

use MWGuerra\DockerLocal\Config\ConfigValidator;

describe('ConfigValidator', function () {
    beforeEach(function () {
        $this->validator = new ConfigValidator();
    });

    describe('validate()', function () {
        it('passes with valid configuration', function () {
            $config = [
                'version' => '2.0.0',
                'projects_path' => '/home/user/projects',
                'docker_files_path' => '/home/user/.config/docker-local',
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
            ];

            $result = $this->validator->validate($config);

            expect($result)->toBeTrue();
            expect($this->validator->getErrors())->toBeEmpty();
        });

        it('fails when required keys are missing', function () {
            $config = [];

            $result = $this->validator->validate($config);

            expect($result)->toBeFalse();
            expect($this->validator->getErrors())->toContain('Missing required configuration key: version');
            expect($this->validator->getErrors())->toContain('Missing required configuration key: projects_path');
        });

        it('fails when version is wrong type', function () {
            $config = [
                'version' => 123, // Should be string
                'projects_path' => '/path',
            ];

            $result = $this->validator->validate($config);

            expect($result)->toBeFalse();
            expect($this->validator->getErrors())->toContain("Configuration key 'version' must be of type string, got integer");
        });

        it('fails when port is wrong type', function () {
            $config = [
                'version' => '2.0.0',
                'projects_path' => '/path',
                'mysql' => [
                    'port' => '3306', // Should be integer
                ],
            ];

            $result = $this->validator->validate($config);

            expect($result)->toBeFalse();
            expect($this->validator->getErrors())->toContain("Configuration key 'mysql.port' must be of type integer, got string");
        });

        it('fails with invalid port number', function () {
            $config = [
                'version' => '2.0.0',
                'projects_path' => '/path',
                'mysql' => [
                    'port' => 99999, // Invalid port
                ],
            ];

            $result = $this->validator->validate($config);

            expect($result)->toBeFalse();
            expect($this->validator->getErrors())->toContain("Invalid port number for 'mysql.port': 99999 (must be 1-65535)");
        });

        it('fails with port number zero', function () {
            $config = [
                'version' => '2.0.0',
                'projects_path' => '/path',
                'redis' => [
                    'port' => 0,
                ],
            ];

            $result = $this->validator->validate($config);

            expect($result)->toBeFalse();
        });

        it('fails with negative port number', function () {
            $config = [
                'version' => '2.0.0',
                'projects_path' => '/path',
                'postgres' => [
                    'port' => -1,
                ],
            ];

            $result = $this->validator->validate($config);

            expect($result)->toBeFalse();
        });

        it('detects port conflicts', function () {
            $config = [
                'version' => '2.0.0',
                'projects_path' => '/path',
                'mysql' => [
                    'port' => 3306,
                ],
                'postgres' => [
                    'port' => 3306, // Conflict with MySQL
                ],
            ];

            $result = $this->validator->validate($config);

            expect($result)->toBeFalse();
            $errors = $this->validator->getErrors();
            $hasConflict = false;
            foreach ($errors as $error) {
                if (str_contains($error, 'Port conflict')) {
                    $hasConflict = true;
                    break;
                }
            }
            expect($hasConflict)->toBeTrue();
        });

        it('validates reverb port configuration', function () {
            $config = [
                'version' => '2.0.0',
                'projects_path' => '/path',
                'reverb' => [
                    'port' => 8080,
                    'project_name' => 'myapp',
                    'app_id' => 'my-app-id',
                    'app_key' => 'my-app-key',
                    'app_secret' => 'my-app-secret',
                    'scaling_enabled' => false,
                ],
            ];

            $result = $this->validator->validate($config);

            expect($result)->toBeTrue();
            expect($this->validator->getErrors())->toBeEmpty();
        });

        it('fails with invalid reverb port', function () {
            $config = [
                'version' => '2.0.0',
                'projects_path' => '/path',
                'reverb' => [
                    'port' => 99999, // Invalid port
                ],
            ];

            $result = $this->validator->validate($config);

            expect($result)->toBeFalse();
            expect($this->validator->getErrors())->toContain("Invalid port number for 'reverb.port': 99999 (must be 1-65535)");
        });

        it('detects reverb port conflict with other services', function () {
            $config = [
                'version' => '2.0.0',
                'projects_path' => '/path',
                'mailpit' => [
                    'web_port' => 8080,
                ],
                'reverb' => [
                    'port' => 8080, // Conflict with Mailpit
                ],
            ];

            $result = $this->validator->validate($config);

            expect($result)->toBeFalse();
            $errors = $this->validator->getErrors();
            $hasConflict = false;
            foreach ($errors as $error) {
                if (str_contains($error, 'Port conflict')) {
                    $hasConflict = true;
                    break;
                }
            }
            expect($hasConflict)->toBeTrue();
        });

        it('allows optional keys to be missing', function () {
            $config = [
                'version' => '2.0.0',
                'projects_path' => '/path',
                // All other keys are optional
            ];

            $result = $this->validator->validate($config);

            expect($result)->toBeTrue();
        });
    });

    describe('getWarnings()', function () {
        it('warns when projects directory does not exist', function () {
            $config = [
                'version' => '2.0.0',
                'projects_path' => '/nonexistent/path/12345',
            ];

            $this->validator->validate($config);
            $warnings = $this->validator->getWarnings();

            expect($warnings)->not->toBeEmpty();
            $hasWarning = false;
            foreach ($warnings as $warning) {
                if (str_contains($warning, 'Projects directory does not exist')) {
                    $hasWarning = true;
                    break;
                }
            }
            expect($hasWarning)->toBeTrue();
        });

        it('warns when docker files directory does not exist', function () {
            $config = [
                'version' => '2.0.0',
                'projects_path' => '/tmp', // Exists
                'docker_files_path' => '/nonexistent/docker/path',
            ];

            $this->validator->validate($config);

            expect($this->validator->hasWarnings())->toBeTrue();
        });
    });

    describe('isValid()', function () {
        it('returns true after successful validation', function () {
            $config = [
                'version' => '2.0.0',
                'projects_path' => '/tmp',
            ];

            $this->validator->validate($config);

            expect($this->validator->isValid())->toBeTrue();
        });

        it('returns false after failed validation', function () {
            $config = [];

            $this->validator->validate($config);

            expect($this->validator->isValid())->toBeFalse();
        });
    });

    describe('hasWarnings()', function () {
        it('returns true when there are warnings', function () {
            $config = [
                'version' => '2.0.0',
                'projects_path' => '/nonexistent/12345',
            ];

            $this->validator->validate($config);

            expect($this->validator->hasWarnings())->toBeTrue();
        });

        it('returns false when there are no warnings', function () {
            $config = [
                'version' => '2.0.0',
                'projects_path' => '/tmp',
            ];

            $this->validator->validate($config);

            expect($this->validator->hasWarnings())->toBeFalse();
        });
    });
});
