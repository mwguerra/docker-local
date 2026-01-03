#!/bin/bash

# ==============================================================================
# setup-dns.sh - Configura dnsmasq para resolução wildcard de *.test e *.localhost
# ==============================================================================
# Isso permite que qualquer subdomínio funcione automaticamente!
#
# Uso: sudo "$(which docker-local)" setup:dns
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration
source "$PACKAGE_DIR/lib/config.sh"

# Additional color
CYAN='\033[0;36m'

# ==============================================================================
# Verificar se está rodando como root
# ==============================================================================
if [ "$EUID" -ne 0 ]; then
    echo ""
    echo -e "${RED}Error: This command requires root privileges${NC}"
    echo ""
    echo -e "Please run with sudo:"
    echo -e "  ${CYAN}sudo \"\$(which docker-local)\" setup:dns${NC}"
    echo ""
    exit 1
fi

# ==============================================================================
# Handle --uninstall flag
# ==============================================================================
if [ "$1" = "--uninstall" ] || [ "$1" = "-u" ]; then
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║         Removing docker-local DNS Configuration               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""

    removed_files=0

    # Remove Linux dnsmasq configs
    if [ -f /etc/dnsmasq.d/laravel-dev.conf ]; then
        rm -f /etc/dnsmasq.d/laravel-dev.conf
        echo -e "${GREEN}✓${NC} Removed /etc/dnsmasq.d/laravel-dev.conf"
        removed_files=$((removed_files + 1))
    fi

    if [ -f /etc/dnsmasq.d/docker-local-listen.conf ]; then
        rm -f /etc/dnsmasq.d/docker-local-listen.conf
        echo -e "${GREEN}✓${NC} Removed /etc/dnsmasq.d/docker-local-listen.conf"
        removed_files=$((removed_files + 1))
    fi

    # Remove systemd-resolved drop-in
    if [ -f /etc/systemd/resolved.conf.d/docker-local.conf ]; then
        rm -f /etc/systemd/resolved.conf.d/docker-local.conf
        echo -e "${GREEN}✓${NC} Removed /etc/systemd/resolved.conf.d/docker-local.conf"
        removed_files=$((removed_files + 1))
    fi

    # Remove old file name if exists (from previous versions)
    if [ -f /etc/systemd/resolved.conf.d/dnsmasq.conf ]; then
        rm -f /etc/systemd/resolved.conf.d/dnsmasq.conf
        echo -e "${GREEN}✓${NC} Removed /etc/systemd/resolved.conf.d/dnsmasq.conf (legacy)"
        removed_files=$((removed_files + 1))
    fi

    # Remove macOS configs
    if [ -f /usr/local/etc/dnsmasq.d/laravel-dev.conf ]; then
        rm -f /usr/local/etc/dnsmasq.d/laravel-dev.conf
        echo -e "${GREEN}✓${NC} Removed /usr/local/etc/dnsmasq.d/laravel-dev.conf"
        removed_files=$((removed_files + 1))
    fi

    if [ -f /etc/resolver/test ]; then
        rm -f /etc/resolver/test
        echo -e "${GREEN}✓${NC} Removed /etc/resolver/test"
        removed_files=$((removed_files + 1))
    fi

    if [ -f /etc/resolver/localhost ]; then
        rm -f /etc/resolver/localhost
        echo -e "${GREEN}✓${NC} Removed /etc/resolver/localhost"
        removed_files=$((removed_files + 1))
    fi

    if [ $removed_files -eq 0 ]; then
        echo -e "${YELLOW}No docker-local DNS configuration files found.${NC}"
    else
        echo ""
        echo -e "${YELLOW}Restarting services...${NC}"

        # Restart services
        if systemctl is-active --quiet dnsmasq 2>/dev/null; then
            systemctl restart dnsmasq || true
            echo -e "${GREEN}✓${NC} Restarted dnsmasq"
        fi

        if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
            systemctl restart systemd-resolved
            echo -e "${GREEN}✓${NC} Restarted systemd-resolved"
        fi

        if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
            brew services restart dnsmasq 2>/dev/null || true
        fi

        echo ""
        echo -e "${GREEN}✓ DNS configuration removed successfully.${NC}"
        echo -e "  ${DIM}Your system DNS settings have been restored.${NC}"
    fi

    echo ""
    exit 0
fi

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║         Configuração de DNS Wildcard com dnsmasq              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# ==============================================================================
# Verificar se já está configurado
# ==============================================================================
DNSMASQ_CONFIG="/etc/dnsmasq.d/laravel-dev.conf"
MACOS_CONFIG="/usr/local/etc/dnsmasq.d/laravel-dev.conf"

