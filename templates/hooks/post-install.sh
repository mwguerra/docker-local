#!/bin/bash

# ==============================================================================
# post-install.sh - Executado APÓS a instalação do Laravel e configuração do .env
# ==============================================================================
# Use para executar comandos após a criação básica do projeto.
# O .env já está configurado e o APP_KEY já foi gerado.
#
# Variáveis disponíveis:
#   $1 = PROJECT_NAME (nome do projeto)
#   $2 = PROJECT_PATH (caminho completo do projeto)
# ==============================================================================

PROJECT_NAME=$1
PROJECT_PATH=$2

# Exemplo: Executar migrations automaticamente
# docker exec -w "/var/www/$PROJECT_NAME" php php artisan migrate

# Exemplo: Criar usuário admin
# docker exec -w "/var/www/$PROJECT_NAME" php php artisan tinker --execute="
#     \App\Models\User::create([
#         'name' => 'Admin',
#         'email' => 'admin@$PROJECT_NAME.test',
#         'password' => bcrypt('password'),
#     ]);
# "

# Exemplo: Criar link de storage
# docker exec -w "/var/www/$PROJECT_NAME" php php artisan storage:link

# Exemplo: Configurar permissões
# chmod -R 775 "$PROJECT_PATH/storage"
# chmod -R 775 "$PROJECT_PATH/bootstrap/cache"

exit 0
