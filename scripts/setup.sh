#!/bin/bash

# ==============================================================================
# Script de Setup - Laravel Docker Development Environment
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

# Source configuration
source "$PACKAGE_DIR/lib/config.sh"

# User config locations
CERTS_DIR="$CONFIG_DIR/certs"
PROJECTS_DIR="$(get_projects_dir)"

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     Laravel Docker Development Environment - Setup            ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ==============================================================================
# Funções Auxiliares
# ==============================================================================

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}✗ $1 não encontrado. Por favor, instale antes de continuar.${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ $1 encontrado${NC}"
    fi
}

# ==============================================================================
# Verificar dependências
# ==============================================================================

echo -e "${YELLOW}Verificando dependências...${NC}"
echo ""

check_command "docker"
check_command "docker-compose"

# Verificar se mkcert está instalado
if ! command -v mkcert &> /dev/null; then
    echo -e "${YELLOW}⚠ mkcert não encontrado. Instalando...${NC}"
    
    # Detectar sistema operacional
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y libnss3-tools
            curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
            chmod +x mkcert-v*-linux-amd64
            sudo mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert
        elif command -v pacman &> /dev/null; then
            sudo pacman -S mkcert
        elif command -v dnf &> /dev/null; then
            sudo dnf install mkcert
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install mkcert
        brew install nss # para Firefox
    fi
fi

check_command "mkcert"

echo ""

# ==============================================================================
# Instalar CA raiz do mkcert
# ==============================================================================

echo -e "${YELLOW}Instalando CA raiz do mkcert...${NC}"
mkcert -install
print_success "CA raiz instalada"

# ==============================================================================
# Criar certificados SSL
# ==============================================================================

echo ""
echo -e "${YELLOW}Gerando certificados SSL...${NC}"

mkdir -p "$CERTS_DIR"

# Certificado para *.localhost
echo -e "${BLUE}→ Gerando certificado para *.localhost${NC}"
mkcert -cert-file "$CERTS_DIR/localhost.crt" \
       -key-file "$CERTS_DIR/localhost.key" \
       "localhost" "*.localhost" "*.*.localhost"

# Certificado para *.test
echo -e "${BLUE}→ Gerando certificado para *.test${NC}"
mkcert -cert-file "$CERTS_DIR/test.crt" \
       -key-file "$CERTS_DIR/test.key" \
       "test" "*.test" "*.*.test"

print_success "Certificados gerados em $CERTS_DIR"

# ==============================================================================
# Criar arquivos de configuração se não existirem
# ==============================================================================

# Create config directory
mkdir -p "$CONFIG_DIR"

# Create config.json from stub
if [ ! -f "$CONFIG_DIR/config.json" ]; then
    echo ""
    echo -e "${YELLOW}Criando config.json...${NC}"
    if [ -f "$PACKAGE_DIR/stubs/config.json.stub" ]; then
        cp "$PACKAGE_DIR/stubs/config.json.stub" "$CONFIG_DIR/config.json"
    fi
    print_success "config.json criado em $CONFIG_DIR"
fi

# Create .env from stub
ENV_FILE="$CONFIG_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo ""
    echo -e "${YELLOW}Criando arquivo .env...${NC}"
    if [ -f "$PACKAGE_DIR/stubs/.env.stub" ]; then
        cp "$PACKAGE_DIR/stubs/.env.stub" "$ENV_FILE"
    fi
    print_success "Arquivo .env criado em $CONFIG_DIR"
fi

# ==============================================================================
# Criar diretório de projetos
# ==============================================================================

