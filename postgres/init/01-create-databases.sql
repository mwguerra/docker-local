-- ==============================================================================
-- PostgreSQL Initialization Script
-- Creates default databases and extensions for Laravel development
-- ==============================================================================

-- Testing database (for PHPUnit/Pest tests)
CREATE DATABASE laravel_testing;

-- Install useful extensions in the main database
-- These are available for all projects using PostgreSQL
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";  -- pgvector for AI embeddings

-- Also install extensions in the testing database
\c laravel_testing;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";

-- Return to default database
\c laravel;
