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

# Additional colors
CYAN='\033[0;36m'
WHITE='\033[1;37m'

# Install CA root
mkcert -install

# Fix NSS trust flags for Chrome/Chromium
# mkcert -install sometimes sets trust flags to C,, instead of CT,C,C
# The 'T' flag is required for SSL/TLS server authentication
fix_nss_trust() {
    local NSS_DB="$HOME/.pki/nssdb"

    if [ -d "$NSS_DB" ] && command -v certutil &> /dev/null; then
        # Get the CA name from NSS database
        local CA_NAME=$(certutil -L -d "sql:$NSS_DB" 2>/dev/null | grep -i "mkcert" | sed 's/\s*[A-Z,]*$//' | sed 's/\s*$//')

        if [ -n "$CA_NAME" ]; then
            local TRUST_FLAGS=$(certutil -L -d "sql:$NSS_DB" 2>/dev/null | grep -i "mkcert" | awk '{print $NF}')

            # Check if trust flags are missing 'T' for SSL
            if ! echo "$TRUST_FLAGS" | grep -q "CT"; then
                echo -e "${YELLOW}→ Fixing NSS trust flags for Chrome/Chromium...${NC}"

                # Get the CA root path
                local CA_ROOT=$(mkcert -CAROOT 2>/dev/null)

                if [ -f "$CA_ROOT/rootCA.pem" ]; then
                    # Remove old entry and add with correct trust flags
                    certutil -D -d "sql:$NSS_DB" -n "$CA_NAME" 2>/dev/null || true
                    certutil -A -d "sql:$NSS_DB" -n "$CA_NAME" -t "CT,C,C" -i "$CA_ROOT/rootCA.pem"
                    echo -e "${GREEN}✓ NSS trust flags fixed (CT,C,C)${NC}"
                    echo -e "${DIM}  Restart your browser for changes to take effect${NC}"
                fi
            else
                echo -e "${GREEN}✓ NSS trust flags already correct ($TRUST_FLAGS)${NC}"
            fi
        fi
    fi
}

fix_nss_trust

# Create certificates directory
mkdir -p "$CERTS_DIR"

# Gerar certificado para *.localhost
echo -e "${BLUE}→ Generating certificate for *.localhost${NC}"
mkcert -cert-file "$CERTS_DIR/localhost.crt" \
       -key-file "$CERTS_DIR/localhost.key" \
       "localhost" "*.localhost" \
       "traefik.localhost" "mail.localhost" "minio.localhost" "s3.localhost" \
       "whisper.localhost" "stream.localhost" "ws.localhost" "livekit.localhost"

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
