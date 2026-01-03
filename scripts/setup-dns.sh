#!/bin/bash

# ==============================================================================
# setup-dns.sh - Configure wildcard DNS for *.test and *.localhost domains
# ==============================================================================
# This enables any subdomain to resolve to 127.0.0.1 automatically!
#
# Usage: sudo "$(which docker-local)" setup:dns
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration
source "$PACKAGE_DIR/lib/config.sh"

# Additional color
CYAN='\033[0;36m'

# ==============================================================================
# Check if running as root
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
# Configuration paths
# ==============================================================================
NM_DNSMASQ_DIR="/etc/NetworkManager/dnsmasq.d"
NM_CONF_DIR="/etc/NetworkManager/conf.d"
NM_DNSMASQ_CONF="$NM_DNSMASQ_DIR/docker-local.conf"
NM_DNS_CONF="$NM_CONF_DIR/docker-local-dns.conf"
NM_RESOLV_CONF="/var/run/NetworkManager/resolv.conf"
SYSTEMD_RESOLV_CONF="/run/systemd/resolve/stub-resolv.conf"

# Legacy paths (for cleanup)
LEGACY_DNSMASQ_CONF="/etc/dnsmasq.d/laravel-dev.conf"
LEGACY_DNSMASQ_LISTEN="/etc/dnsmasq.d/docker-local-listen.conf"
LEGACY_RESOLVED_CONF="/etc/systemd/resolved.conf.d/docker-local.conf"
LEGACY_RESOLVED_CONF2="/etc/systemd/resolved.conf.d/dnsmasq.conf"

# macOS paths - detect Homebrew prefix (Intel: /usr/local, Apple Silicon: /opt/homebrew)
if [[ "$OSTYPE" == "darwin"* ]]; then
    HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix 2>/dev/null || echo "/usr/local")}"
else
    HOMEBREW_PREFIX="/usr/local"
