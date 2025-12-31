-- ==============================================================================
-- Script de Inicialização do PostgreSQL
-- Cria bancos de dados adicionais se necessário
-- ==============================================================================

-- Banco para testes
CREATE DATABASE laravel_testing;

-- Banco para pcast
CREATE DATABASE pcast;

-- Extensões úteis para Laravel
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";  -- pgvector para embeddings de IA

-- Também criar extensões no banco de testes
\c laravel_testing;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";

-- Extensões para pcast
\c pcast;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";
