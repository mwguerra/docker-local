#!/bin/bash

# ==============================================================================
# pre-install.sh - Executado ANTES da instalação do Laravel
# ==============================================================================
# Use para preparar o ambiente antes da criação do projeto.
#
# Variáveis disponíveis:
#   $1 = PROJECT_NAME (nome do projeto)
#   $2 = PROJECT_PATH (caminho completo do projeto)
# ==============================================================================

PROJECT_NAME=$1
PROJECT_PATH=$2

# Exemplo: Criar banco de dados específico para o projeto
# docker exec mysql mysql -u root -psecret -e "CREATE DATABASE IF NOT EXISTS \`$PROJECT_NAME\`;"
# docker exec postgres psql -U laravel -c "CREATE DATABASE $PROJECT_NAME;" 2>/dev/null || true

# Exemplo: Verificar se há espaço em disco suficiente
# MIN_SPACE_MB=500
# AVAILABLE_SPACE=$(df -m "$HOME/projects" | awk 'NR==2 {print $4}')
# if [ "$AVAILABLE_SPACE" -lt "$MIN_SPACE_MB" ]; then
#     echo "Error: Not enough disk space (need ${MIN_SPACE_MB}MB, have ${AVAILABLE_SPACE}MB)"
#     exit 1
# fi

exit 0