fi
MACOS_DNSMASQ_DIR="$HOMEBREW_PREFIX/etc/dnsmasq.d"
MACOS_DNSMASQ_CONF="$MACOS_DNSMASQ_DIR/docker-local.conf"

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

    # Remove NetworkManager dnsmasq config
    if [ -f "$NM_DNSMASQ_CONF" ]; then
        rm -f "$NM_DNSMASQ_CONF"
        echo -e "${GREEN}✓${NC} Removed $NM_DNSMASQ_CONF"
        removed_files=$((removed_files + 1))
    fi

    # Remove NetworkManager dns=dnsmasq config
    if [ -f "$NM_DNS_CONF" ]; then
        rm -f "$NM_DNS_CONF"
        echo -e "${GREEN}✓${NC} Removed $NM_DNS_CONF"
        removed_files=$((removed_files + 1))
    fi

    # Remove legacy dnsmasq config (from old versions)
    if [ -f "$NM_CONF_DIR/dnsmasq.conf" ]; then
        rm -f "$NM_CONF_DIR/dnsmasq.conf"
        echo -e "${GREEN}✓${NC} Removed $NM_CONF_DIR/dnsmasq.conf (legacy)"
        removed_files=$((removed_files + 1))
    fi

    # Restore resolv.conf to systemd-resolved (Linux)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -L /etc/resolv.conf ]; then
            current_target=$(readlink -f /etc/resolv.conf 2>/dev/null || echo "")
            if [[ "$current_target" == *"NetworkManager"* ]]; then
                rm -f /etc/resolv.conf
                ln -s "$SYSTEMD_RESOLV_CONF" /etc/resolv.conf
                echo -e "${GREEN}✓${NC} Restored /etc/resolv.conf to systemd-resolved"
                removed_files=$((removed_files + 1))
            fi
        fi
    fi

    # Remove legacy standalone dnsmasq configs
    if [ -f "$LEGACY_DNSMASQ_CONF" ]; then
        rm -f "$LEGACY_DNSMASQ_CONF"
        echo -e "${GREEN}✓${NC} Removed $LEGACY_DNSMASQ_CONF (legacy)"
        removed_files=$((removed_files + 1))
    fi

    if [ -f "$LEGACY_DNSMASQ_LISTEN" ]; then
        rm -f "$LEGACY_DNSMASQ_LISTEN"
        echo -e "${GREEN}✓${NC} Removed $LEGACY_DNSMASQ_LISTEN (legacy)"
        removed_files=$((removed_files + 1))
    fi

    # Remove legacy systemd-resolved drop-ins
    if [ -f "$LEGACY_RESOLVED_CONF" ]; then
        rm -f "$LEGACY_RESOLVED_CONF"
        echo -e "${GREEN}✓${NC} Removed $LEGACY_RESOLVED_CONF (legacy)"
        removed_files=$((removed_files + 1))
    fi

    if [ -f "$LEGACY_RESOLVED_CONF2" ]; then
        rm -f "$LEGACY_RESOLVED_CONF2"
        echo -e "${GREEN}✓${NC} Removed $LEGACY_RESOLVED_CONF2 (legacy)"
        removed_files=$((removed_files + 1))
    fi

    # Remove macOS configs
    if [ -f "$MACOS_DNSMASQ_CONF" ]; then
        rm -f "$MACOS_DNSMASQ_CONF"
        echo -e "${GREEN}✓${NC} Removed $MACOS_DNSMASQ_CONF"
        removed_files=$((removed_files + 1))
    fi

    # Remove legacy macOS config name
    MACOS_LEGACY_CONF="$MACOS_DNSMASQ_DIR/laravel-dev.conf"
    if [ -f "$MACOS_LEGACY_CONF" ]; then
        rm -f "$MACOS_LEGACY_CONF"
        echo -e "${GREEN}✓${NC} Removed $MACOS_LEGACY_CONF (legacy)"
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

        # Restart NetworkManager (Linux)
        if systemctl is-active --quiet NetworkManager 2>/dev/null; then
            systemctl restart NetworkManager
            echo -e "${GREEN}✓${NC} Restarted NetworkManager"
        fi

        # Stop standalone dnsmasq if running (we don't need it anymore)
        if systemctl is-active --quiet dnsmasq 2>/dev/null; then
            systemctl stop dnsmasq
            systemctl disable dnsmasq 2>/dev/null || true
            echo -e "${GREEN}✓${NC} Stopped standalone dnsmasq service"
        fi

        # Restart systemd-resolved if active
        if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
            systemctl restart systemd-resolved
            echo -e "${GREEN}✓${NC} Restarted systemd-resolved"
        fi

        # macOS
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
echo "║       Wildcard DNS Configuration with NetworkManager          ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# ==============================================================================
# Check if already configured
# ==============================================================================
check_existing_config() {
    # Linux - check NetworkManager dnsmasq config
    if [ -f "$NM_DNSMASQ_CONF" ]; then
        if grep -q "address=/.test/127.0.0.1" "$NM_DNSMASQ_CONF" 2>/dev/null; then
            return 0
        fi
    fi

    # macOS
    if [ -f "$MACOS_DNSMASQ_CONF" ]; then
        if grep -q "address=/.test/127.0.0.1" "$MACOS_DNSMASQ_CONF" 2>/dev/null; then
            return 0
        fi
    fi

    return 1
}

if check_existing_config; then
    echo -e "${GREEN}✓ DNS wildcard already configured!${NC}"
    echo ""

    # Check if NetworkManager's dnsmasq is running
    if pgrep -f "dnsmasq.*NetworkManager" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ NetworkManager's dnsmasq is running${NC}"
    elif pgrep -x dnsmasq > /dev/null 2>&1; then
        echo -e "${GREEN}✓ dnsmasq is running${NC}"
    else
        echo -e "${YELLOW}⚠ dnsmasq may not be running${NC}"
        echo -e "  Try: ${CYAN}sudo systemctl restart NetworkManager${NC}"
    fi

    # Check resolv.conf is pointing to NetworkManager
    if [ -L /etc/resolv.conf ]; then
        current_target=$(readlink -f /etc/resolv.conf 2>/dev/null || echo "")
        if [[ "$current_target" == *"NetworkManager"* ]]; then
            echo -e "${GREEN}✓ /etc/resolv.conf points to NetworkManager${NC}"
        else
            echo ""
            echo -e "${YELLOW}⚠ /etc/resolv.conf not pointing to NetworkManager, fixing...${NC}"
            rm -f /etc/resolv.conf
            ln -s "$NM_RESOLV_CONF" /etc/resolv.conf
            echo -e "${GREEN}✓ Fixed /etc/resolv.conf symlink${NC}"
        fi
    fi

    echo ""
    echo -e "${CYAN}Testing DNS resolution:${NC}"
    if ping -c 1 -W 2 test.test > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} *.test resolves to 127.0.0.1"
    else
        echo -e "  ${YELLOW}○${NC} *.test may not be resolving yet"
        echo -e "  ${DIM}Try restarting NetworkManager: sudo systemctl restart NetworkManager${NC}"
    fi
    echo ""
    echo -e "No changes needed."
    echo ""
    exit 0
