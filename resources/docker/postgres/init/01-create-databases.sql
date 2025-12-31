-- ==============================================================================
-- PostgreSQL Initialization Script
-- Creates additional databases if needed
-- ==============================================================================

-- Database for testing
CREATE DATABASE laravel_testing;

-- Database for pcast
CREATE DATABASE pcast;

-- Useful extensions for Laravel
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";  -- pgvector for AI embeddings

-- Also create extensions in test database
\c laravel_testing;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";

-- Extensions for pcast
\c pcast;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";
