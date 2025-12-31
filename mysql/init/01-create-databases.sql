-- ==============================================================================
-- Script de Inicialização do MySQL
-- Cria bancos de dados adicionais se necessário
-- ==============================================================================

-- Você pode adicionar mais bancos aqui
-- CREATE DATABASE IF NOT EXISTS `outro_projeto`;
-- GRANT ALL PRIVILEGES ON `outro_projeto`.* TO 'laravel'@'%';

-- Exemplo: Banco para testes
CREATE DATABASE IF NOT EXISTS `laravel_testing`;
GRANT ALL PRIVILEGES ON `laravel_testing`.* TO 'laravel'@'%';

FLUSH PRIVILEGES;
