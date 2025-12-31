#!/bin/bash

# ==============================================================================
# Script para verificar status de todos os serviços - 2025 Edition
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration
source "$PACKAGE_DIR/lib/config.sh"

# Load environment to get port configurations
load_env

# Additional color
CYAN='\033[0;36m'

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     Laravel Docker Dev - Status dos Serviços (2025)           ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Função para verificar serviço
check_service() {
    local name=$1
    local container=$2
    local version=$3
    
    printf "%-18s" "$name ($version):"
    
    if docker ps --format '{{.Names}}' | grep -q "^$container$"; then
        echo -e "${GREEN}● Running${NC}"
        return 0
    else
        echo -e "${RED}○ Stopped${NC}"
        return 1
    fi
}

echo -e "${YELLOW}Containers:${NC}"
echo ""

check_service "Traefik" "traefik" "3.6"
check_service "Nginx" "nginx" "alpine"
check_service "PHP-FPM" "php" "8.4"
check_service "MySQL" "mysql" "9.1"
check_service "PostgreSQL" "postgres" "17"
check_service "Redis" "redis" "8"
check_service "Mailpit" "mailpit" "latest"
check_service "MinIO" "minio" "latest"

echo ""
echo -e "${YELLOW}Versões Detalhadas:${NC}"
echo ""

# PHP Version
if docker ps --format '{{.Names}}' | grep -q "^php$"; then
    PHP_VERSION=$(docker exec php php -v 2>/dev/null | head -1 | cut -d' ' -f2)
    printf "  PHP:        "
    echo -e "${CYAN}$PHP_VERSION${NC}"
    
    # Verificar Xdebug
    XDEBUG=$(docker exec php php -m 2>/dev/null | grep -i xdebug)
    if [ -n "$XDEBUG" ]; then
        XDEBUG_VERSION=$(docker exec php php -r "echo phpversion('xdebug');" 2>/dev/null)
        printf "  Xdebug:     "
        echo -e "${GREEN}✓ Enabled ($XDEBUG_VERSION)${NC}"
    else
        printf "  Xdebug:     "
        echo -e "${YELLOW}○ Disabled${NC}"
    fi
fi

# MySQL Version
if docker ps --format '{{.Names}}' | grep -q "^mysql$"; then
    MYSQL_VERSION=$(docker exec mysql mysql --version 2>/dev/null | awk '{print $3}')
    printf "  MySQL:      "
    echo -e "${CYAN}$MYSQL_VERSION${NC}"
fi

# PostgreSQL Version
if docker ps --format '{{.Names}}' | grep -q "^postgres$"; then
    PG_VERSION=$(docker exec postgres psql --version 2>/dev/null | awk '{print $3}')
    printf "  PostgreSQL: "
    echo -e "${CYAN}$PG_VERSION${NC}"
fi

# Redis Version
if docker ps --format '{{.Names}}' | grep -q "^redis$"; then
    REDIS_VERSION=$(docker exec redis redis-server --version 2>/dev/null | awk '{print $3}' | cut -d'=' -f2)
    printf "  Redis:      "
    echo -e "${CYAN}$REDIS_VERSION${NC}"
fi

echo ""
echo -e "${YELLOW}Conexões:${NC}"
echo ""

# Testar MySQL
printf "  MySQL:      "
if docker exec mysql mysql -u laravel -psecret -e "SELECT 1" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Conectado${NC} (laravel@mysql:3306)"
else
    echo -e "${RED}✗ Falha na conexão${NC}"
fi

# Testar PostgreSQL
printf "  PostgreSQL: "
if docker exec postgres psql -U laravel -d laravel -c "SELECT 1" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Conectado${NC} (laravel@postgres:5432)"
else
    echo -e "${RED}✗ Falha na conexão${NC}"
fi

# Testar Redis
printf "  Redis:      "
if docker exec redis redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Conectado${NC} (redis:6379)"
else
    echo -e "${RED}✗ Falha na conexão${NC}"
fi

# Testar MinIO
printf "  MinIO:      "
if docker exec minio mc ready local > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Conectado${NC} (minio:9000)"
else
    echo -e "${RED}✗ Falha na conexão${NC}"
fi

echo ""
echo -e "${YELLOW}Extensões PHP Instaladas:${NC}"
echo ""
if docker ps --format '{{.Names}}' | grep -q "^php$"; then
    docker exec php php -m 2>/dev/null | grep -E "^(pdo_mysql|pdo_pgsql|redis|imagick|xdebug|swoole|mongodb|amqp|gd|intl|bcmath|opcache|pcov|memcached|grpc)$" | while read ext; do
        printf "  ${GREEN}✓${NC} $ext\n"
    done
fi

echo ""
echo -e "${YELLOW}URLs de Acesso:${NC}"
echo ""
echo "  • https://traefik.localhost     - Dashboard Traefik"
echo "  • https://mail.localhost        - Mailpit (email testing)"
echo "  • https://minio.localhost       - MinIO Console"
echo "  • https://s3.localhost          - MinIO API (S3)"
echo "  • https://meuprojeto.test       - Seu projeto Laravel"
echo ""
echo -e "${YELLOW}Portas Locais:${NC}"
echo ""
echo "  ┌─────────────┬──────────────────┬─────────────────────────────┐"
echo "  │ Serviço     │ Porta            │ Credenciais                 │"
echo "  ├─────────────┼──────────────────┼─────────────────────────────┤"
echo "  │ MySQL 9.1   │ localhost:3306   │ laravel / secret            │"
echo "  │ PostgreSQL  │ localhost:5432   │ laravel / secret            │"
echo "  │ Redis 8     │ localhost:6379   │ sem senha                   │"
echo "  │ MinIO API   │ localhost:9000   │ minio / minio123            │"
echo "  │ MinIO Web   │ localhost:9001   │ minio / minio123            │"
echo "  │ Mailpit     │ localhost:1025   │ SMTP (sem auth)             │"
echo "  │ Mailpit Web │ localhost:8025   │ -                           │"
echo "  └─────────────┴──────────────────┴─────────────────────────────┘"
echo ""
