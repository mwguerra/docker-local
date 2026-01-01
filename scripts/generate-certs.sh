#!/bin/bash

# ==============================================================================
# generate-certs.sh - Regenera certificados SSL com mkcert
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration
source "$PACKAGE_DIR/lib/config.sh"

# Certificates go to user config directory
CERTS_DIR="$CONFIG_DIR/certs"

echo -e "${BLUE}Generating SSL certificates...${NC}"

# Verificar mkcert
if ! command -v mkcert &> /dev/null; then
    echo "mkcert not found. Installing..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y libnss3-tools
            curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
            chmod +x mkcert-v*-linux-amd64
            sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install mkcert nss
    fi
fi

# Instalar CA raiz
mkcert -install

# Criar diretório de certificados
mkdir -p "$CERTS_DIR"

# Gerar certificado para *.localhost
echo -e "${BLUE}→ Generating certificate for *.localhost${NC}"
mkcert -cert-file "$CERTS_DIR/localhost.crt" \
       -key-file "$CERTS_DIR/localhost.key" \
       "localhost" "*.localhost"

# Gerar certificado para *.test
echo -e "${BLUE}→ Generating certificate for *.test${NC}"
mkcert -cert-file "$CERTS_DIR/test.crt" \
       -key-file "$CERTS_DIR/test.key" \
       "test" "*.test"

print_success "Certificates generated in $CERTS_DIR"
echo ""
echo "Files created:"
ls -la "$CERTS_DIR"

print_info "These certificates will be used by Traefik for HTTPS"
