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

# ==============================================================================
# Generate unique values for project isolation
# ==============================================================================

# Count existing projects to calculate Redis DB offset
# Each project uses 3 Redis DBs (cache, session, queue)
PROJECT_COUNT=$(find "$PROJECTS_DIR" -maxdepth 1 -type d ! -name "$(basename "$PROJECTS_DIR")" 2>/dev/null | wc -l)
REDIS_DB_OFFSET=$((PROJECT_COUNT * 3))

# Ensure we don't exceed Redis DB limit (0-15)
if [ $REDIS_DB_OFFSET -gt 13 ]; then
    echo -e "${YELLOW}Aviso: Muitos projetos. Reutilizando Redis DBs (pode haver conflitos).${NC}"
    REDIS_DB_OFFSET=$((REDIS_DB_OFFSET % 14))
fi

REDIS_CACHE_DB=$REDIS_DB_OFFSET
REDIS_SESSION_DB=$((REDIS_DB_OFFSET + 1))
REDIS_QUEUE_DB=$((REDIS_DB_OFFSET + 2))

# Generate unique Reverb credentials
REVERB_APP_ID=$((RANDOM * RANDOM % 900000 + 100000))
REVERB_APP_KEY=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 20)
REVERB_APP_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32)

echo -e "${BLUE}Criando projeto Laravel: $PROJECT_NAME${NC}"
if [ "$USE_POSTGRES" = true ]; then
    echo -e "${YELLOW}Banco de dados: PostgreSQL${NC}"
else
    echo -e "${YELLOW}Banco de dados: MySQL${NC}"
fi
echo -e "${CYAN}Redis DBs: cache=$REDIS_CACHE_DB, session=$REDIS_SESSION_DB, queue=$REDIS_QUEUE_DB${NC}"
echo ""

# ==============================================================================
# Create Laravel project via PHP container
# ==============================================================================
docker exec -w /var/www php composer create-project laravel/laravel "$PROJECT_NAME"

echo ""
print_success "Projeto criado com sucesso!"
echo ""

# ==============================================================================
# Create database automatically
# ==============================================================================
echo -e "${YELLOW}Criando banco de dados: $PROJECT_NAME${NC}"

# Sanitize database name (only alphanumeric and underscore)
DB_NAME=$(echo "$PROJECT_NAME" | tr '-' '_' | tr -cd '[:alnum:]_')

if [ "$USE_POSTGRES" = true ]; then
    # Create PostgreSQL database
    docker exec postgres psql -U "${POSTGRES_USER:-laravel}" -d postgres -c "CREATE DATABASE \"$DB_NAME\";" 2>/dev/null || true
    docker exec postgres psql -U "${POSTGRES_USER:-laravel}" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";" 2>/dev/null || true
    docker exec postgres psql -U "${POSTGRES_USER:-laravel}" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS \"pgcrypto\";" 2>/dev/null || true
    docker exec postgres psql -U "${POSTGRES_USER:-laravel}" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS \"vector\";" 2>/dev/null || true

    # Create testing database
    docker exec postgres psql -U "${POSTGRES_USER:-laravel}" -d postgres -c "CREATE DATABASE \"${DB_NAME}_testing\";" 2>/dev/null || true
    print_success "Banco PostgreSQL '$DB_NAME' criado"
else
    # Create MySQL database
    docker exec mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD:-secret}" -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;" 2>/dev/null || true
    docker exec mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD:-secret}" -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '${MYSQL_USER:-laravel}'@'%';" 2>/dev/null || true

    # Create testing database
    docker exec mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD:-secret}" -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}_testing\`;" 2>/dev/null || true
    docker exec mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD:-secret}" -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}_testing\`.* TO '${MYSQL_USER:-laravel}'@'%';" 2>/dev/null || true
    print_success "Banco MySQL '$DB_NAME' criado"
fi

# ==============================================================================
# Create MinIO bucket for the project
# ==============================================================================
echo -e "${YELLOW}Criando bucket MinIO: $PROJECT_NAME${NC}"
docker exec minio-setup mc mb myminio/"$PROJECT_NAME" --ignore-existing 2>/dev/null || \
    docker exec minio mc mb local/"$PROJECT_NAME" --ignore-existing 2>/dev/null || true
