#!/bin/bash

# ==============================================================================
# make-env.sh - Gera configurações .env para projetos Laravel
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration
source "$PACKAGE_DIR/lib/config.sh"

# Load environment variables from config
load_env

# Additional colors not in config.sh
CYAN='\033[0;36m'
WHITE='\033[1;37m'
DIM='\033[2m'

# Valores padrão (podem ser sobrescritos pelo .env)
MYSQL_HOST="mysql"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_DATABASE="${MYSQL_DATABASE:-laravel}"
MYSQL_USER="${MYSQL_USER:-laravel}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-secret}"

POSTGRES_HOST="postgres"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_DATABASE="${POSTGRES_DATABASE:-laravel}"
POSTGRES_USER="${POSTGRES_USER:-laravel}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-secret}"

REDIS_HOST="redis"
REDIS_PORT="${REDIS_PORT:-6379}"

MINIO_HOST="minio"
MINIO_API_PORT="${MINIO_API_PORT:-9000}"
MINIO_CONSOLE_PORT="${MINIO_CONSOLE_PORT:-9001}"
MINIO_ROOT_USER="${MINIO_ROOT_USER:-minio}"
MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-minio123}"
MINIO_BUCKET="${MINIO_BUCKET:-laravel}"

MAILPIT_HOST="mailpit"
MAILPIT_SMTP_PORT="${MAILPIT_SMTP_PORT:-1025}"
MAILPIT_WEB_PORT="${MAILPIT_WEB_PORT:-8025}"

# Detectar portas reais dos containers em execução
get_real_port() {
    local container=$1
    local internal_port=$2
    docker port "$container" "$internal_port" 2>/dev/null | cut -d':' -f2 | head -1
}

# Verificar se containers estão rodando e obter portas reais
if docker ps --format '{{.Names}}' | grep -q "^mysql$"; then
    MYSQL_EXTERNAL_PORT=$(get_real_port mysql 3306)
    MYSQL_RUNNING=true
else
    MYSQL_EXTERNAL_PORT=$MYSQL_PORT
    MYSQL_RUNNING=false
fi

if docker ps --format '{{.Names}}' | grep -q "^postgres$"; then
    POSTGRES_EXTERNAL_PORT=$(get_real_port postgres 5432)
    POSTGRES_RUNNING=true
else
    POSTGRES_EXTERNAL_PORT=$POSTGRES_PORT
    POSTGRES_RUNNING=false
fi

if docker ps --format '{{.Names}}' | grep -q "^redis$"; then
    REDIS_EXTERNAL_PORT=$(get_real_port redis 6379)
    REDIS_RUNNING=true
else
    REDIS_EXTERNAL_PORT=$REDIS_PORT
    REDIS_RUNNING=false
fi

if docker ps --format '{{.Names}}' | grep -q "^minio$"; then
    MINIO_EXTERNAL_API_PORT=$(get_real_port minio 9000)
    MINIO_EXTERNAL_CONSOLE_PORT=$(get_real_port minio 9001)
    MINIO_RUNNING=true
else
    MINIO_EXTERNAL_API_PORT=$MINIO_API_PORT
    MINIO_EXTERNAL_CONSOLE_PORT=$MINIO_CONSOLE_PORT
    MINIO_RUNNING=false
fi

if docker ps --format '{{.Names}}' | grep -q "^mailpit$"; then
    MAILPIT_EXTERNAL_SMTP_PORT=$(get_real_port mailpit 1025)
    MAILPIT_EXTERNAL_WEB_PORT=$(get_real_port mailpit 8025)
    MAILPIT_RUNNING=true
else
    MAILPIT_EXTERNAL_SMTP_PORT=$MAILPIT_SMTP_PORT
    MAILPIT_EXTERNAL_WEB_PORT=$MAILPIT_WEB_PORT
    MAILPIT_RUNNING=false
fi

