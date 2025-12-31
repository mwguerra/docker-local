-- ==============================================================================
-- MySQL Initialization Script
-- Creates additional databases if needed
-- ==============================================================================

-- You can add more databases here
-- CREATE DATABASE IF NOT EXISTS `other_project`;
-- GRANT ALL PRIVILEGES ON `other_project`.* TO 'laravel'@'%';

-- Example: Database for testing
CREATE DATABASE IF NOT EXISTS `laravel_testing`;
GRANT ALL PRIVILEGES ON `laravel_testing`.* TO 'laravel'@'%';

FLUSH PRIVILEGES;