print_success "Bucket MinIO '$PROJECT_NAME' criado"

# ==============================================================================
# Generate .env from stub template
# ==============================================================================
ENV_FILE="$PROJECTS_DIR/$PROJECT_NAME/.env"
STUB_FILE="$PACKAGE_DIR/stubs/laravel.env.stub"

if [ -f "$STUB_FILE" ]; then
    echo -e "${YELLOW}Gerando .env do projeto a partir do template...${NC}"

    # Backup original .env
    if [ -f "$ENV_FILE" ]; then
        cp "$ENV_FILE" "$ENV_FILE.original"
    fi

    # Copy stub and replace all placeholders
    cp "$STUB_FILE" "$ENV_FILE"

    # Replace all placeholders
    sed -i "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" "$ENV_FILE"
    sed -i "s|{{REDIS_CACHE_DB}}|$REDIS_CACHE_DB|g" "$ENV_FILE"
    sed -i "s|{{REDIS_SESSION_DB}}|$REDIS_SESSION_DB|g" "$ENV_FILE"
    sed -i "s|{{REDIS_QUEUE_DB}}|$REDIS_QUEUE_DB|g" "$ENV_FILE"
    sed -i "s|{{REVERB_APP_ID}}|$REVERB_APP_ID|g" "$ENV_FILE"
    sed -i "s|{{REVERB_APP_KEY}}|$REVERB_APP_KEY|g" "$ENV_FILE"
    sed -i "s|{{REVERB_APP_SECRET}}|$REVERB_APP_SECRET|g" "$ENV_FILE"

    # Adjust for PostgreSQL if selected
    if [ "$USE_POSTGRES" = true ]; then
        sed -i "s|DB_CONNECTION=mysql|DB_CONNECTION=pgsql|g" "$ENV_FILE"
        sed -i "s|DB_HOST=mysql|DB_HOST=postgres|g" "$ENV_FILE"
        sed -i "s|DB_PORT=3306|DB_PORT=5432|g" "$ENV_FILE"
    fi

    # Generate APP_KEY
    docker exec -w /var/www/"$PROJECT_NAME" php php artisan key:generate --force 2>/dev/null || true

    print_success "Arquivo .env configurado com isolamento completo"
