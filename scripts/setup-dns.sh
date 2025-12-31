#!/bin/bash

# ==============================================================================
# setup-dns.sh - Configura dnsmasq para resolução wildcard de *.test e *.localhost
# ==============================================================================
# Isso permite que qualquer subdomínio funcione automaticamente!
#
# Uso: sudo docker-local setup:dns
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
    echo -e "  ${CYAN}sudo docker-local setup:dns${NC}"
    echo ""
    exit 1
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
        
        # Parar systemd-resolved se estiver em conflito
        if systemctl is-active --quiet systemd-resolved; then
            echo -e "${YELLOW}Configuring systemd-resolved to coexist with dnsmasq...${NC}"
            
            # Criar diretório se não existir
            mkdir -p /etc/systemd/resolved.conf.d/
            
            # Verificar se já configurado
            if [ ! -f /etc/systemd/resolved.conf.d/dnsmasq.conf ]; then
                cat > /etc/systemd/resolved.conf.d/dnsmasq.conf << 'EOF'
[Resolve]
DNS=127.0.0.1
Domains=~test ~localhost
EOF
            fi
            
            # Desabilitar stub listener
            if grep -q "#DNSStubListener=yes" /etc/systemd/resolved.conf 2>/dev/null; then
                sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
            fi
            
            # Reiniciar resolved
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
        
        # Configurar NetworkManager para usar dnsmasq (se estiver instalado)
        if [ -d "/etc/NetworkManager/conf.d" ]; then
            if [ ! -f /etc/NetworkManager/conf.d/dnsmasq.conf ]; then
                echo -e "${YELLOW}Configuring NetworkManager...${NC}"
                cat > /etc/NetworkManager/conf.d/dnsmasq.conf << 'EOF'
[main]
dns=dnsmasq
EOF
            fi
        fi
        
        # Reiniciar dnsmasq
        echo -e "${YELLOW}Starting dnsmasq...${NC}"
        systemctl enable dnsmasq
        systemctl restart dnsmasq
        
        # Reiniciar NetworkManager se necessário
        if systemctl is-active --quiet NetworkManager; then
            systemctl restart NetworkManager
        fi
        
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
