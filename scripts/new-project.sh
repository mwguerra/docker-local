#!/bin/bash

# ==============================================================================
# Helper para criar novos projetos Laravel
# Uso: ./new-project.sh <nome-projeto> [--postgres]
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration
source "$PACKAGE_DIR/lib/config.sh"

# Load environment variables
load_env

PROJECTS_DIR="$(get_projects_dir)"

# Parse argumentos
USE_POSTGRES=false
PROJECT_NAME=""

for arg in "$@"; do
    case $arg in
        --postgres)
            USE_POSTGRES=true
            shift
            ;;
        *)
            if [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME=$arg
            fi
            ;;
    esac
done

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}Uso: $0 <nome-projeto> [--postgres]${NC}"
    echo ""
    echo "Exemplos:"
    echo "  $0 meuprojeto              # Usa MySQL (padrão)"
    echo "  $0 meuprojeto --postgres   # Usa PostgreSQL"
    exit 1
fi

if [ -d "$PROJECTS_DIR/$PROJECT_NAME" ]; then
    echo -e "${RED}Erro: O projeto '$PROJECT_NAME' já existe!${NC}"
    exit 1
fi

echo -e "${BLUE}Criando projeto Laravel: $PROJECT_NAME${NC}"
if [ "$USE_POSTGRES" = true ]; then
    echo -e "${YELLOW}Banco de dados: PostgreSQL${NC}"
else
    echo -e "${YELLOW}Banco de dados: MySQL${NC}"
fi
echo ""

# Criar projeto via container PHP
docker exec -w /var/www php composer create-project laravel/laravel "$PROJECT_NAME"

echo ""
print_success "Projeto criado com sucesso!"
echo ""

# Configurar .env do projeto
ENV_FILE="$PROJECTS_DIR/$PROJECT_NAME/.env"

if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}Configurando .env do projeto...${NC}"
    
    # Backup do .env original
    cp "$ENV_FILE" "$ENV_FILE.backup"
    
    # Configurações gerais
    sed -i "s|APP_URL=http://localhost|APP_URL=https://$PROJECT_NAME.test|" "$ENV_FILE"
    sed -i "s|APP_TIMEZONE=UTC|APP_TIMEZONE=America/Sao_Paulo|" "$ENV_FILE"
    
    # Configurar banco de dados
    if [ "$USE_POSTGRES" = true ]; then
        sed -i "s/DB_CONNECTION=sqlite/DB_CONNECTION=pgsql/" "$ENV_FILE"
        sed -i "s/DB_CONNECTION=mysql/DB_CONNECTION=pgsql/" "$ENV_FILE"
        sed -i "s/DB_HOST=127.0.0.1/DB_HOST=postgres/" "$ENV_FILE"
        sed -i "s/DB_PORT=3306/DB_PORT=5432/" "$ENV_FILE"
    else
        sed -i "s/DB_CONNECTION=sqlite/DB_CONNECTION=mysql/" "$ENV_FILE"
        sed -i "s/DB_HOST=127.0.0.1/DB_HOST=mysql/" "$ENV_FILE"
    fi
    
    sed -i "s/DB_DATABASE=laravel/DB_DATABASE=${MYSQL_DATABASE:-laravel}/" "$ENV_FILE"
    sed -i "s/DB_USERNAME=root/DB_USERNAME=${MYSQL_USER:-laravel}/" "$ENV_FILE"
    sed -i "s/DB_PASSWORD=/DB_PASSWORD=${MYSQL_PASSWORD:-secret}/" "$ENV_FILE"
    
    # Configurar Redis
    sed -i "s/REDIS_HOST=127.0.0.1/REDIS_HOST=redis/" "$ENV_FILE"
    sed -i "s/CACHE_STORE=database/CACHE_STORE=redis/" "$ENV_FILE"
    sed -i "s/SESSION_DRIVER=database/SESSION_DRIVER=redis/" "$ENV_FILE"
    sed -i "s/QUEUE_CONNECTION=database/QUEUE_CONNECTION=redis/" "$ENV_FILE"
    
    # Configurar Mailpit
    sed -i "s/MAIL_MAILER=log/MAIL_MAILER=smtp/" "$ENV_FILE"
    sed -i "s/MAIL_HOST=127.0.0.1/MAIL_HOST=mailpit/" "$ENV_FILE"
    sed -i "s/MAIL_PORT=2525/MAIL_PORT=1025/" "$ENV_FILE"
    
    # Adicionar configurações do MinIO (S3) se não existirem
    if ! grep -q "AWS_ENDPOINT" "$ENV_FILE"; then
        cat >> "$ENV_FILE" << 'EOF'

# MinIO (S3-Compatible Storage)
AWS_ACCESS_KEY_ID=minio
AWS_SECRET_ACCESS_KEY=minio123
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=laravel
AWS_ENDPOINT=http://minio:9000
AWS_USE_PATH_STYLE_ENDPOINT=true
EOF
    fi
    
    print_success "Arquivo .env configurado"
fi

echo ""
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                  Projeto Pronto! 🎉                           ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "Acesse seu projeto em:"
echo -e "  ${BLUE}https://$PROJECT_NAME.test${NC}"
echo ""
echo "Lembre-se de adicionar ao /etc/hosts (se não estiver usando dnsmasq):"
echo -e "  ${YELLOW}127.0.0.1 $PROJECT_NAME.test${NC}"
echo ""
echo "Configurações prontas para uso:"
echo -e "  ${GREEN}✓${NC} Banco de dados: $([ "$USE_POSTGRES" = true ] && echo "PostgreSQL" || echo "MySQL")"
echo -e "  ${GREEN}✓${NC} Redis (cache, session, queue)"
echo -e "  ${GREEN}✓${NC} Mailpit (email testing)"
echo -e "  ${GREEN}✓${NC} MinIO (S3 storage)"
echo ""
echo "Para executar migrations:"
echo -e "  ${YELLOW}./scripts/artisan.sh $PROJECT_NAME migrate${NC}"
echo ""
