#!/bin/bash

# ==============================================================================
# Script: ssl-regenerate.sh - Regenerate SSL certificates
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration
source "$PACKAGE_DIR/lib/config.sh"

CERTS_DIR="$CONFIG_DIR/certs"

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              SSL Certificate Generator                        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if mkcert is installed
if ! command -v mkcert &> /dev/null; then
    echo -e "${RED}✗ mkcert is not installed${NC}"
    echo ""
    echo "Installing mkcert..."

    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y libnss3-tools
            curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
            chmod +x mkcert-v*-linux-amd64
            sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert
        elif command -v pacman &> /dev/null; then
            sudo pacman -S mkcert
        elif command -v dnf &> /dev/null; then
            sudo dnf install mkcert
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install mkcert
        brew install nss
    fi
fi

echo -e "${GREEN}✓ mkcert is installed${NC}"
echo ""

# Install CA root if not already installed
echo -e "${YELLOW}Installing mkcert CA root (if needed)...${NC}"
mkcert -install

# Fix NSS database trust flags if needed (Chrome/Chromium)
if [ -d "$HOME/.pki/nssdb" ] && command -v certutil &> /dev/null; then
    # Get the CA certificate name from NSS database
    CA_NAME=$(certutil -L -d sql:$HOME/.pki/nssdb 2>/dev/null | grep "mkcert" | sed 's/\s*[A-Z,]*$//' | sed 's/\s*$//')

    if [ -n "$CA_NAME" ]; then
        # Check current trust flags
        CURRENT_FLAGS=$(certutil -L -d sql:$HOME/.pki/nssdb 2>/dev/null | grep "mkcert" | awk '{print $NF}')

        # If not trusted for SSL (missing T flag), fix it
        if [[ "$CURRENT_FLAGS" != *"CT"* ]] && [[ "$CURRENT_FLAGS" != "C,,"* || "$CURRENT_FLAGS" == "C,," ]]; then
            echo -e "  ${YELLOW}→ Fixing NSS database trust flags...${NC}"
            # Delete the existing entry
            certutil -D -d sql:$HOME/.pki/nssdb -n "$CA_NAME" 2>/dev/null || true
            # Add it back with correct trust flags
            certutil -A -d sql:$HOME/.pki/nssdb -n "$CA_NAME" -t "CT,C,C" -i "$(mkcert -CAROOT)/rootCA.pem" 2>/dev/null
            echo -e "  ${GREEN}✓ NSS database trust flags fixed${NC}"
        fi
    fi
fi

echo -e "${GREEN}✓ CA root installed${NC}"
echo ""

# Create certs directory
mkdir -p "$CERTS_DIR"

# Generate certificates
echo -e "${YELLOW}Generating SSL certificates...${NC}"
echo ""

# Certificate for *.localhost
# Note: OpenSSL doesn't properly match wildcards for .localhost TLD
# So we add explicit domains for known services
echo -e "${BLUE}→ Generating certificate for *.localhost${NC}"
echo -e "  ${DIM}Adding known services...${NC}"
LOCALHOST_DOMAINS=(
    "localhost"
    "*.localhost"
    "traefik.localhost"
    "mail.localhost"
    "minio.localhost"
    "s3.localhost"
    "whisper.localhost"
    "stream.localhost"
    "ws.localhost"
    "livekit.localhost"
)
echo -e "    ${DIM}+ traefik.localhost, mail.localhost, minio.localhost, ...${NC}"
mkcert -cert-file "$CERTS_DIR/localhost.crt" \
       -key-file "$CERTS_DIR/localhost.key" \
       "${LOCALHOST_DOMAINS[@]}"
echo -e "  ${GREEN}✓${NC} localhost.crt and localhost.key created (${#LOCALHOST_DOMAINS[@]} domains)"

# Certificate for *.test
# Note: OpenSSL doesn't properly match wildcards for .test TLD (not in public suffix list)
# So we scan for projects and add their domains explicitly
echo -e "${BLUE}→ Generating certificate for *.test${NC}"

# Start with base domains
DOMAINS=("test" "*.test")

# Get projects directory
PROJECTS_DIR="$(get_projects_dir)"

# Scan for Laravel projects and add their domains
if [ -d "$PROJECTS_DIR" ]; then
    echo -e "  ${DIM}Scanning for projects in $PROJECTS_DIR...${NC}"

    # Find all directories with artisan file (Laravel projects) - up to 4 levels deep
    while IFS= read -r project_dir; do
        if [ -n "$project_dir" ]; then
            project_name=$(basename "$project_dir")
            # Convert underscores to hyphens for domain (Laravel convention)
            domain_name=$(echo "$project_name" | tr '_' '-')
            # Add project.test domain
            DOMAINS+=("${domain_name}.test")
            # Add wildcard for subdomains (*.project.test) for apps with subdomain routing
            DOMAINS+=("*.${domain_name}.test")
            echo -e "    ${DIM}+ ${domain_name}.test, *.${domain_name}.test${NC}"
        fi
    done < <(find "$PROJECTS_DIR" -maxdepth 4 -name "artisan" -type f 2>/dev/null | xargs -I{} dirname {} 2>/dev/null | sort -u)
fi

# Generate the certificate with all domains
mkcert -cert-file "$CERTS_DIR/test.crt" \
       -key-file "$CERTS_DIR/test.key" \
       "${DOMAINS[@]}"
echo -e "  ${GREEN}✓${NC} test.crt and test.key created (${#DOMAINS[@]} domains)"

echo ""
print_success "Certificates generated in $CERTS_DIR"
echo ""

# Show certificate details
echo -e "${WHITE}Certificate Details:${NC}"
echo ""

for cert in localhost test; do
    echo -e "  ${CYAN}${cert}.crt:${NC}"
    expiry=$(openssl x509 -in "$CERTS_DIR/${cert}.crt" -noout -enddate 2>/dev/null | cut -d= -f2)
    sans=$(openssl x509 -in "$CERTS_DIR/${cert}.crt" -noout -text 2>/dev/null | grep -A1 "Subject Alternative Name" | tail -1 | sed 's/DNS://g')
    echo "    Expires: $expiry"
    echo "    SANs: $sans"
    echo ""
done

# Restart Traefik if running
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^traefik$"; then
    echo -e "${YELLOW}Restarting Traefik to load new certificates...${NC}"
    docker restart traefik
    echo -e "${GREEN}✓ Traefik restarted${NC}"
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                 SSL Setup Complete! 🔒                        ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Your domains are now served with HTTPS:"
echo -e "  • ${CYAN}https://*.localhost${NC} (e.g., https://traefik.localhost)"
echo -e "  • ${CYAN}https://*.test${NC} - All detected Laravel projects included"
echo ""
echo -e "${DIM}Run 'docker-local ssl:regenerate' after adding new projects${NC}"
echo -e "${DIM}to include their domains in the certificate.${NC}"
echo ""
