#!/bin/bash

# ==============================================================================
# Script: ssl-status.sh - Show SSL certificate status
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration
source "$PACKAGE_DIR/lib/config.sh"

# Additional colors not in config.sh
CYAN='\033[0;36m'
WHITE='\033[1;37m'

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

# Check browser trust (NSS database for Chrome/Chromium)
echo -e "${WHITE}Browser Trust (NSS Database):${NC}"
NSS_DB="$HOME/.pki/nssdb"
NSS_TRUST_OK=true

if [ -d "$NSS_DB" ] && command -v certutil &> /dev/null; then
    # Get the CA name from mkcert
    CA_NAME=$(certutil -L -d "sql:$NSS_DB" 2>/dev/null | grep -i "mkcert" | sed 's/\s*[A-Z,]*$//' | sed 's/\s*$//')

    if [ -n "$CA_NAME" ]; then
        # Get trust flags
        TRUST_FLAGS=$(certutil -L -d "sql:$NSS_DB" 2>/dev/null | grep -i "mkcert" | awk '{print $NF}')

        # Check if trust flags include 'T' for SSL (should be CT,, or CT,C,C)
        if echo "$TRUST_FLAGS" | grep -q "CT"; then
            echo -e "  ${GREEN}✓${NC} CA trusted for SSL in Chrome/Chromium"
            echo -e "      ${DIM}Trust flags: $TRUST_FLAGS${NC}"
        else
            echo -e "  ${RED}✗${NC} CA NOT trusted for SSL (flags: $TRUST_FLAGS)"
            echo -e "      ${DIM}Expected: CT,C,C or CT,, (T = trusted for SSL)${NC}"
            echo ""
            echo -e "  ${YELLOW}This is why your browser shows 'Not Secure'!${NC}"
            echo ""
            echo -e "  ${WHITE}To fix, run:${NC}"
            echo -e "    ${CYAN}docker-local ssl:regenerate${NC}"
            echo ""
            echo -e "  ${DIM}Or manually fix with:${NC}"
            echo -e "    ${DIM}certutil -D -d sql:\$HOME/.pki/nssdb -n \"$CA_NAME\"${NC}"
            echo -e "    ${DIM}certutil -A -d sql:\$HOME/.pki/nssdb -n \"$CA_NAME\" -t \"CT,C,C\" -i \"\$(mkcert -CAROOT)/rootCA.pem\"${NC}"
            NSS_TRUST_OK=false
        fi
    else
        echo -e "  ${YELLOW}○${NC} mkcert CA not found in NSS database"
        echo -e "      ${DIM}Run: ${CYAN}docker-local ssl:regenerate${NC}"
        NSS_TRUST_OK=false
    fi
else
    if [ ! -d "$NSS_DB" ]; then
        echo -e "  ${YELLOW}○${NC} NSS database not found at $NSS_DB"
    fi
    if ! command -v certutil &> /dev/null; then
        echo -e "  ${YELLOW}○${NC} certutil not installed (install libnss3-tools)"
    fi
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