# Exibir header
echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${WHITE}           Laravel .env Configuration Generator                            ${BLUE}║${NC}"
echo -e "${BLUE}║${DIM}           Copy the settings below to your Laravel .env file              ${BLUE}║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Status dos serviços
echo -e "${YELLOW}Service Status:${NC}"
echo -e "  MySQL:      $([ "$MYSQL_RUNNING" = true ] && echo -e "${GREEN}● Running${NC}" || echo -e "${RED}○ Stopped${NC}")"
echo -e "  PostgreSQL: $([ "$POSTGRES_RUNNING" = true ] && echo -e "${GREEN}● Running${NC}" || echo -e "${RED}○ Stopped${NC}")"
echo -e "  Redis:      $([ "$REDIS_RUNNING" = true ] && echo -e "${GREEN}● Running${NC}" || echo -e "${RED}○ Stopped${NC}")"
echo -e "  MinIO:      $([ "$MINIO_RUNNING" = true ] && echo -e "${GREEN}● Running${NC}" || echo -e "${RED}○ Stopped${NC}")"
echo -e "  Mailpit:    $([ "$MAILPIT_RUNNING" = true ] && echo -e "${GREEN}● Running${NC}" || echo -e "${RED}○ Stopped${NC}")"
echo ""

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}Copy everything below this line:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Gerar configurações
cat << EOF
# ==============================================================================
# Laravel Docker Environment Configuration
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# ==============================================================================

# ==============================================================================
# MySQL 9.1
# Host interno (Docker): ${MYSQL_HOST}
# Host externo (localhost): localhost:${MYSQL_EXTERNAL_PORT:-$MYSQL_PORT}
# ==============================================================================
DB_CONNECTION=mysql
DB_HOST=${MYSQL_HOST}
DB_PORT=${MYSQL_PORT}
DB_DATABASE=${MYSQL_DATABASE}
DB_USERNAME=${MYSQL_USER}
DB_PASSWORD=${MYSQL_PASSWORD}
DB_CHARSET=utf8mb4
DB_COLLATION=utf8mb4_unicode_ci

# ==============================================================================
# PostgreSQL 17 (alternativa - descomente para usar)
# Host interno (Docker): ${POSTGRES_HOST}
# Host externo (localhost): localhost:${POSTGRES_EXTERNAL_PORT:-$POSTGRES_PORT}
# ==============================================================================
# DB_CONNECTION=pgsql
# DB_HOST=${POSTGRES_HOST}
# DB_PORT=${POSTGRES_PORT}
# DB_DATABASE=${POSTGRES_DATABASE}
# DB_USERNAME=${POSTGRES_USER}
# DB_PASSWORD=${POSTGRES_PASSWORD}

# ==============================================================================
# Redis 8
# Host interno (Docker): ${REDIS_HOST}
# Host externo (localhost): localhost:${REDIS_EXTERNAL_PORT:-$REDIS_PORT}
# ==============================================================================
REDIS_CLIENT=phpredis
REDIS_HOST=${REDIS_HOST}
REDIS_PASSWORD=null
REDIS_PORT=${REDIS_PORT}

# Cache, Session, Queue via Redis
CACHE_STORE=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
BROADCAST_CONNECTION=redis

# Separar databases por função (opcional)
REDIS_CACHE_DB=1
REDIS_SESSION_DB=2
REDIS_QUEUE_DB=3

# ==============================================================================
# MinIO (S3-Compatible Storage)
# API interno (Docker): http://${MINIO_HOST}:${MINIO_API_PORT}
# API externo (localhost): http://localhost:${MINIO_EXTERNAL_API_PORT:-$MINIO_API_PORT}
# Console: http://localhost:${MINIO_EXTERNAL_CONSOLE_PORT:-$MINIO_CONSOLE_PORT}
# Console HTTPS: https://minio.localhost
# ==============================================================================
FILESYSTEM_DISK=s3

AWS_ACCESS_KEY_ID=${MINIO_ROOT_USER}
AWS_SECRET_ACCESS_KEY=${MINIO_ROOT_PASSWORD}
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=${MINIO_BUCKET}
AWS_ENDPOINT=http://${MINIO_HOST}:${MINIO_API_PORT}
AWS_USE_PATH_STYLE_ENDPOINT=true
AWS_URL=http://localhost:${MINIO_EXTERNAL_API_PORT:-$MINIO_API_PORT}/${MINIO_BUCKET}

