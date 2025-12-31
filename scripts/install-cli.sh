#!/bin/bash

# ==============================================================================
# install-cli.sh - DEPRECATED
# ==============================================================================
# This script is deprecated. docker-local is now installed via Composer.
#
# Installation:
#   composer global require mwguerra/docker-local
#
# Make sure ~/.composer/vendor/bin is in your PATH:
#   export PATH="$HOME/.composer/vendor/bin:$PATH"
#
# Then run:
#   docker-local init
# ==============================================================================

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${YELLOW}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    DEPRECATED SCRIPT                          ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${YELLOW}This installation method is deprecated.${NC}"
echo ""
echo "docker-local is now distributed as a Composer package."
echo ""
echo -e "${BLUE}To install docker-local:${NC}"
echo ""
echo -e "  ${CYAN}composer global require mwguerra/docker-local${NC}"
echo ""
echo -e "${BLUE}Make sure Composer's bin directory is in your PATH:${NC}"
echo ""
echo -e "  ${CYAN}export PATH=\"\$HOME/.composer/vendor/bin:\$PATH\"${NC}"
echo ""
echo -e "${BLUE}Then initialize the environment:${NC}"
echo ""
echo -e "  ${CYAN}docker-local init${NC}"
echo ""
echo -e "${GREEN}After installation, you can use docker-local from anywhere!${NC}"
echo ""

exit 1