check_existing_config() {
    # Linux
    if [ -f "$DNSMASQ_CONFIG" ]; then
        if grep -q "address=/.test/127.0.0.1" "$DNSMASQ_CONFIG" 2>/dev/null; then
            return 0
        fi
    fi
    
    # macOS
    if [ -f "$MACOS_CONFIG" ]; then
        if grep -q "address=/.test/127.0.0.1" "$MACOS_CONFIG" 2>/dev/null; then
            return 0
        fi
    fi
    
    return 1
}

if check_existing_config; then
    echo -e "${GREEN}✓ DNS wildcard already configured!${NC}"
    echo ""
    
    # Verificar se dnsmasq está rodando
    if systemctl is-active --quiet dnsmasq 2>/dev/null; then
        echo -e "${GREEN}✓ dnsmasq service is running${NC}"
    elif pgrep -x dnsmasq > /dev/null 2>&1; then
        echo -e "${GREEN}✓ dnsmasq is running${NC}"
    else
        echo -e "${YELLOW}⚠ dnsmasq may not be running${NC}"
        echo -e "  Try: ${CYAN}sudo systemctl start dnsmasq${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}Testing DNS resolution:${NC}"
    if ping -c 1 -W 1 test.test > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} *.test resolves to 127.0.0.1"
    else
        echo -e "  ${YELLOW}○${NC} *.test may not be resolving"
    fi
    echo ""
    echo -e "No changes needed."
    echo ""
    exit 0
fi

# ==============================================================================
# Detectar sistema operacional e instalar/configurar
# ==============================================================================
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Verificar se é Ubuntu/Debian
    if command -v apt-get &> /dev/null; then
        echo -e "${BLUE}Sistema detectado: Ubuntu/Debian${NC}"
        echo ""
        
        # Verificar se dnsmasq já está instalado
        if ! command -v dnsmasq &> /dev/null; then
            echo -e "${YELLOW}Installing dnsmasq...${NC}"
            apt-get update
            apt-get install -y dnsmasq
        else
            echo -e "${GREEN}✓ dnsmasq already installed${NC}"
        fi
        
        # Configure systemd-resolved to route .test and .localhost to dnsmasq
        # This is ADDITIVE - it only adds routing for specific domains
        # and does NOT modify the main resolved.conf or disable any features
        if systemctl is-active --quiet systemd-resolved; then
            echo -e "${YELLOW}Configuring systemd-resolved to route .test/.localhost to dnsmasq...${NC}"

            # Create drop-in directory
            mkdir -p /etc/systemd/resolved.conf.d/

            # Create drop-in config that ONLY routes .test and .localhost domains to dnsmasq
            # This preserves all other DNS settings - only these specific domains go to 127.0.0.1
            if [ ! -f /etc/systemd/resolved.conf.d/docker-local.conf ]; then
                cat > /etc/systemd/resolved.conf.d/docker-local.conf << 'EOF'
# docker-local: Route only .test and .localhost domains to local dnsmasq
# This is additive and does not modify your existing DNS configuration
# Your normal DNS servers remain unchanged for all other domains
# To remove: sudo rm /etc/systemd/resolved.conf.d/docker-local.conf && sudo systemctl restart systemd-resolved
[Resolve]
DNS=127.0.0.1#53
Domains=~test. ~localhost.
FallbackDNS=
EOF
                echo -e "${GREEN}✓ Created /etc/systemd/resolved.conf.d/docker-local.conf${NC}"
                echo -e "  ${DIM}(Routes only .test and .localhost to dnsmasq on 127.0.0.1)${NC}"
            fi

            # Restart resolved to pick up changes
            systemctl restart systemd-resolved
        fi
        
        # Criar configuração do dnsmasq
        echo -e "${YELLOW}Configuring dnsmasq...${NC}"
        mkdir -p /etc/dnsmasq.d
        cat > /etc/dnsmasq.d/laravel-dev.conf << 'EOF'
# Laravel Docker Development - DNS Wildcard
# Redireciona *.test e *.localhost para 127.0.0.1

# Wildcard para .test
address=/.test/127.0.0.1

# Wildcard para .localhost
address=/.localhost/127.0.0.1

# Cache DNS
cache-size=1000
EOF
        
        # Configure dnsmasq to listen on a non-conflicting address
        # This avoids conflicts with systemd-resolved's stub listener
        if [ ! -f /etc/dnsmasq.d/docker-local-listen.conf ]; then
            cat > /etc/dnsmasq.d/docker-local-listen.conf << 'EOF'