fi

# ==============================================================================
# Detect operating system and configure
# ==============================================================================
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Check if NetworkManager is available
    if ! command -v nmcli &> /dev/null; then
        echo -e "${RED}Error: NetworkManager is not installed.${NC}"
        echo -e "This script requires NetworkManager to be installed and running."
        exit 1
    fi

    if ! systemctl is-active --quiet NetworkManager 2>/dev/null; then
        echo -e "${RED}Error: NetworkManager is not running.${NC}"
        echo -e "Please start NetworkManager first: sudo systemctl start NetworkManager"
        exit 1
    fi

    echo -e "${BLUE}Detected: Linux with NetworkManager${NC}"
    echo ""

    # Clean up legacy configurations
    echo -e "${YELLOW}Cleaning up legacy configurations...${NC}"

    # Stop standalone dnsmasq if running (we'll use NetworkManager's instead)
    if systemctl is-active --quiet dnsmasq 2>/dev/null; then
        systemctl stop dnsmasq
        systemctl disable dnsmasq 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Disabled standalone dnsmasq service (using NetworkManager's instead)"
    fi

    # Remove legacy configs
    [ -f "$LEGACY_DNSMASQ_CONF" ] && rm -f "$LEGACY_DNSMASQ_CONF"
    [ -f "$LEGACY_DNSMASQ_LISTEN" ] && rm -f "$LEGACY_DNSMASQ_LISTEN"
    [ -f "$LEGACY_RESOLVED_CONF" ] && rm -f "$LEGACY_RESOLVED_CONF"
    [ -f "$LEGACY_RESOLVED_CONF2" ] && rm -f "$LEGACY_RESOLVED_CONF2"

    # Step 1: Enable dnsmasq plugin in NetworkManager
    echo -e "${YELLOW}Configuring NetworkManager to use dnsmasq...${NC}"
    mkdir -p "$NM_CONF_DIR"

    cat > "$NM_DNS_CONF" << 'EOF'
# docker-local: Enable dnsmasq for DNS resolution
# This allows NetworkManager to handle wildcard domains like *.test
[main]
dns=dnsmasq
EOF
    echo -e "${GREEN}✓${NC} Created $NM_DNS_CONF"

    # Step 2: Configure dnsmasq wildcard rules
    echo -e "${YELLOW}Configuring dnsmasq wildcard rules...${NC}"
    mkdir -p "$NM_DNSMASQ_DIR"

    cat > "$NM_DNSMASQ_CONF" << 'EOF'
# docker-local: Wildcard DNS for development domains
# Routes *.test and *.localhost to 127.0.0.1

# Wildcard for .test domains
address=/.test/127.0.0.1

# Wildcard for .localhost domains
address=/.localhost/127.0.0.1
EOF
    echo -e "${GREEN}✓${NC} Created $NM_DNSMASQ_CONF"

    # Step 3: Point resolv.conf to NetworkManager's resolver
    # This bypasses systemd-resolved which doesn't handle routing domains properly
    echo -e "${YELLOW}Configuring system resolver...${NC}"

    if [ -e /etc/resolv.conf ]; then
        # Check if it's a symlink
        if [ -L /etc/resolv.conf ]; then
            current_target=$(readlink -f /etc/resolv.conf 2>/dev/null || echo "")
            if [[ "$current_target" != *"NetworkManager"* ]]; then
                rm -f /etc/resolv.conf
                ln -s "$NM_RESOLV_CONF" /etc/resolv.conf
                echo -e "${GREEN}✓${NC} Pointed /etc/resolv.conf to NetworkManager"
            else
                echo -e "${GREEN}✓${NC} /etc/resolv.conf already points to NetworkManager"
            fi
        else
            # It's a regular file, back it up and replace
            mv /etc/resolv.conf /etc/resolv.conf.docker-local-backup
            ln -s "$NM_RESOLV_CONF" /etc/resolv.conf
            echo -e "${GREEN}✓${NC} Pointed /etc/resolv.conf to NetworkManager (backup saved)"
        fi
    else
        ln -s "$NM_RESOLV_CONF" /etc/resolv.conf
        echo -e "${GREEN}✓${NC} Created /etc/resolv.conf pointing to NetworkManager"
    fi

    # Step 4: Restart NetworkManager to apply changes
    echo -e "${YELLOW}Restarting NetworkManager...${NC}"
    systemctl restart NetworkManager
    echo -e "${GREEN}✓${NC} NetworkManager restarted"

    # Wait for NetworkManager to initialize
    sleep 2

elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${BLUE}Detected: macOS${NC}"
    echo ""

    # Install via Homebrew
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}Homebrew not found. Please install it first.${NC}"
        exit 1
    fi

    if ! command -v dnsmasq &> /dev/null; then
        echo -e "${YELLOW}Installing dnsmasq...${NC}"
        brew install dnsmasq
    else
        echo -e "${GREEN}✓ dnsmasq already installed${NC}"
    fi

    # Configure dnsmasq
    echo -e "${YELLOW}Configuring dnsmasq...${NC}"
    mkdir -p "$MACOS_DNSMASQ_DIR"

    cat > "$MACOS_DNSMASQ_CONF" << 'EOF'
