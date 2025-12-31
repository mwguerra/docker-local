#!/bin/bash

# ==============================================================================
# Helper para executar comandos Composer em projetos
# Uso: ./composer.sh <nome-projeto> <comando>
# Exemplo: ./composer.sh meuprojeto require laravel/sanctum
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration for consistent environment
source "$PACKAGE_DIR/lib/config.sh"

if [ -z "$1" ]; then
    echo "Uso: $0 <nome-projeto> <comando-composer>"
    echo "Exemplo: $0 meuprojeto require laravel/sanctum"
    exit 1
fi

PROJECT=$1
shift
COMMAND="$@"

if [ -z "$COMMAND" ]; then
    COMMAND="list"
fi

docker exec -it -w "/var/www/$PROJECT" php composer $COMMAND
