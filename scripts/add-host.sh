#!/bin/bash

# ==============================================================================
# Helper para adicionar domínios ao /etc/hosts
# Uso: ./add-host.sh <dominio> [subdominio1] [subdominio2] ...
# Exemplo: ./add-host.sh meuprojeto.test api admin tenant1
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration
source "$PACKAGE_DIR/lib/config.sh"

if [ -z "$1" ]; then
    echo -e "${YELLOW}Uso: $0 <dominio-base> [subdominio1] [subdominio2] ...${NC}"
    echo ""
    echo "Exemplos:"
    echo "  $0 meuprojeto.test                    # Adiciona apenas meuprojeto.test"
    echo "  $0 meuprojeto.test api admin          # Adiciona meuprojeto.test, api.meuprojeto.test, admin.meuprojeto.test"
    echo "  $0 meuprojeto.test api admin tenant1  # Adiciona múltiplos subdomínios"
    exit 1
fi

DOMAIN=$1
shift
SUBDOMAINS="$@"

HOSTS_FILE="/etc/hosts"
MARKER="# Laravel Docker Dev"

# Verificar se estamos rodando como root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Este script precisa de permissões de root.${NC}"
    echo -e "Execute: ${BLUE}sudo $0 $DOMAIN $SUBDOMAINS${NC}"
    exit 1
fi

# Construir lista de hosts
HOSTS="$DOMAIN"
for sub in $SUBDOMAINS; do
    HOSTS="$HOSTS $sub.$DOMAIN"
done

echo -e "${BLUE}Adicionando hosts ao $HOSTS_FILE:${NC}"
echo -e "  ${GREEN}$HOSTS${NC}"
echo ""

# Verificar se já existe entrada para este domínio
if grep -q "127.0.0.1 $DOMAIN" "$HOSTS_FILE"; then
    echo -e "${YELLOW}⚠ Entrada para $DOMAIN já existe. Atualizando...${NC}"
    # Remover entrada existente
    sed -i "/127.0.0.1.*$DOMAIN/d" "$HOSTS_FILE"
fi

# Adicionar nova entrada
echo "127.0.0.1 $HOSTS $MARKER" >> "$HOSTS_FILE"

echo -e "${GREEN}✓ Hosts adicionados com sucesso!${NC}"
echo ""
echo "Entradas atuais para .test:"
grep "\.test" "$HOSTS_FILE" | grep -v "^#" || echo "  (nenhuma)"
echo ""

# Flush DNS cache
if command -v systemd-resolve &> /dev/null; then
    systemd-resolve --flush-caches 2>/dev/null || true
fi

if command -v resolvectl &> /dev/null; then
    resolvectl flush-caches 2>/dev/null || true
fi

echo -e "${GREEN}Cache DNS limpo.${NC}"
