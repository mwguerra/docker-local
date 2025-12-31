#!/bin/bash

# ==============================================================================
# Helper para executar comandos Artisan em projetos
# Uso: ./artisan.sh <nome-projeto> <comando>
# Exemplo: ./artisan.sh meuprojeto migrate
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration for consistent environment
source "$PACKAGE_DIR/lib/config.sh"

if [ -z "$1" ]; then
    echo "Uso: $0 <nome-projeto> <comando-artisan>"
    echo "Exemplo: $0 meuprojeto migrate"
    exit 1
fi

PROJECT=$1
shift
COMMAND="$@"

if [ -z "$COMMAND" ]; then
    COMMAND="list"
fi

docker exec -it -w "/var/www/$PROJECT" php php artisan $COMMAND