# docker-local: Wildcard DNS for development domains
address=/.test/127.0.0.1
address=/.localhost/127.0.0.1
EOF
    echo -e "${GREEN}✓${NC} Created $MACOS_DNSMASQ_CONF"

    # Configure resolver
    echo -e "${YELLOW}Configuring system resolver...${NC}"
    mkdir -p /etc/resolver

    if [ ! -f /etc/resolver/test ]; then
        echo "nameserver 127.0.0.1" > /etc/resolver/test
        echo -e "${GREEN}✓${NC} Created /etc/resolver/test"
    fi

    if [ ! -f /etc/resolver/localhost ]; then
        echo "nameserver 127.0.0.1" > /etc/resolver/localhost
        echo -e "${GREEN}✓${NC} Created /etc/resolver/localhost"
    fi

    # Start dnsmasq service
    echo -e "${YELLOW}Starting dnsmasq service...${NC}"
    brew services start dnsmasq
    echo -e "${GREEN}✓${NC} dnsmasq service started"

else
    echo -e "${RED}Unsupported operating system: $OSTYPE${NC}"
    exit 1
fi

# ==============================================================================
# Verify configuration
# ==============================================================================
echo ""
echo -e "${CYAN}Verifying DNS resolution...${NC}"

# Give it a moment to stabilize
sleep 1

if ping -c 1 -W 2 test.test > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} test.test resolves to 127.0.0.1"
    dns_working=true
else
    echo -e "  ${YELLOW}○${NC} test.test not resolving yet (may need a moment)"
    dns_working=false
fi

if ping -c 1 -W 2 myproject.test > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} myproject.test resolves to 127.0.0.1"
else
    echo -e "  ${YELLOW}○${NC} myproject.test not resolving yet"
fi

echo ""
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              DNS Wildcard Configured!                         ║"
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

if [ "$dns_working" = false ]; then
    echo -e "${YELLOW}Note:${NC} If DNS is not resolving immediately, try:"
    echo -e "  ${CYAN}sudo systemctl restart NetworkManager${NC}"
    echo ""
fi

echo -e "${DIM}────────────────────────────────────────────────────────────────${NC}"
echo -e "${WHITE}Files created:${NC}"
echo ""
if [ -f "$NM_DNS_CONF" ]; then
    echo -e "  ${DIM}•${NC} $NM_DNS_CONF"
fi
if [ -f "$NM_DNSMASQ_CONF" ]; then
    echo -e "  ${DIM}•${NC} $NM_DNSMASQ_CONF"
fi
if [ -f "$MACOS_DNSMASQ_CONF" ]; then
    echo -e "  ${DIM}•${NC} $MACOS_DNSMASQ_CONF"
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
