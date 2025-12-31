#!/bin/bash

# ==============================================================================
# create-database.sh - Cria banco de dados em MySQL e/ou PostgreSQL
# Uso: ./create-database.sh <nome-banco> [--mysql|--postgres|--both]
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration
source "$PACKAGE_DIR/lib/config.sh"

# Load environment for database credentials
load_env

# Parse argumentos
DB_NAME=""
CREATE_MYSQL=false
CREATE_POSTGRES=false

for arg in "$@"; do
    case $arg in
        --mysql)
            CREATE_MYSQL=true
            ;;
        --postgres)
            CREATE_POSTGRES=true
            ;;
        --both)
            CREATE_MYSQL=true
            CREATE_POSTGRES=true
            ;;
        *)
            if [ -z "$DB_NAME" ]; then
                DB_NAME=$arg
            fi
            ;;
    esac
done

# Se nenhum DB específico foi selecionado, criar em ambos
if [ "$CREATE_MYSQL" = false ] && [ "$CREATE_POSTGRES" = false ]; then
    CREATE_MYSQL=true
    CREATE_POSTGRES=true
fi

# Validar nome do banco
if [ -z "$DB_NAME" ]; then
    echo -e "${RED}Usage: $0 <database-name> [--mysql|--postgres|--both]${NC}"
    echo ""
    echo "Examples:"
    echo "  $0 myapp              # Create in both MySQL and PostgreSQL"
    echo "  $0 myapp --mysql      # Create only in MySQL"
    echo "  $0 myapp --postgres   # Create only in PostgreSQL"
    echo "  $0 myapp --both       # Explicit both"
    exit 1
fi

# Sanitizar nome do banco (apenas alfanuméricos e underscore)
DB_NAME=$(echo "$DB_NAME" | sed 's/[^a-zA-Z0-9_]/_/g')

echo -e "${BLUE}Creating database: ${DB_NAME}${NC}"
echo ""

# Criar em MySQL
if [ "$CREATE_MYSQL" = true ]; then
    printf "MySQL:     "
    if docker ps --format '{{.Names}}' | grep -q "^mysql$"; then
        if docker exec mysql mysql -u root -psecret -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`; GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO 'laravel'@'%';" 2>/dev/null; then
            echo -e "${GREEN}✓ Created${NC}"
        else
            echo -e "${RED}✗ Failed${NC}"
        fi
    else
        echo -e "${YELLOW}○ Container not running${NC}"
    fi
fi

# Criar em PostgreSQL
if [ "$CREATE_POSTGRES" = true ]; then
    printf "PostgreSQL: "
    if docker ps --format '{{.Names}}' | grep -q "^postgres$"; then
        if docker exec postgres psql -U laravel -c "CREATE DATABASE $DB_NAME;" 2>/dev/null; then
            echo -e "${GREEN}✓ Created${NC}"
        else
            # Pode falhar se já existir, tentar verificar
            if docker exec postgres psql -U laravel -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
                echo -e "${YELLOW}○ Already exists${NC}"
            else
                echo -e "${RED}✗ Failed${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}○ Container not running${NC}"
    fi
fi

echo ""
echo -e "${GREEN}Done.${NC}"
echo ""
echo "Use in Laravel .env:"
echo ""
if [ "$CREATE_MYSQL" = true ]; then
    echo "# MySQL"
    echo "DB_CONNECTION=mysql"
    echo "DB_HOST=mysql"
    echo "DB_DATABASE=$DB_NAME"
fi
if [ "$CREATE_POSTGRES" = true ]; then
    echo ""
    echo "# PostgreSQL"
    echo "DB_CONNECTION=pgsql"
    echo "DB_HOST=postgres"
    echo "DB_DATABASE=$DB_NAME"
fi
echo ""
