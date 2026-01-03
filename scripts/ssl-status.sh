#!/bin/bash

# ==============================================================================
# Script: ssl-status.sh - Show SSL certificate status
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration
source "$PACKAGE_DIR/lib/config.sh"

CERTS_DIR="$CONFIG_DIR/certs"

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              SSL Certificate Status                           ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if mkcert is installed
if ! command -v mkcert &> /dev/null; then
    echo -e "${RED}✗ mkcert is not installed${NC}"
    echo "  Install with: docker-local init"
    exit 1
fi

echo -e "${GREEN}✓ mkcert is installed${NC}"
echo ""

# Check mkcert CA
echo -e "${WHITE}Certificate Authority:${NC}"
CAROOT=$(mkcert -CAROOT 2>/dev/null)
if [ -d "$CAROOT" ]; then
    echo -e "  ${GREEN}✓${NC} CA installed at: ${CYAN}$CAROOT${NC}"
else
    echo -e "  ${RED}✗${NC} CA not installed. Run: ${CYAN}mkcert -install${NC}"
fi
echo ""

# Check certificates
echo -e "${WHITE}SSL Certificates:${NC}"
echo ""

check_cert() {
    local name="$1"
    local cert_file="$CERTS_DIR/${name}.crt"
    local key_file="$CERTS_DIR/${name}.key"

    if [ ! -f "$cert_file" ]; then
        echo -e "  ${YELLOW}○${NC} ${name}.crt - ${RED}Not found${NC}"
        return
    fi

    if [ ! -f "$key_file" ]; then
        echo -e "  ${YELLOW}○${NC} ${name}.key - ${RED}Not found${NC}"
        return
    fi

    # Get certificate info
    local expiry=$(openssl x509 -in "$cert_file" -noout -enddate 2>/dev/null | cut -d= -f2)
    local sans=$(openssl x509 -in "$cert_file" -noout -text 2>/dev/null | grep -A1 "Subject Alternative Name" | tail -1 | sed 's/DNS://g' | tr ',' '\n' | tr -d ' ')

    # Check if expired
    local expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$expiry" +%s 2>/dev/null)
    local now_epoch=$(date +%s)

    if [ "$expiry_epoch" -lt "$now_epoch" ]; then
        echo -e "  ${RED}✗${NC} ${name}.crt - ${RED}EXPIRED${NC}"
    else
        local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
        if [ "$days_left" -lt 30 ]; then
            echo -e "  ${YELLOW}!${NC} ${name}.crt - Expires in ${YELLOW}${days_left} days${NC}"
        else
            echo -e "  ${GREEN}✓${NC} ${name}.crt - Valid for ${GREEN}${days_left} days${NC}"
        fi
    fi

    echo -e "      ${DIM}Expires: $expiry${NC}"
    echo -e "      ${DIM}SANs:${NC}"
    echo "$sans" | while read -r san; do
        echo -e "        ${CYAN}• $san${NC}"
    done
    echo ""
}

check_cert "localhost"
check_cert "test"

# Check Traefik TLS configuration
echo -e "${WHITE}Traefik TLS Configuration:${NC}"
TLS_CONFIG="$CONFIG_DIR/traefik/dynamic/tls.yml"
if [ -f "$TLS_CONFIG" ]; then
    echo -e "  ${GREEN}✓${NC} TLS config: ${CYAN}$TLS_CONFIG${NC}"
else
    echo -e "  ${RED}✗${NC} TLS config not found"
fi
echo ""

# Check if Traefik is using HTTPS redirect
echo -e "${WHITE}HTTPS Redirection:${NC}"
# Get the package docker-compose file
COMPOSE_FILE="$PACKAGE_DIR/resources/docker/docker-compose.yml"
if [ -f "$COMPOSE_FILE" ]; then
    if grep -q "entrypoints.web.http.redirections.entryPoint.to=websecure" "$COMPOSE_FILE"; then
        echo -e "  ${GREEN}✓${NC} HTTP → HTTPS redirect is enabled"
    else
        echo -e "  ${YELLOW}○${NC} HTTP → HTTPS redirect is not configured"
    fi
else
    echo -e "  ${YELLOW}○${NC} Could not check docker-compose configuration"
fi
echo ""

# Summary
echo -e "${WHITE}Summary:${NC}"
if [ -f "$CERTS_DIR/localhost.crt" ] && [ -f "$CERTS_DIR/test.crt" ]; then
    echo -e "  ${GREEN}✓${NC} All certificates are in place"
    echo ""
    echo "  Domains with HTTPS:"
    echo -e "    • ${CYAN}*.localhost${NC} (e.g., traefik.localhost, mail.localhost)"
    echo -e "    • ${CYAN}*.test${NC} (e.g., myproject.test)"
else
    echo -e "  ${RED}✗${NC} Missing certificates. Run: ${CYAN}docker-local ssl:regenerate${NC}"
fi
echo ""
