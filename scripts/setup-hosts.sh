#!/bin/bash

# ==============================================================================
# setup-hosts.sh - Adiciona hostnames dos containers Docker ao /etc/hosts local
# ==============================================================================
# Isso permite que o PHP local conecte aos serviços usando os mesmos hostnames
# que os containers Docker usam (mysql, postgres, redis, etc.)
#
# Uso: sudo docker-local setup:hosts
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration
source "$PACKAGE_DIR/lib/config.sh"

# Additional color
CYAN='\033[0;36m'

HOSTS_FILE="/etc/hosts"
HOSTS_ENTRY="127.0.0.1 mysql postgres redis minio mailpit"

# ==============================================================================
# Verificar se está rodando como root
# ==============================================================================
if [ "$EUID" -ne 0 ]; then
    echo ""
    echo -e "${RED}Error: This command requires root privileges${NC}"
    echo ""
    echo -e "Please run with sudo:"
    echo -e "  ${CYAN}sudo docker-local setup:hosts${NC}"
    echo ""
    exit 1
fi

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║         Setting up local hostnames for Docker services        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# ==============================================================================
# Verificar se já está configurado
# ==============================================================================
if grep -q "127.0.0.1.*mysql.*postgres.*redis.*minio.*mailpit" "$HOSTS_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ Docker hostnames already configured in /etc/hosts${NC}"
    echo ""
    echo -e "${CYAN}Current entry:${NC}"
    grep "127.0.0.1.*mysql" "$HOSTS_FILE" | head -1
    echo ""
    echo -e "No changes needed."
    echo ""
    exit 0
fi

# Verificar se hosts individuais já existem (configuração parcial)
EXISTING_HOSTS=""
for host in mysql postgres redis minio mailpit; do
    if grep -q "127.0.0.1.*\b$host\b" "$HOSTS_FILE" 2>/dev/null; then
        EXISTING_HOSTS="$EXISTING_HOSTS $host"
    fi
done

if [ -n "$EXISTING_HOSTS" ]; then
    echo -e "${YELLOW}Warning: Some hostnames already exist in /etc/hosts:${NC}"
    echo -e "  $EXISTING_HOSTS"
    echo ""
    echo -e "These entries will be preserved. Adding missing hostnames..."
    echo ""
fi

# ==============================================================================
# Adicionar entrada
# ==============================================================================
echo -e "${BLUE}Adding Docker hostnames to $HOSTS_FILE...${NC}"

# Adicionar com comentário
{
    echo ""
    echo "# Laravel Docker Environment - Added by docker-local setup:hosts"
    echo "$HOSTS_ENTRY"
} >> "$HOSTS_FILE"

echo -e "${GREEN}✓ Hostnames added successfully!${NC}"
echo ""

# Mostrar o que foi adicionado
echo -e "${CYAN}Added entry:${NC}"
echo -e "  $HOSTS_ENTRY"
echo ""

# Testar resolução
echo -e "${BLUE}Testing hostname resolution...${NC}"
echo ""

ALL_OK=true
for host in mysql postgres redis minio mailpit; do
    if ping -c 1 -W 1 "$host" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $host → 127.0.0.1"
    else
        echo -e "  ${RED}✗${NC} $host - resolution failed"
        ALL_OK=false
    fi
done
echo ""

if [ "$ALL_OK" = true ]; then
    echo -e "${GREEN}All hostnames configured correctly!${NC}"
else
    echo -e "${YELLOW}Some hostnames may not be resolving. Check /etc/hosts manually.${NC}"
fi

echo ""
echo -e "${GREEN}Your .env can now use hostnames like:${NC}"
echo ""
echo "  DB_HOST=mysql"
echo "  REDIS_HOST=redis"
echo "  MAIL_HOST=mailpit"
echo ""
