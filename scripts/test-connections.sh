#!/bin/bash

# ==============================================================================
# test-connections.sh - Testa conexões com todos os serviços
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration
source "$PACKAGE_DIR/lib/config.sh"

# Load environment
load_env

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                  Testing Service Connections                   ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Função para testar conexão
test_connection() {
    local name=$1
    local container=$2
    local test_cmd=$3
    
    printf "Testing %-12s: " "$name"
    
    if ! docker ps --format '{{.Names}}' | grep -q "^$container$"; then
        echo -e "${RED}✗ Container not running${NC}"
        return 1
    fi
    
    if docker exec "$container" sh -c "$test_cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Connected${NC}"
        return 0
    else
        echo -e "${RED}✗ Connection failed${NC}"
        return 1
    fi
}

# Testar MySQL
test_connection "MySQL" "mysql" "mysqladmin ping -h localhost -u laravel -psecret"

# Testar PostgreSQL
test_connection "PostgreSQL" "postgres" "pg_isready -U laravel -d laravel"

# Testar Redis
test_connection "Redis" "redis" "redis-cli ping"

# Testar MinIO
test_connection "MinIO" "minio" "mc ready local 2>/dev/null || curl -sf http://localhost:9000/minio/health/live"

# Testar Mailpit
test_connection "Mailpit" "mailpit" "wget -q --spider http://localhost:8025"

# Testar Nginx
test_connection "Nginx" "nginx" "nginx -t"

# Testar PHP
test_connection "PHP-FPM" "php" "php-fpm -t"

echo ""

# Testar conexões de banco via PHP
echo -e "${YELLOW}Testing database connections via PHP:${NC}"
echo ""

# MySQL via PHP
printf "PHP → MySQL:    "
if docker exec php php -r "new PDO('mysql:host=mysql;dbname=laravel', 'laravel', 'secret');" 2>/dev/null; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
fi

# PostgreSQL via PHP
printf "PHP → PostgreSQL: "
if docker exec php php -r "new PDO('pgsql:host=postgres;dbname=laravel', 'laravel', 'secret');" 2>/dev/null; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
fi

# Redis via PHP
printf "PHP → Redis:    "
if docker exec php php -r "\$r = new Redis(); \$r->connect('redis', 6379); echo \$r->ping();" 2>/dev/null | grep -q "PONG"; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
fi

echo ""
echo -e "${GREEN}Connection tests complete.${NC}"
echo ""