# docker-local: Listen configuration
# Listen on 127.0.0.1 (not 127.0.0.53 which systemd-resolved uses)
listen-address=127.0.0.1
bind-interfaces
EOF
        fi

        # Start dnsmasq
        echo -e "${YELLOW}Starting dnsmasq...${NC}"
        systemctl enable dnsmasq
        systemctl restart dnsmasq

        # NOTE: We intentionally do NOT modify NetworkManager settings
        # as that could disrupt network connectivity
        
    elif command -v pacman &> /dev/null; then
        echo -e "${BLUE}Sistema detectado: Arch Linux${NC}"
        echo ""
        
        if ! command -v dnsmasq &> /dev/null; then
            pacman -S --noconfirm dnsmasq
        fi
        
        mkdir -p /etc/dnsmasq.d
        cat > /etc/dnsmasq.d/laravel-dev.conf << 'EOF'
address=/.test/127.0.0.1
address=/.localhost/127.0.0.1
EOF
        
        systemctl enable dnsmasq
        systemctl restart dnsmasq
        
    elif command -v dnf &> /dev/null; then
        echo -e "${BLUE}Sistema detectado: Fedora/RHEL${NC}"
        echo ""
        
        if ! command -v dnsmasq &> /dev/null; then
            dnf install -y dnsmasq
        fi
        
        mkdir -p /etc/dnsmasq.d
        cat > /etc/dnsmasq.d/laravel-dev.conf << 'EOF'
address=/.test/127.0.0.1
address=/.localhost/127.0.0.1
EOF
        
        systemctl enable dnsmasq
        systemctl restart dnsmasq
    fi
    
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${BLUE}Sistema detectado: macOS${NC}"
    echo ""
    
    # Instalar via Homebrew
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}Homebrew não encontrado. Por favor, instale primeiro.${NC}"
        exit 1
    fi
    
    if ! command -v dnsmasq &> /dev/null; then
        brew install dnsmasq
    fi
    
    # Configurar
    mkdir -p /usr/local/etc/dnsmasq.d
    cat > /usr/local/etc/dnsmasq.d/laravel-dev.conf << 'EOF'
address=/.test/127.0.0.1
address=/.localhost/127.0.0.1
EOF
    
    # Configurar resolver
    mkdir -p /etc/resolver
    
    if [ ! -f /etc/resolver/test ]; then
        echo "nameserver 127.0.0.1" > /etc/resolver/test
    fi
    
    if [ ! -f /etc/resolver/localhost ]; then
        echo "nameserver 127.0.0.1" > /etc/resolver/localhost
    fi
    
    # Iniciar serviço
    brew services start dnsmasq
fi

echo ""
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              DNS Wildcard Configured! 🎉                      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "Now you can use any .test or .localhost domain:"
echo ""
echo "  • https://myproject.test"
echo "  • https://api.myproject.test"
echo "  • https://admin.myproject.test"
echo "  • https://anything.test"
echo ""
echo -e "${YELLOW}Test with:${NC} ping myproject.test"
echo ""
echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
echo -e "${WHITE}Files created (to uninstall, remove these and restart services):${NC}"
echo ""
if [ -f /etc/dnsmasq.d/laravel-dev.conf ]; then
    echo -e "  ${DIM}•${NC} /etc/dnsmasq.d/laravel-dev.conf"
fi
if [ -f /etc/dnsmasq.d/docker-local-listen.conf ]; then
    echo -e "  ${DIM}•${NC} /etc/dnsmasq.d/docker-local-listen.conf"
fi
if [ -f /etc/systemd/resolved.conf.d/docker-local.conf ]; then
    echo -e "  ${DIM}•${NC} /etc/systemd/resolved.conf.d/docker-local.conf"
fi
if [ -f /usr/local/etc/dnsmasq.d/laravel-dev.conf ]; then
    echo -e "  ${DIM}•${NC} /usr/local/etc/dnsmasq.d/laravel-dev.conf"
fi
if [ -f /etc/resolver/test ]; then
    echo -e "  ${DIM}•${NC} /etc/resolver/test"
fi
if [ -f /etc/resolver/localhost ]; then
    echo -e "  ${DIM}•${NC} /etc/resolver/localhost"
fi
echo ""
echo -e "${DIM}To uninstall: sudo \"\$(which docker-local)\" setup:dns --uninstall${NC}"
echo ""
