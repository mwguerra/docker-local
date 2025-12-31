#!/bin/bash

# ==============================================================================
# install.sh - Script de instalação customizado para novos projetos Laravel
# ==============================================================================
# Este script é executado após a criação de um novo projeto Laravel.
# Customize conforme suas necessidades!
#
# Variáveis disponíveis:
#   $1 = PROJECT_NAME (nome do projeto)
#   $2 = PROJECT_PATH (caminho completo do projeto)
# ==============================================================================

PROJECT_NAME=$1
PROJECT_PATH=$2

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
DIM='\033[2m'
NC='\033[0m'

echo -e "${BLUE}Running custom installation for ${PROJECT_NAME}...${NC}"

# ==============================================================================
# PACOTES COMPOSER - Descomente os que desejar instalar automaticamente
# ==============================================================================

# --- Desenvolvimento ---
# docker exec -w "/var/www/$PROJECT_NAME" php composer require --dev \
#     laravel/telescope \
#     barryvdh/laravel-debugbar \
#     laravel/pint \
#     pestphp/pest --with-all-dependencies

# --- Autenticação ---
# docker exec -w "/var/www/$PROJECT_NAME" php composer require laravel/sanctum
# docker exec -w "/var/www/$PROJECT_NAME" php php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"

# --- Breeze (Starter Kit) ---
# docker exec -w "/var/www/$PROJECT_NAME" php composer require laravel/breeze --dev
# docker exec -w "/var/www/$PROJECT_NAME" php php artisan breeze:install blade

# --- Jetstream (Starter Kit Avançado) ---
# docker exec -w "/var/www/$PROJECT_NAME" php composer require laravel/jetstream
# docker exec -w "/var/www/$PROJECT_NAME" php php artisan jetstream:install livewire

# --- Filament (Admin Panel) ---
# docker exec -w "/var/www/$PROJECT_NAME" php composer require filament/filament:"^3.0"
# docker exec -w "/var/www/$PROJECT_NAME" php php artisan filament:install --panels

# --- Spatie Packages ---
# docker exec -w "/var/www/$PROJECT_NAME" php composer require spatie/laravel-permission
# docker exec -w "/var/www/$PROJECT_NAME" php composer require spatie/laravel-medialibrary
# docker exec -w "/var/www/$PROJECT_NAME" php composer require spatie/laravel-activitylog
# docker exec -w "/var/www/$PROJECT_NAME" php composer require spatie/laravel-backup
# docker exec -w "/var/www/$PROJECT_NAME" php composer require spatie/laravel-query-builder

# --- API ---
# docker exec -w "/var/www/$PROJECT_NAME" php composer require spatie/laravel-data
# docker exec -w "/var/www/$PROJECT_NAME" php composer require spatie/laravel-fractal

# --- Queue & Jobs ---
# docker exec -w "/var/www/$PROJECT_NAME" php composer require laravel/horizon

# --- Outros ---
# docker exec -w "/var/www/$PROJECT_NAME" php composer require livewire/livewire
# docker exec -w "/var/www/$PROJECT_NAME" php composer require inertiajs/inertia-laravel


# ==============================================================================
# COMANDOS ARTISAN - Descomente os que desejar executar
# ==============================================================================

# Executar migrations
# docker exec -w "/var/www/$PROJECT_NAME" php php artisan migrate

# Publicar configurações
# docker exec -w "/var/www/$PROJECT_NAME" php php artisan vendor:publish --tag=laravel-pagination

# Criar links de storage
# docker exec -w "/var/www/$PROJECT_NAME" php php artisan storage:link

# Limpar caches
# docker exec -w "/var/www/$PROJECT_NAME" php php artisan config:clear
# docker exec -w "/var/www/$PROJECT_NAME" php php artisan cache:clear


# ==============================================================================
# NPM/YARN - Descomente para instalar dependências frontend
# ==============================================================================

# docker exec -w "/var/www/$PROJECT_NAME" php npm install
# docker exec -w "/var/www/$PROJECT_NAME" php npm run build


# ==============================================================================
# ESTRUTURA DE PASTAS - Crie pastas adicionais se necessário
# ==============================================================================

# mkdir -p "$PROJECT_PATH/app/Actions"
# mkdir -p "$PROJECT_PATH/app/Services"
# mkdir -p "$PROJECT_PATH/app/Repositories"
# mkdir -p "$PROJECT_PATH/app/Traits"
# mkdir -p "$PROJECT_PATH/app/Enums"
# mkdir -p "$PROJECT_PATH/app/DTOs"


# ==============================================================================
# ARQUIVOS CUSTOMIZADOS - Copie arquivos de templates se necessário
# ==============================================================================

# TEMPLATES_DIR="$(dirname "$0")"
# 
# if [ -f "$TEMPLATES_DIR/files/.editorconfig" ]; then
#     cp "$TEMPLATES_DIR/files/.editorconfig" "$PROJECT_PATH/"
# fi
# 
# if [ -f "$TEMPLATES_DIR/files/phpstan.neon" ]; then
#     cp "$TEMPLATES_DIR/files/phpstan.neon" "$PROJECT_PATH/"
# fi


# ==============================================================================
# GIT - Inicializar repositório
# ==============================================================================

# cd "$PROJECT_PATH"
# git init
# git add .
# git commit -m "Initial commit - Laravel project created"


echo -e "${GREEN}✓ Custom installation complete${NC}"