# ==============================================================================
# Mailpit (Email Testing)
# SMTP interno (Docker): ${MAILPIT_HOST}:${MAILPIT_SMTP_PORT}
# SMTP externo (localhost): localhost:${MAILPIT_EXTERNAL_SMTP_PORT:-$MAILPIT_SMTP_PORT}
# Web UI: http://localhost:${MAILPIT_EXTERNAL_WEB_PORT:-$MAILPIT_WEB_PORT}
# Web UI HTTPS: https://mail.localhost
# ==============================================================================
MAIL_MAILER=smtp
MAIL_HOST=${MAILPIT_HOST}
MAIL_PORT=${MAILPIT_SMTP_PORT}
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="noreply@example.test"
MAIL_FROM_NAME="\${APP_NAME}"
EOF

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Resumo de portas
echo -e "${YELLOW}Quick Reference - External Ports (localhost):${NC}"
echo ""
printf "  ${WHITE}%-15s${NC} %s\n" "MySQL:" "localhost:${MYSQL_EXTERNAL_PORT:-$MYSQL_PORT}"
printf "  ${WHITE}%-15s${NC} %s\n" "PostgreSQL:" "localhost:${POSTGRES_EXTERNAL_PORT:-$POSTGRES_PORT}"
printf "  ${WHITE}%-15s${NC} %s\n" "Redis:" "localhost:${REDIS_EXTERNAL_PORT:-$REDIS_PORT}"
printf "  ${WHITE}%-15s${NC} %s\n" "MinIO API:" "localhost:${MINIO_EXTERNAL_API_PORT:-$MINIO_API_PORT}"
printf "  ${WHITE}%-15s${NC} %s\n" "MinIO Console:" "localhost:${MINIO_EXTERNAL_CONSOLE_PORT:-$MINIO_CONSOLE_PORT}"
printf "  ${WHITE}%-15s${NC} %s\n" "Mailpit SMTP:" "localhost:${MAILPIT_EXTERNAL_SMTP_PORT:-$MAILPIT_SMTP_PORT}"
printf "  ${WHITE}%-15s${NC} %s\n" "Mailpit Web:" "localhost:${MAILPIT_EXTERNAL_WEB_PORT:-$MAILPIT_WEB_PORT}"
echo ""

echo -e "${YELLOW}HTTPS URLs (via Traefik):${NC}"
echo ""
printf "  ${WHITE}%-15s${NC} %s\n" "Your Project:" "https://[project-name].test"
printf "  ${WHITE}%-15s${NC} %s\n" "Traefik:" "https://traefik.localhost"
printf "  ${WHITE}%-15s${NC} %s\n" "Mailpit:" "https://mail.localhost"
printf "  ${WHITE}%-15s${NC} %s\n" "MinIO:" "https://minio.localhost"
printf "  ${WHITE}%-15s${NC} %s\n" "S3 API:" "https://s3.localhost"
echo ""

echo -e "${YELLOW}Database GUI Connection (e.g., TablePlus, DBeaver):${NC}"
echo ""
echo -e "  ${WHITE}MySQL:${NC}"
echo -e "    Host: localhost"
echo -e "    Port: ${MYSQL_EXTERNAL_PORT:-$MYSQL_PORT}"
echo -e "    User: ${MYSQL_USER}"
echo -e "    Password: ${MYSQL_PASSWORD}"
echo -e "    Database: ${MYSQL_DATABASE}"
echo ""
echo -e "  ${WHITE}PostgreSQL:${NC}"
echo -e "    Host: localhost"
echo -e "    Port: ${POSTGRES_EXTERNAL_PORT:-$POSTGRES_PORT}"
echo -e "    User: ${POSTGRES_USER}"
echo -e "    Password: ${POSTGRES_PASSWORD}"
echo -e "    Database: ${POSTGRES_DATABASE}"
echo ""
echo -e "  ${WHITE}Redis:${NC}"
echo -e "    Host: localhost"
echo -e "    Port: ${REDIS_EXTERNAL_PORT:-$REDIS_PORT}"
echo -e "    Password: (none)"
echo ""