if [ ! -d "$PROJECTS_DIR" ]; then
    echo ""
    echo -e "${YELLOW}Criando diretório de projetos...${NC}"
    mkdir -p "$PROJECTS_DIR"
    
    # Criar um projeto default de exemplo
    mkdir -p "$PROJECTS_DIR/default/public"
    cat > "$PROJECTS_DIR/default/public/index.php" << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Laravel Docker Dev</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container { 
            background: white;
            padding: 3rem;
            border-radius: 1rem;
            box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25);
            text-align: center;
            max-width: 600px;
        }
        h1 { color: #1a202c; margin-bottom: 1rem; font-size: 2rem; }
        p { color: #4a5568; margin-bottom: 1.5rem; line-height: 1.6; }
        .info { 
            background: #f7fafc; 
            padding: 1rem; 
            border-radius: 0.5rem; 
            font-family: monospace;
            font-size: 0.875rem;
            text-align: left;
        }
        .info strong { color: #667eea; }
        code { 
            background: #edf2f7; 
            padding: 0.25rem 0.5rem; 
            border-radius: 0.25rem;
            font-size: 0.875rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐳 Laravel Docker Dev</h1>
        <p>Seu ambiente de desenvolvimento está funcionando!</p>
        <div class="info">
            <p><strong>Host:</strong> <?= $_SERVER['HTTP_HOST'] ?? 'N/A' ?></p>
            <p><strong>Projeto:</strong> <?= $_SERVER['HTTP_X_PROJECT'] ?? 'default' ?></p>
            <p><strong>Subdomínio:</strong> <?= $_SERVER['HTTP_X_SUBDOMAIN'] ?? 'nenhum' ?></p>
            <p><strong>PHP:</strong> <?= PHP_VERSION ?></p>
        </div>
        <p style="margin-top: 1.5rem;">
            Crie uma pasta com seu projeto em <code>projects/</code> e acesse via 
            <code>https://nome-projeto.test</code>
        </p>
    </div>
</body>
</html>
EOF
    print_success "Diretório de projetos criado em $PROJECTS_DIR"
fi

# ==============================================================================
# Configurar /etc/hosts (opcional)
# ==============================================================================

echo ""
echo -e "${YELLOW}Configuração de DNS local:${NC}"
echo ""
echo "Para usar domínios .test, você tem duas opções:"
echo ""
echo -e "${BLUE}Opção 1 - dnsmasq (recomendado):${NC}"
echo "  sudo apt install dnsmasq"
echo "  echo 'address=/.test/127.0.0.1' | sudo tee /etc/dnsmasq.d/test.conf"
echo "  sudo systemctl restart dnsmasq"
echo ""
echo -e "${BLUE}Opção 2 - Editar /etc/hosts manualmente:${NC}"
echo "  sudo nano /etc/hosts"
echo "  # Adicionar linhas como:"
echo "  127.0.0.1 meuprojeto.test"
echo "  127.0.0.1 api.meuprojeto.test"
echo "  127.0.0.1 admin.meuprojeto.test"
echo ""

# ==============================================================================
# Construir e iniciar containers
# ==============================================================================

echo -e "${YELLOW}Deseja construir e iniciar os containers agora? (s/n)${NC}"
read -r response

if [[ "$response" =~ ^([sS]|[yY])$ ]]; then
    echo ""
    echo -e "${BLUE}Construindo imagens...${NC}"
    docker_compose build

    echo ""
    echo -e "${BLUE}Iniciando containers...${NC}"
    docker_compose up -d

    echo ""
    print_success "Ambiente iniciado com sucesso!"
fi

# ==============================================================================
# Resumo Final
# ==============================================================================

echo ""
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                 Setup Completo! 🎉 (2025 Edition)             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "URLs disponíveis:"
echo "  • https://traefik.localhost   - Dashboard Traefik 3.6"
echo "  • https://mail.localhost      - Mailpit (email testing)"
echo "  • https://minio.localhost     - MinIO Console (S3)"
echo "  • https://s3.localhost        - MinIO API (S3)"
echo "  • https://meuprojeto.test     - Seu projeto Laravel"
echo ""
echo "Serviços disponíveis:"
echo "  ┌─────────────┬──────────┬──────────────────┬────────────────────────┐"
echo "  │ Serviço     │ Versão   │ Porta            │ Credenciais            │"
echo "  ├─────────────┼──────────┼──────────────────┼────────────────────────┤"
echo "  │ PHP         │ 8.4      │ (interno)        │ -                      │"
echo "  │ MySQL       │ 9.1      │ localhost:3306   │ laravel / secret       │"
echo "  │ PostgreSQL  │ 17       │ localhost:5432   │ laravel / secret       │"
echo "  │ Redis       │ 8        │ localhost:6379   │ sem senha              │"
echo "  │ MinIO       │ latest   │ localhost:9000   │ minio / minio123       │"
echo "  │ Mailpit     │ latest   │ localhost:1025   │ -                      │"
echo "  │ Traefik     │ 3.6      │ localhost:8080   │ -                      │"
echo "  └─────────────┴──────────┴──────────────────┴────────────────────────┘"
echo ""
echo "Xdebug:"
echo "  • Habilitado por padrão (porta 9003)"
echo "  • Para desabilitar: XDEBUG_ENABLED=false no .env"
echo ""
echo "Para criar um novo projeto Laravel:"
echo "  ./scripts/new-project.sh meuprojeto            # MySQL"
echo "  ./scripts/new-project.sh meuprojeto --postgres # PostgreSQL"
echo ""
echo "Para verificar status dos serviços:"
echo "  ./scripts/status.sh"
echo ""
echo "Comandos úteis:"
echo "  docker-compose up -d      # Iniciar ambiente"
echo "  docker-compose down       # Parar ambiente"
echo "  docker-compose logs -f    # Ver logs"
echo "  ./scripts/artisan.sh meuprojeto migrate  # Executar artisan"
echo ""