else
    # Fallback: configure existing .env if stub not found
    echo -e "${YELLOW}Configurando .env existente...${NC}"

    if [ -f "$ENV_FILE" ]; then
        cp "$ENV_FILE" "$ENV_FILE.backup"

        # Basic configuration
        sed -i "s|APP_URL=http://localhost|APP_URL=https://$PROJECT_NAME.test|" "$ENV_FILE"
        sed -i "s|APP_TIMEZONE=UTC|APP_TIMEZONE=America/Sao_Paulo|" "$ENV_FILE"

        # Database
        if [ "$USE_POSTGRES" = true ]; then
            sed -i "s/DB_CONNECTION=sqlite/DB_CONNECTION=pgsql/" "$ENV_FILE"
            sed -i "s/DB_CONNECTION=mysql/DB_CONNECTION=pgsql/" "$ENV_FILE"
            sed -i "s/DB_HOST=127.0.0.1/DB_HOST=postgres/" "$ENV_FILE"
            sed -i "s/DB_PORT=3306/DB_PORT=5432/" "$ENV_FILE"
        else
            sed -i "s/DB_CONNECTION=sqlite/DB_CONNECTION=mysql/" "$ENV_FILE"
            sed -i "s/DB_HOST=127.0.0.1/DB_HOST=mysql/" "$ENV_FILE"
        fi

        sed -i "s/DB_DATABASE=laravel/DB_DATABASE=$DB_NAME/" "$ENV_FILE"
        sed -i "s/DB_USERNAME=root/DB_USERNAME=${MYSQL_USER:-laravel}/" "$ENV_FILE"
        sed -i "s/DB_PASSWORD=/DB_PASSWORD=${MYSQL_PASSWORD:-secret}/" "$ENV_FILE"

        # Redis
        sed -i "s/REDIS_HOST=127.0.0.1/REDIS_HOST=redis/" "$ENV_FILE"
        sed -i "s/CACHE_STORE=database/CACHE_STORE=redis/" "$ENV_FILE"
        sed -i "s/SESSION_DRIVER=database/SESSION_DRIVER=redis/" "$ENV_FILE"
        sed -i "s/QUEUE_CONNECTION=database/QUEUE_CONNECTION=redis/" "$ENV_FILE"

        # Add isolation config if not present
        if ! grep -q "CACHE_PREFIX" "$ENV_FILE"; then
            echo "" >> "$ENV_FILE"
            echo "# Project Isolation" >> "$ENV_FILE"
            echo "CACHE_PREFIX=${PROJECT_NAME}_" >> "$ENV_FILE"
            echo "REDIS_CACHE_DB=$REDIS_CACHE_DB" >> "$ENV_FILE"
            echo "REDIS_SESSION_DB=$REDIS_SESSION_DB" >> "$ENV_FILE"
            echo "REDIS_QUEUE_DB=$REDIS_QUEUE_DB" >> "$ENV_FILE"
        fi

        # Mailpit
        sed -i "s/MAIL_MAILER=log/MAIL_MAILER=smtp/" "$ENV_FILE"
        sed -i "s/MAIL_HOST=127.0.0.1/MAIL_HOST=mailpit/" "$ENV_FILE"
        sed -i "s/MAIL_PORT=2525/MAIL_PORT=1025/" "$ENV_FILE"

        # MinIO
        if ! grep -q "AWS_ENDPOINT" "$ENV_FILE"; then
            cat >> "$ENV_FILE" << EOF

# MinIO (S3-Compatible Storage)
AWS_ACCESS_KEY_ID=minio
AWS_SECRET_ACCESS_KEY=minio123
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=$PROJECT_NAME
AWS_ENDPOINT=http://minio:9000
AWS_USE_PATH_STYLE_ENDPOINT=true
EOF
        fi

        print_success "Arquivo .env configurado"
    fi
fi

# ==============================================================================
# Summary
# ==============================================================================
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
echo "Configurações de isolamento (multi-projeto):"
echo -e "  ${GREEN}✓${NC} Banco de dados: $DB_NAME ($([ "$USE_POSTGRES" = true ] && echo "PostgreSQL" || echo "MySQL"))"
echo -e "  ${GREEN}✓${NC} Redis Cache DB: $REDIS_CACHE_DB"
echo -e "  ${GREEN}✓${NC} Redis Session DB: $REDIS_SESSION_DB"
echo -e "  ${GREEN}✓${NC} Redis Queue DB: $REDIS_QUEUE_DB"
echo -e "  ${GREEN}✓${NC} Cache Prefix: ${PROJECT_NAME}_"
echo -e "  ${GREEN}✓${NC} MinIO Bucket: $PROJECT_NAME"
echo -e "  ${GREEN}✓${NC} Reverb App ID: $REVERB_APP_ID"
echo ""
echo "Serviços prontos para uso:"
echo -e "  ${GREEN}✓${NC} Mailpit (email testing)"
echo -e "  ${GREEN}✓${NC} Xdebug (debugging)"
echo ""

# Check if DNS is configured for .test domains
if ! ping -c 1 -W 1 test.test > /dev/null 2>&1; then
    echo -e "${YELLOW}DNS for .test domains not configured. Run:${NC}"
    echo -e "  ${CYAN}sudo \"\$(which docker-local)\" setup:dns${NC}"
    echo ""
    echo -e "${DIM}Or add manually to /etc/hosts:${NC}"
    echo -e "  ${DIM}127.0.0.1 $PROJECT_NAME.test${NC}"
    echo ""
fi

echo "Para executar migrations:"
echo -e "  ${YELLOW}docker exec -w /var/www/$PROJECT_NAME php php artisan migrate${NC}"
echo ""
