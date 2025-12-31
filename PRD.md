# PRD: Laravel Docker Development Environment

> **Versão:** 2.0.0  
> **Última atualização:** 2025-12-30  
> **Status:** Em desenvolvimento

---

## 📋 Sumário

1. [Visão Geral](#1-visão-geral)
2. [Objetivos](#2-objetivos)
3. [Estrutura de Diretórios](#3-estrutura-de-diretórios)
4. [Stack Tecnológica](#4-stack-tecnológica)
5. [Arquitetura](#5-arquitetura)
6. [Serviços e Configurações](#6-serviços-e-configurações)
7. [Interface de Comandos](#7-interface-de-comandos)
8. [Configuração de Projetos Laravel](#8-configuração-de-projetos-laravel)
9. [SSL e Domínios](#9-ssl-e-domínios)
10. [DNS e Subdomínios](#10-dns-e-subdomínios)
11. [Xdebug](#11-xdebug)
12. [Extensões PHP](#12-extensões-php)
13. [URLs e Portas](#13-urls-e-portas)
14. [Requisitos do Sistema](#14-requisitos-do-sistema)
15. [Instalação](#15-instalação)
16. [Roadmap](#16-roadmap)
17. [Decisões Técnicas](#17-decisões-técnicas)

---

## 1. Visão Geral

### 1.1 Descrição

O **Laravel Docker Development Environment** é uma solução completa e pronta para uso que fornece um ambiente de desenvolvimento local para projetos Laravel utilizando Docker. A solução substitui ferramentas como Laravel Valet (especialmente em Linux) oferecendo suporte completo a SSL, domínios personalizados e subdomínios wildcard.

### 1.2 Problema

- Laravel Valet não tem suporte oficial para Linux
- Variantes não-oficiais do Valet para Linux são instáveis
- Configuração manual de Docker para Laravel é complexa e demorada
- Falta de suporte a subdomínios wildcard em soluções existentes
- Dificuldade em manter múltiplos projetos com diferentes requisitos

### 1.3 Solução

Uma stack Docker pré-configurada com:
- Todos os serviços necessários para Laravel prontos "de fábrica"
- SSL automático com certificados locais confiáveis
- Suporte a domínios `.test` e `.localhost` com wildcards
- Interface de comandos via Composer para facilitar o uso
- Configuração centralizada com valores padrão sensatos

---

## 2. Objetivos

### 2.1 Objetivos Primários

- [ ] Fornecer ambiente de desenvolvimento Laravel completo com um único comando
- [ ] Suportar SSL/HTTPS com certificados confiáveis pelo sistema
- [ ] Permitir múltiplos projetos simultâneos com domínios personalizados
- [ ] Suportar subdomínios wildcard (ex: `api.meuprojeto.test`, `admin.meuprojeto.test`)
- [ ] Incluir todos os serviços comuns: MySQL, PostgreSQL, Redis, MinIO (S3), Mailpit
- [ ] Fornecer Xdebug configurado e pronto para uso

### 2.2 Objetivos Secundários

- [ ] Manter compatibilidade com as versões mais recentes de cada componente
- [ ] Oferecer comandos simples via Composer para gerenciamento
- [ ] Gerar configurações `.env` para projetos Laravel automaticamente
- [ ] Documentação clara e completa
- [ ] Fácil atualização e manutenção

### 2.3 Não-Objetivos

- Não é um ambiente de produção
- Não substitui CI/CD pipelines
- Não gerencia deploy ou orquestração de containers em produção
- Não inclui serviços específicos de cloud (AWS, GCP, Azure)

---

## 3. Estrutura de Diretórios

### 3.1 Visão Geral

```
~/
├── docker-environment/          # Ambiente Docker (este projeto)
│   ├── composer.json            # Scripts de gerenciamento
│   ├── docker-compose.yml       # Definição dos serviços
│   ├── .env                     # Configurações do ambiente
│   ├── .env.example             # Template de configurações
│   ├── certs/                   # Certificados SSL gerados
│   ├── mysql/                   # Configurações MySQL
│   ├── postgres/                # Configurações PostgreSQL
│   ├── redis/                   # Configurações Redis
│   ├── php/                     # Dockerfile e configs PHP
│   ├── nginx/                   # Configurações Nginx
│   ├── traefik/                 # Configurações Traefik
│   └── scripts/                 # Scripts auxiliares
│
└── projects/                    # Projetos Laravel
    ├── projeto-a/               # https://projeto-a.test
    ├── projeto-b/               # https://projeto-b.test
    └── api/                     # https://api.test
```

### 3.2 Detalhamento ~/docker-environment/

```
docker-environment/
├── composer.json                 # Scripts Composer para gerenciamento
├── docker-compose.yml            # Definição principal dos serviços
├── .env                          # Variáveis de ambiente (não versionado)
├── .env.example                  # Template de variáveis
├── .gitignore                    # Arquivos ignorados
├── README.md                     # Documentação principal
├── PRD.md                        # Este documento
│
├── bin/                          # Executáveis
│   └── docker-local              # CLI principal (symlink para /usr/local/bin)
│
├── certs/                        # Certificados SSL
│   ├── localhost.crt             # Certificado *.localhost
│   ├── localhost.key             # Chave *.localhost
│   ├── test.crt                  # Certificado *.test
│   └── test.key                  # Chave *.test
│
├── mysql/
│   ├── my.cnf                    # Configurações customizadas MySQL
│   └── init/                     # Scripts de inicialização
│       └── 01-create-databases.sql
│
├── postgres/
│   └── init/                     # Scripts de inicialização
│       └── 01-create-databases.sql
│
├── redis/
│   └── redis.conf                # Configurações Redis
│
├── php/
│   ├── Dockerfile                # Build do container PHP
│   ├── php.ini                   # Configurações PHP
│   └── xdebug.ini                # Configurações Xdebug
│
├── nginx/
│   └── default.conf              # Configuração multi-projeto
│
├── traefik/
│   └── dynamic/
│       └── tls.yml               # Configuração de certificados
│
├── templates/                    # Templates para novos projetos
│   ├── install.sh                # Script de instalação customizado
│   ├── hooks/
│   │   ├── pre-install.sh        # Hook pré-instalação
│   │   └── post-install.sh       # Hook pós-instalação
│   └── files/                    # Arquivos para copiar (opcional)
│
└── scripts/
    ├── setup.sh                  # Setup inicial completo
    ├── setup-dns.sh              # Configuração DNS wildcard
    ├── install-cli.sh            # Instalação do CLI docker-local
    ├── status.sh                 # Verifica status dos serviços
    ├── make-env.sh               # Gera configurações .env Laravel
    ├── new-project.sh            # Cria novo projeto Laravel
    ├── artisan.sh                # Executa comandos artisan
    ├── composer.sh               # Executa comandos composer
    ├── create-database.sh        # Cria bancos de dados
    ├── generate-certs.sh         # Regenera certificados SSL
    ├── test-connections.sh       # Testa conexões
    └── add-host.sh               # Adiciona hosts ao /etc/hosts
```

### 3.3 Mapeamento de Volumes

| Container | Volume Local | Volume Container |
|-----------|--------------|------------------|
| php | `~/projects` | `/var/www` |
| nginx | `~/projects` | `/var/www` |
| mysql | Docker volume | `/var/lib/mysql` |
| postgres | Docker volume | `/var/lib/postgresql/data` |
| redis | Docker volume | `/data` |
| minio | Docker volume | `/data` |

---

## 4. Stack Tecnológica

### 4.1 Versões dos Componentes

| Componente | Versão | Notas |
|------------|--------|-------|
| **PHP** | 8.4 | Com Xdebug, OPcache, JIT |
| **MySQL** | 9.1 | Innovation track (ou 8.4 LTS) |
| **PostgreSQL** | 17 | Versão estável mais recente |
| **Redis** | 8 | Com I/O threading |
| **Traefik** | 3.6 | Reverse proxy com SSL |
| **Nginx** | Alpine (latest) | Servidor web |
| **MinIO** | Latest | S3-compatible storage |
| **Mailpit** | Latest | Email testing |
| **Node.js** | LTS (via Alpine) | Para Vite/Mix |
| **Composer** | Latest | Gerenciador de dependências |

### 4.2 Justificativa das Versões

- **PHP 8.4**: Versão estável mais recente com property hooks, asymmetric visibility
- **MySQL 9.1**: Innovation track com features mais recentes (alternativa: 8.4 LTS para estabilidade)
- **PostgreSQL 17**: Melhorias de I/O e performance significativas
- **Redis 8**: Novo modelo de licenciamento, I/O threading melhorado
- **Traefik 3.6**: Suporte a Gateway API 1.4, Knative, melhor dashboard

---

## 5. Arquitetura

### 5.1 Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              BROWSER                                      │
│                    https://meuprojeto.test                               │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         TRAEFIK (Reverse Proxy)                          │
│                              Port 80, 443                                │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  • SSL Termination (mkcert certificates)                         │    │
│  │  • Routing: *.test, *.localhost, *.*.test                       │    │
│  │  • Dashboard: https://traefik.localhost                          │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                              NGINX                                        │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  • Multi-project routing based on hostname                       │    │
│  │  • meuprojeto.test → /var/www/meuprojeto/public                 │    │
│  │  • Passes subdomain info via X-Subdomain header                 │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                            PHP-FPM 8.4                                   │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  • Laravel Application                                           │    │
│  │  • Xdebug (porta 9003)                                          │    │
│  │  • OPcache + JIT                                                 │    │
│  │  • Extensões: redis, pdo_mysql, pdo_pgsql, imagick, swoole...   │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
          │              │              │              │
          ▼              ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   MySQL 9.1  │ │ PostgreSQL 17│ │   Redis 8    │ │    MinIO     │
│   Port 3306  │ │   Port 5432  │ │   Port 6379  │ │  Port 9000   │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
                                          │
                                          ▼
                               ┌──────────────────┐
                               │     Mailpit      │
                               │   SMTP: 1025     │
                               │   Web: 8025      │
                               └──────────────────┘
```

### 5.2 Fluxo de Requisição

1. Browser faz requisição para `https://meuprojeto.test`
2. DNS local (dnsmasq) resolve `*.test` para `127.0.0.1`
3. Traefik recebe a requisição na porta 443
4. Traefik termina SSL e roteia para Nginx
5. Nginx identifica o projeto pelo hostname (`meuprojeto`)
6. Nginx define root como `/var/www/meuprojeto/public`
7. Nginx passa requisição PHP para PHP-FPM
8. Laravel processa a requisição
9. Resposta retorna pelo mesmo caminho

### 5.3 Rede Docker

```yaml
networks:
  laravel-dev:
    name: laravel-dev
    driver: bridge
```

Todos os containers estão na mesma rede `laravel-dev`, permitindo comunicação por nome do container.

---

## 6. Serviços e Configurações

### 6.1 MySQL 9.1

**Container:** `mysql`

**Configurações padrão (.env):**
```env
MYSQL_VERSION=9.1
MYSQL_PORT=3306
MYSQL_ROOT_PASSWORD=secret
MYSQL_DATABASE=laravel
MYSQL_USER=laravel
MYSQL_PASSWORD=secret
```

**Configurações customizadas (my.cnf):**
- Character set: `utf8mb4`
- Collation: `utf8mb4_unicode_ci`
- InnoDB buffer pool: 256MB
- Max connections: 200
- Slow query log habilitado

**Banco de dados criados automaticamente:**
- `laravel` (padrão)
- `laravel_testing` (para testes)

---

### 6.2 PostgreSQL 17

**Container:** `postgres`

**Configurações padrão (.env):**
```env
POSTGRES_PORT=5432
POSTGRES_DATABASE=laravel
POSTGRES_USER=laravel
POSTGRES_PASSWORD=secret
```

**Extensões instaladas:**
- `uuid-ossp`
- `pgcrypto`

**Banco de dados criados automaticamente:**
- `laravel` (padrão)
- `laravel_testing` (para testes)

---

### 6.3 Redis 8

**Container:** `redis`

**Configurações padrão (.env):**
```env
REDIS_PORT=6379
```

**Configurações customizadas (redis.conf):**
- Max memory: 256MB
- Eviction policy: `allkeys-lru`
- I/O threads: 4
- Append only: yes
- Active defragmentation: yes

---

### 6.4 MinIO (S3)

**Container:** `minio`

**Configurações padrão (.env):**
```env
MINIO_API_PORT=9000
MINIO_CONSOLE_PORT=9001
MINIO_ROOT_USER=minio
MINIO_ROOT_PASSWORD=minio123
MINIO_BUCKET=laravel
```

**Setup automático:**
- Bucket `laravel` criado automaticamente
- Pasta `public/` com acesso anônimo habilitado

---

### 6.5 Mailpit

**Container:** `mailpit`

**Configurações padrão (.env):**
```env
MAILPIT_SMTP_PORT=1025
MAILPIT_WEB_PORT=8025
```

**Features:**
- Web UI para visualizar emails
- API para testes automatizados
- Suporta anexos e HTML

---

### 6.6 Traefik 3.6

**Container:** `traefik`

**Portas:**
- 80: HTTP (redireciona para HTTPS)
- 443: HTTPS
- 8080: Dashboard

**Rotas configuradas:**
- `*.localhost` → nginx
- `*.test` → nginx
- `*.*.test` → nginx (subdomínios)
- `traefik.localhost` → dashboard
- `mail.localhost` → mailpit
- `minio.localhost` → minio console
- `s3.localhost` → minio api

---

## 7. Interface de Comandos

O ambiente utiliza o CLI `docker-local` que pode ser executado de qualquer diretório.

---

### 7.1 CLI docker-local

O `docker-local` é um CLI completo com 50+ comandos para gerenciar o ambiente e projetos.

#### Instalação do CLI

```bash
cd ~/docker-environment
./scripts/install-cli.sh

# Adicionar autocompletion (opcional)
eval "$(docker-local completion bash)"  # ~/.bashrc
eval "$(docker-local completion zsh)"   # ~/.zshrc
```

#### Comandos Disponíveis

##### Setup e Diagnóstico

| Comando | Descrição |
|---------|-----------|
| `docker-local init` | Setup completo inicial (recomendado para primeira execução) |
| `docker-local doctor` | Diagnóstico completo de saúde do sistema |
| `docker-local setup:hosts` | Adiciona hostnames ao /etc/hosts *(requer sudo)* |
| `docker-local setup:dns` | Configura dnsmasq para *.test *(requer sudo)* |
| `docker-local config` | Mostra configuração atual |
| `docker-local update` | Atualiza imagens Docker e CLI |

##### Gerenciamento do Ambiente

| Comando | Descrição |
|---------|-----------|
| `docker-local up` | Inicia containers |
| `docker-local down` | Para containers |
| `docker-local restart` | Reinicia containers |
| `docker-local status` | Status dos serviços |
| `docker-local logs [service]` | Logs Docker |
| `docker-local ports` | Portas expostas |
| `docker-local clean [--laravel\|--docker\|--logs]` | Limpa caches |

##### Projetos

| Comando | Descrição |
|---------|-----------|
| `docker-local list` | Lista todos os projetos Laravel |
| `docker-local make:laravel <nome>` | Cria novo projeto |
| `docker-local clone <repo> [nome]` | Clona e configura repositório |
| `docker-local open [nome\|--mail\|--minio]` | Abre no navegador |
| `docker-local ide [code\|phpstorm]` | Abre no editor |
| `docker-local env:check` | Verifica .env (serviços, prefixos, conflitos) |
| `docker-local env:check --all` | Audita TODOS os projetos |
| `docker-local env:audit` | Alias para env:check --all |
| `docker-local make:env` | Gera .env com IDs únicos |
| `docker-local update:env` | Atualiza .env preservando chaves |

##### Desenvolvimento

| Comando | Descrição |
|---------|-----------|
| `docker-local tinker` | Laravel Tinker |
| `docker-local test [--coverage\|--parallel]` | Executa testes |
| `docker-local require <package>` | Instala pacote (com sugestões) |
| `docker-local logs:laravel` | Tail storage/logs/laravel.log |

##### Artisan Shortcuts

| Comando | Descrição |
|---------|-----------|
| `docker-local new:model <nome> [-mcr]` | make:model |
| `docker-local new:controller <nome>` | make:controller |
| `docker-local new:migration <nome>` | make:migration |
| `docker-local new:seeder <nome>` | make:seeder |
| `docker-local new:factory <nome>` | make:factory |
| `docker-local new:request <nome>` | make:request |
| `docker-local new:resource <nome>` | make:resource |
| `docker-local new:middleware <nome>` | make:middleware |
| `docker-local new:event <nome>` | make:event |
| `docker-local new:job <nome>` | make:job |
| `docker-local new:mail <nome>` | make:mail |
| `docker-local new:command <nome>` | make:command |

##### Banco de Dados

| Comando | Descrição |
|---------|-----------|
| `docker-local db:mysql` | Cliente MySQL |
| `docker-local db:postgres` | Cliente PostgreSQL |
| `docker-local db:redis` | Cliente Redis |
| `docker-local db:create <nome>` | Cria database |
| `docker-local db:dump` | Exporta para SQL |
| `docker-local db:restore <file>` | Importa SQL |
| `docker-local db:fresh` | migrate:fresh --seed |

##### Queue

| Comando | Descrição |
|---------|-----------|
| `docker-local queue:work` | Inicia worker |
| `docker-local queue:restart` | Reinicia workers |
| `docker-local queue:failed` | Lista jobs falhos |
| `docker-local queue:retry [id\|all]` | Reprocessa falhos |
| `docker-local queue:clear` | Limpa fila |

##### Xdebug

| Comando | Descrição |
|---------|-----------|
| `docker-local xdebug on` | Habilita (debug) |
| `docker-local xdebug off` | Desabilita (performance) |
| `docker-local xdebug status` | Status atual |

##### Outros

| Comando | Descrição |
|---------|-----------|
| `docker-local shell` | Shell PHP container |
| `docker-local completion [bash\|zsh]` | Gera autocompletion |
| `docker-local self-update` | Atualiza CLI |
| `docker-local help` | Ajuda |

#### Exemplos de Uso

```bash
# Setup inicial
docker-local init
sudo docker-local setup:hosts
sudo docker-local setup:dns

# Criar projeto
docker-local make:laravel blog
cd ~/projects/blog
php artisan migrate
docker-local open

# Clonar projeto existente
docker-local clone git@github.com:user/api.git
cd ~/projects/api
docker-local env:check

# Desenvolvimento
docker-local new:model Post -mcr
docker-local require sanctum
docker-local test --coverage

# Database
docker-local db:dump
docker-local db:fresh

# Debug
docker-local xdebug on
docker-local logs:laravel

# Diagnóstico
docker-local doctor
docker-local clean --all
```

#### Configuração

```bash
# Em ~/.bashrc ou ~/.zshrc
export DOCKER_ENV_DIR="$HOME/docker-environment"
export PROJECTS_DIR="$HOME/projects"
```

---

### 7.2 Atalhos de Pacotes

O comando `require` mapeia nomes curtos para pacotes completos:

| Atalho | Pacote |
|--------|--------|
| `sanctum` | laravel/sanctum |
| `telescope` | laravel/telescope --dev |
| `horizon` | laravel/horizon |
| `breeze` | laravel/breeze --dev |
| `jetstream` | laravel/jetstream |
| `debugbar` | barryvdh/laravel-debugbar --dev |
| `ide-helper` | barryvdh/laravel-ide-helper --dev |
| `pint` | laravel/pint --dev |
| `pest` | pestphp/pest --dev |
| `livewire` | livewire/livewire |
| `filament` | filament/filament |
| `spatie-permission` | spatie/laravel-permission |
| `spatie-media` | spatie/laravel-medialibrary |
| `spatie-backup` | spatie/laravel-backup |
| `spatie-activity` | spatie/laravel-activitylog |

Exemplo:
```bash
docker-local require sanctum
# Executa: composer require laravel/sanctum
# Sugere: php artisan vendor:publish --provider="..."
```

---

### 7.3 composer.json

```json
{
    "name": "laravel/docker-environment",
    "description": "Laravel Docker Development Environment",
    "type": "project",
    "license": "MIT",
    "scripts": {
        "docker:setup": "bash scripts/setup.sh",
        "docker:dns": "sudo bash scripts/setup-dns.sh",
        "docker:up": "docker-compose up -d",
        "docker:down": "docker-compose down",
        "docker:restart": "docker-compose restart",
        "docker:stop": "docker-compose stop",
        "docker:status": "bash scripts/status.sh",
        "docker:logs": "docker-compose logs -f",
        "docker:logs:php": "docker-compose logs -f php",
        "docker:logs:nginx": "docker-compose logs -f nginx",
        "docker:logs:mysql": "docker-compose logs -f mysql",
        "docker:ports": "docker-compose ps --format 'table {{.Name}}\t{{.Ports}}'",
        "docker:build": "docker-compose build --no-cache",
        "docker:pull": "docker-compose pull",
        "docker:prune": "docker system prune -af --volumes",
        
        "make:env": "bash scripts/make-env.sh",
        "make:project": "bash scripts/new-project.sh",
        
        "artisan": "bash scripts/artisan.sh",
        "composer:project": "bash scripts/composer.sh",
        
        "php:shell": "docker exec -it php sh",
        "mysql:shell": "docker exec -it mysql mysql -u laravel -psecret",
        "postgres:shell": "docker exec -it postgres psql -U laravel",
        "redis:shell": "docker exec -it redis redis-cli",
        
        "cert:generate": "bash scripts/generate-certs.sh",
        "host:add": "sudo bash scripts/add-host.sh"
    },
    "scripts-descriptions": {
        "docker:setup": "Executa setup inicial completo (certificados, DNS, build)",
        "docker:dns": "Configura dnsmasq para resolução wildcard *.test",
        "docker:up": "Inicia todos os containers",
        "docker:down": "Para e remove todos os containers",
        "docker:restart": "Reinicia todos os containers",
        "docker:stop": "Para todos os containers (sem remover)",
        "docker:status": "Mostra status detalhado de todos os serviços",
        "docker:logs": "Mostra logs de todos os containers em tempo real",
        "docker:ports": "Lista portas expostas de cada container",
        "docker:build": "Reconstrói imagens Docker do zero",
        "docker:pull": "Atualiza imagens base",
        "docker:prune": "Remove containers, imagens e volumes não utilizados",
        
        "make:env": "Gera configurações .env para projetos Laravel",
        "make:project": "Cria novo projeto Laravel com configuração automática",
        
        "artisan": "Executa comando artisan em um projeto",
        "composer:project": "Executa comando composer em um projeto",
        
        "php:shell": "Abre shell no container PHP",
        "mysql:shell": "Abre cliente MySQL",
        "postgres:shell": "Abre cliente PostgreSQL",
        "redis:shell": "Abre cliente Redis",
        
        "cert:generate": "Regenera certificados SSL",
        "host:add": "Adiciona entrada ao /etc/hosts"
    }
}
```

### 7.2 Comandos Detalhados

#### docker:setup
Executa configuração inicial completa:
1. Verifica dependências (Docker, docker-compose, mkcert)
2. Instala mkcert CA no sistema
3. Gera certificados SSL para *.test e *.localhost
4. Copia .env.example para .env
5. Cria diretório de projetos
6. Builda imagens Docker
7. Inicia containers
8. Exibe resumo de configuração

#### docker:status
Exibe status detalhado:
- Estado de cada container (running/stopped)
- Versões de cada serviço
- Conexões de banco de dados
- Extensões PHP instaladas
- URLs de acesso
- Portas e credenciais

#### docker:ports
Lista portas em formato tabular:
```
NAME        PORTS
traefik     0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 0.0.0.0:8080->8080/tcp
mysql       0.0.0.0:3306->3306/tcp
postgres    0.0.0.0:5432->5432/tcp
redis       0.0.0.0:6379->6379/tcp
minio       0.0.0.0:9000->9000/tcp, 0.0.0.0:9001->9001/tcp
mailpit     0.0.0.0:1025->1025/tcp, 0.0.0.0:8025->8025/tcp
```

#### make:env
Gera e exibe no terminal configurações .env para Laravel:

```bash
$ composer make:env

╔═══════════════════════════════════════════════════════════════╗
║           Laravel .env Configuration Generator                 ║
╚═══════════════════════════════════════════════════════════════╝

Copy the following to your Laravel .env file:

# ============================================================
# Database - MySQL 9.1
# ============================================================
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret

# ============================================================
# Database - PostgreSQL 17 (alternative)
# ============================================================
# DB_CONNECTION=pgsql
# DB_HOST=postgres
# DB_PORT=5432
# DB_DATABASE=laravel
# DB_USERNAME=laravel
# DB_PASSWORD=secret

# ============================================================
# Redis 8
# ============================================================
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

CACHE_STORE=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

# ============================================================
# MinIO (S3 Storage)
# ============================================================
FILESYSTEM_DISK=s3
AWS_ACCESS_KEY_ID=minio
AWS_SECRET_ACCESS_KEY=minio123
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=laravel
AWS_ENDPOINT=http://minio:9000
AWS_USE_PATH_STYLE_ENDPOINT=true

# ============================================================
# Mailpit
# ============================================================
MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null

# ============================================================
# Current Ports (from running containers)
# ============================================================
# MySQL:      localhost:3306
# PostgreSQL: localhost:5432  
# Redis:      localhost:6379
# MinIO API:  localhost:9000
# MinIO Web:  localhost:9001
# Mailpit:    localhost:1025 (SMTP), localhost:8025 (Web)
```

#### env:check

Verifica se o arquivo `.env` do projeto Laravel está corretamente configurado, incluindo verificação de conflitos com outros projetos:

```bash
cd ~/projects/meuprojeto
docker-local env:check
```

**O que é verificado:**

1. **Hostnames no /etc/hosts** - mysql, postgres, redis, minio, mailpit
2. **Database** - Container rodando, conexão OK
3. **Redis & Cache Isolation** - Prefixos únicos para evitar colisão de dados
4. **Reverb (WebSockets)** - Credenciais únicas por projeto
5. **Conflitos entre projetos** - Verifica se há CACHE_PREFIX ou REVERB_APP_ID duplicados
6. **APP_URL** - Resolução DNS

**Exemplo de saída:**

```
┌─ Redis & Cache Isolation ────────────────────────────────────────┐
  Host: redis | DB: 0 | Cache DB: 1
  ✓ Redis container is running

  Cache Isolation:
  ✓ CACHE_PREFIX = meuprojeto_cache_
    Good: Prefix includes project identifier

┌─ Reverb (WebSockets) Isolation ──────────────────────────────────┐
  Broadcast: reverb
  ✓ REVERB_APP_ID = 847291
  ✓ REVERB_APP_KEY = a1b2c3d4e5f6...
  ✓ REVERB_APP_SECRET = x7y8z9... (hidden)

┌─ Cross-Project Conflicts ────────────────────────────────────────┐
  ✓ No conflicts with other projects

╔═══════════════════════════════════════════════════════════════════╗
║  ✓ All checks passed!                                           ║
╚═══════════════════════════════════════════════════════════════════╝
```

**Se houver problemas:**

```
┌─ Redis & Cache Isolation ────────────────────────────────────────┐
  ⚠ CACHE_PREFIX not set

  Why: Without a unique prefix, cache keys from different projects
       will collide, causing data corruption and unexpected behavior.
  Fix: Add to .env: CACHE_PREFIX=meuprojeto_cache_

┌─ Cross-Project Conflicts ────────────────────────────────────────┐
  ⚠ CACHE_PREFIX conflict with 'outro-projeto'
    Both projects use: laravel_cache_
    This will cause cache data collision between projects
```

---

#### env:check --all (ou env:audit)

Audita TODOS os projetos em `~/projects` para verificar conflitos de configuração:

```bash
docker-local env:check --all
# ou
docker-local env:audit
```

**O que é verificado:**

1. **CACHE_PREFIX duplicados** - Projetos compartilhando mesmo prefixo de cache
2. **REVERB_APP_ID duplicados** - Projetos com mesmo ID de WebSocket
3. **REVERB_APP_KEY duplicados** - Projetos com mesma chave de autenticação
4. **Valores não definidos** - Projetos sem configurações de isolamento

**Exemplo de saída:**

```
Auditing all projects for configuration conflicts...

Found 4 project(s) with .env files

┌─ Configuration Overview ─────────────────────────────────────────┐
  PROJECT            CACHE_PREFIX         REVERB_ID    REDIS_DB
  ──────────────────────────────────────────────────────────────────
  blog               blog_cache_          847291       0
  api                api_cache_           923847       0
  loja               loja_cache_          NOT_SET      0
  admin              blog_cache_          847291       0    ← Conflitos!

┌─ CACHE_PREFIX Analysis ──────────────────────────────────────────┐
  ✗ Duplicate prefix 'blog_cache_'
    Used by: blog and admin
    Risk: Cache data will be shared/corrupted between these projects
    Fix: Change CACHE_PREFIX in one of the projects' .env files

┌─ REVERB_APP_ID Analysis ─────────────────────────────────────────┐
  ✗ Duplicate REVERB_APP_ID '847291'
    Used by: blog and admin
    Risk: WebSocket messages will be broadcast to wrong clients
    Fix: Regenerate for one project with docker-local update:env

╔═══════════════════════════════════════════════════════════════════╗
║  ✗ Found 2 issue(s) across 4 projects                           ║
╚═══════════════════════════════════════════════════════════════════╝

How to fix:

  Option 1: Regenerate .env for affected projects
    cd ~/projects/<project-name>
    docker-local update:env

  Option 2: Manually edit .env files
    - CACHE_PREFIX should be unique per project
    - REVERB_APP_ID should be a unique number
    - REVERB_APP_KEY should be a unique random string
```

---

#### make:env

Gera um novo arquivo `.env` com valores únicos para isolamento de projetos:

```bash
cd ~/projects/meuprojeto
docker-local make:env
```

**O que é gerado automaticamente:**

- `CACHE_PREFIX` - Baseado no nome do projeto
- `REVERB_APP_ID` - Número aleatório único (100000-999999)
- `REVERB_APP_KEY` - String hexadecimal de 32 caracteres
- `REVERB_APP_SECRET` - String hexadecimal de 32 caracteres

---

#### update:env

Atualiza `.env` existente **preservando valores importantes**:

```bash
cd ~/projects/meuprojeto
docker-local update:env
```

**Valores preservados:**
- `APP_NAME`, `APP_KEY`
- `REVERB_APP_ID`, `REVERB_APP_KEY`, `REVERB_APP_SECRET`
- `CACHE_PREFIX`, `REDIS_DB`, `REDIS_CACHE_DB`

**Valores atualizados:**
- Configurações de conexão (hosts, portas)
- Novos comentários e documentação
- Valores padrão ausentes

---

#### make:project
Cria novo projeto Laravel:

```bash
$ docker-local make:laravel meuprojeto
```

1. Executa `composer create-project laravel/laravel`
2. Configura .env com todos os serviços
3. Gera APP_KEY
4. Exibe URL de acesso

---

#### list

Lista todos os projetos Laravel em `~/projects`:

```bash
$ docker-local list

┌─────────────────────────────────────────────────────────────────┐
│  Laravel Projects in ~/projects                                 │
└─────────────────────────────────────────────────────────────────┘

  NAME                 URL                                 STATUS
  ────────────────────────────────────────────────────────────────
  blog                 https://blog.test                   ✓ accessible
  api                  https://api.test                    ✓ accessible
  loja                 https://loja.test                   ✗ DNS not configured
```

---

#### clone

Clona repositório e configura automaticamente:

```bash
$ docker-local clone git@github.com:user/projeto.git

Cloning repository...
Installing dependencies...
Configuring .env...
Generating application key...
Running migrations...

╔═══════════════════════════════════════════════════════════════╗
║                    Project Cloned! 🎉                         ║
╚═══════════════════════════════════════════════════════════════╝

  Project:  projeto
  Path:     /home/user/projects/projeto
  URL:      https://projeto.test
```

---

#### doctor

Diagnóstico completo do sistema:

```bash
$ docker-local doctor

┌─────────────────────────────────────────────────────────────────┐
│  System Health Check                                            │
└─────────────────────────────────────────────────────────────────┘

Docker:
  ✓ Docker running (v24.0.7)
  ✓ Docker Compose (v2.23.0)
  ✓ Disk space OK (45GB free)

Services:
  ✓ MySQL running (:3306)
  ✓ PostgreSQL running (:5432)
  ✓ Redis running (:6379)
  ✓ MinIO running (:9000)
  ✓ Mailpit running (:1025)
  ✓ Traefik running (:443)

Network:
  ✓ /etc/hosts configured
  ✓ dnsmasq configured
  ✓ *.test resolving

Local PHP:
  ✓ PHP 8.4.1
  ✓ ext-pdo_mysql
  ✓ ext-redis

Local Composer:
  ✓ Composer 2.7.0

SSL Certificates:
  ✓ mkcert installed
  ✓ *.test certificate (expires: Jan 1 2026)

Summary:
  ✓ All systems operational!
```

---

#### open

Abre projeto ou serviço no navegador:

```bash
docker-local open              # Projeto atual
docker-local open blog         # Projeto específico
docker-local open --mail       # Mailpit (emails)
docker-local open --minio      # MinIO Console
docker-local open --traefik    # Traefik Dashboard
```

---

#### xdebug

Controla Xdebug no container PHP:

```bash
docker-local xdebug on         # Habilita (para debugging)
docker-local xdebug off        # Desabilita (melhor performance)
docker-local xdebug status     # Mostra status atual
```

O toggle reinicia o container PHP automaticamente.

---

#### db:dump / db:restore

Backup e restore de database:

```bash
# Exportar
docker-local db:dump
# Cria: ~/projects/meuprojeto/dump_laravel_20250101_120000.sql

# Importar
docker-local db:restore dump.sql
# Warning: This will overwrite existing data
# Continue? [y/N]
```

---

#### queue

Gerenciamento de filas:

```bash
docker-local queue:work        # Inicia worker (Ctrl+C para parar)
docker-local queue:restart     # Envia sinal de restart
docker-local queue:failed      # Lista jobs falhos
docker-local queue:retry all   # Reprocessa todos os falhos
docker-local queue:clear       # Limpa fila (com confirmação)
```

---

#### completion

Gera autocompletion para Bash/Zsh:

```bash
# Bash - adicionar ao ~/.bashrc
eval "$(docker-local completion bash)"

# Zsh - adicionar ao ~/.zshrc
eval "$(docker-local completion zsh)"
```

Permite tab-completion para todos os comandos e argumentos.

---

## 7.3 Templates e Hooks Customizáveis

O CLI `docker-local make:laravel` suporta customização através de templates e hooks.

### Estrutura de Templates

```
~/docker-environment/templates/
├── install.sh              # Script principal de customização
├── hooks/
│   ├── pre-install.sh      # Executado ANTES da instalação
│   └── post-install.sh     # Executado APÓS a instalação
└── files/                  # Arquivos para copiar (opcional)
    ├── .editorconfig
    ├── phpstan.neon
    └── ...
```

### install.sh

Script executado após a criação do projeto e configuração do `.env`. Use para:
- Instalar pacotes Composer adicionais
- Executar comandos Artisan
- Instalar dependências NPM
- Criar estrutura de pastas
- Copiar arquivos de configuração

**Exemplo: Instalar pacotes padrão**

```bash
#!/bin/bash
PROJECT_NAME=$1
PROJECT_PATH=$2

# Instalar pacotes de desenvolvimento
docker exec -w "/var/www/$PROJECT_NAME" php composer require --dev \
    laravel/telescope \
    barryvdh/laravel-debugbar \
    laravel/pint

# Instalar Sanctum
docker exec -w "/var/www/$PROJECT_NAME" php composer require laravel/sanctum
docker exec -w "/var/www/$PROJECT_NAME" php php artisan vendor:publish \
    --provider="Laravel\Sanctum\SanctumServiceProvider"

# Executar migrations
docker exec -w "/var/www/$PROJECT_NAME" php php artisan migrate

# Instalar NPM e build
docker exec -w "/var/www/$PROJECT_NAME" php npm install
docker exec -w "/var/www/$PROJECT_NAME" php npm run build

echo "✓ Custom installation complete"
```

### hooks/pre-install.sh

Executado ANTES da criação do projeto Laravel. Use para:
- Criar banco de dados específico
- Verificar pré-requisitos
- Preparar o ambiente

```bash
#!/bin/bash
PROJECT_NAME=$1
PROJECT_PATH=$2

# Criar banco de dados específico para o projeto
docker exec mysql mysql -u root -psecret \
    -e "CREATE DATABASE IF NOT EXISTS \`$PROJECT_NAME\`;"

docker exec postgres psql -U laravel \
    -c "CREATE DATABASE $PROJECT_NAME;" 2>/dev/null || true
```

### hooks/post-install.sh

Executado APÓS a configuração do `.env` e geração do `APP_KEY`. Use para:
- Configurar permissões
- Criar usuário admin
- Executar seeders

```bash
#!/bin/bash
PROJECT_NAME=$1
PROJECT_PATH=$2

# Criar link de storage
docker exec -w "/var/www/$PROJECT_NAME" php php artisan storage:link

# Criar usuário admin
docker exec -w "/var/www/$PROJECT_NAME" php php artisan tinker --execute="
    \App\Models\User::create([
        'name' => 'Admin',
        'email' => 'admin@$PROJECT_NAME.test',
        'password' => bcrypt('password'),
    ]);
"
```

### Fluxo de Execução

```
docker-local make:laravel myapp
        │
        ▼
┌─────────────────────────────┐
│  1. hooks/pre-install.sh    │  ← Preparação
└─────────────────────────────┘
        │
        ▼
┌─────────────────────────────┐
│  2. composer create-project │  ← Instalação Laravel
└─────────────────────────────┘
        │
        ▼
┌─────────────────────────────┐
│  3. Gerar .env              │  ← Configuração automática
└─────────────────────────────┘
        │
        ▼
┌─────────────────────────────┐
│  4. php artisan key:generate│  ← Gerar APP_KEY
└─────────────────────────────┘
        │
        ▼
┌─────────────────────────────┐
│  5. hooks/post-install.sh   │  ← Pós-configuração
└─────────────────────────────┘
        │
        ▼
┌─────────────────────────────┐
│  6. templates/install.sh    │  ← Customização do usuário
└─────────────────────────────┘
        │
        ▼
    ✓ Projeto criado!
```

---

## 8. Configuração de Projetos Laravel

### 8.1 PHP Local vs Docker

O ambiente suporta **duas formas** de executar comandos PHP:

#### Opção 1: PHP Local (Recomendado)

Com PHP instalado na máquina local, você pode usar comandos diretamente:

```bash
php artisan migrate
php artisan serve      # http://localhost:8000
php artisan pail       # Laravel 11+ logs em tempo real
php artisan queue:work
php artisan horizon
composer require laravel/sanctum
./vendor/bin/pest
npm run dev
```

**Requisitos:**
```bash
# Ubuntu/Debian
sudo apt install php8.4 php8.4-{mysql,pgsql,redis,mbstring,xml,curl,zip,gd,intl}

# macOS
brew install php
pecl install redis
```

**Configurar hostnames:**
```bash
sudo docker-local setup:hosts
```

Isso adiciona ao `/etc/hosts`:
```
127.0.0.1 mysql postgres redis minio mailpit
```

Assim o mesmo `.env` funciona tanto com PHP local quanto dentro dos containers.

#### Opção 2: Via Container Docker

Se não tiver PHP local, use o container:

```bash
docker exec -it php sh
# Dentro do container:
cd /var/www/meuprojeto
php artisan migrate
```

Ou via CLI (se implementado no futuro):
```bash
docker-local shell
```

### 8.2 Compatibilidade do .env

O `.env` gerado usa hostnames que funcionam em **ambos os cenários**:

```env
DB_HOST=mysql        # ✅ Local: resolve via /etc/hosts → 127.0.0.1
                     # ✅ Docker: resolve via Docker network
REDIS_HOST=redis     # ✅ Mesmo comportamento
MAIL_HOST=mailpit    # ✅ Mesmo comportamento
```

### 8.3 O que funciona com PHP Local

| Comando | Local | Docker | Notas |
|---------|-------|--------|-------|
| `php artisan serve` | ✅ | N/A | http://localhost:8000 |
| `php artisan migrate` | ✅ | ✅ | Conecta ao MySQL via hostname |
| `php artisan queue:work` | ✅ | ✅ | Conecta ao Redis |
| `php artisan pail` | ✅ | ✅ | Laravel 11+ live logs |
| `php artisan horizon` | ✅ | ✅ | Se Horizon instalado |
| `php artisan tinker` | ✅ | ✅ | |
| `composer install` | ✅ | ✅ | |
| `./vendor/bin/pest` | ✅ | ✅ | |
| `npm run dev` | ✅ | ✅ | Vite HMR |
| https://projeto.test | Via Traefik | Via Traefik | Nginx + PHP-FPM |

### 8.4 Template .env Completo

```env
# ==============================================================================
# Application
# ==============================================================================
APP_NAME="Meu Projeto"
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_TIMEZONE=America/Sao_Paulo
APP_URL=https://meuprojeto.test

APP_LOCALE=pt_BR
APP_FALLBACK_LOCALE=en
APP_FAKER_LOCALE=pt_BR

# ==============================================================================
# MySQL 9.1
# ==============================================================================
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret
DB_CHARSET=utf8mb4
DB_COLLATION=utf8mb4_unicode_ci

# ==============================================================================
# PostgreSQL 17 (alternativa)
# ==============================================================================
# DB_CONNECTION=pgsql
# DB_HOST=postgres
# DB_PORT=5432
# DB_DATABASE=laravel
# DB_USERNAME=laravel
# DB_PASSWORD=secret

# ==============================================================================
# Redis 8
# ==============================================================================
REDIS_CLIENT=phpredis
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

CACHE_STORE=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis
BROADCAST_CONNECTION=redis

CACHE_PREFIX=meuprojeto_cache
REDIS_CACHE_DB=1
REDIS_SESSION_DB=2
REDIS_QUEUE_DB=3

# ==============================================================================
# MinIO (S3 Storage)
# ==============================================================================
FILESYSTEM_DISK=s3

AWS_ACCESS_KEY_ID=minio
AWS_SECRET_ACCESS_KEY=minio123
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=laravel
AWS_ENDPOINT=http://minio:9000
AWS_USE_PATH_STYLE_ENDPOINT=true
AWS_URL=http://localhost:9000/laravel

# ==============================================================================
# Mailpit
# ==============================================================================
MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="noreply@meuprojeto.test"
MAIL_FROM_NAME="${APP_NAME}"

# ==============================================================================
# Logging
# ==============================================================================
LOG_CHANNEL=stack
LOG_STACK=single
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug
```

### 8.5 Convenção de Nomes

O nome da pasta do projeto define a URL:

| Pasta | URL Principal | Subdomínios |
|-------|---------------|-------------|
| `~/projects/meuprojeto` | `https://meuprojeto.test` | `https://api.meuprojeto.test` |
| `~/projects/loja` | `https://loja.test` | `https://admin.loja.test` |
| `~/projects/api` | `https://api.test` | `https://v1.api.test` |

### 8.6 Acessando Subdomínios no Laravel

O Nginx injeta o subdomínio no header `X-Subdomain`:

```php
// Em qualquer lugar do Laravel
$subdomain = request()->header('X-Subdomain'); // "api", "admin", etc.

// Ou via route domain
Route::domain('{tenant}.meuprojeto.test')->group(function () {
    Route::get('/', function ($tenant) {
        return "Tenant: $tenant";
    });
});
```

### 8.7 Redis e Reverb - Múltiplos Projetos

O ambiente suporta **múltiplos projetos Laravel** compartilhando os mesmos serviços Redis e Reverb, desde que configurados corretamente.

#### Redis - Isolamento entre Projetos

O Laravel usa **3 mecanismos** para isolar dados:

##### 1. Prefixos Automáticos (baseados em APP_NAME)

Por padrão, o Laravel já gera prefixos únicos baseados em `APP_NAME`:

```php
// config/database.php
'prefix' => env('REDIS_PREFIX', Str::slug(env('APP_NAME'), '_').'_database_'),

// config/cache.php
'prefix' => env('CACHE_PREFIX', Str::slug(env('APP_NAME'), '_').'_cache_'),
```

Se `APP_NAME=blog`, as chaves serão prefixadas com `blog_database_` e `blog_cache_`.

##### 2. Database Numbers (0-15)

Redis tem 16 databases. Pode-se usar databases diferentes por projeto ou por função:

```env
# Projeto Blog
REDIS_DB=0
REDIS_CACHE_DB=1

# Projeto API (em outro .env)
REDIS_DB=2
REDIS_CACHE_DB=3
```

##### 3. Prefixos Explícitos (opcional)

Se quiser sobrescrever os prefixos automáticos:

```env
REDIS_PREFIX="meuprojeto_database_"
CACHE_PREFIX="meuprojeto_cache_"
```

#### Reverb - Isolamento entre Projetos

Cada projeto **PRECISA** de credenciais únicas para Reverb:

```env
# Projeto 1
REVERB_APP_ID=123456
REVERB_APP_KEY=chave-unica-projeto-1
REVERB_APP_SECRET=secret-unico-projeto-1

# Projeto 2 (em outro .env)
REVERB_APP_ID=789012
REVERB_APP_KEY=chave-unica-projeto-2
REVERB_APP_SECRET=secret-unico-projeto-2
```

O CLI `docker-local make:laravel` gera automaticamente valores únicos para cada projeto.

#### Configuração .env Gerada pelo CLI

Quando você executa `docker-local make:laravel meuprojeto`, o .env já vem configurado com:

```env
APP_NAME="meuprojeto"

# Redis - prefixos derivam automaticamente de APP_NAME
REDIS_DB=0
REDIS_CACHE_DB=1
CACHE_PREFIX=meuprojeto_cache_

# Reverb - valores únicos gerados automaticamente
REVERB_APP_ID=847291          # Gerado aleatoriamente
REVERB_APP_KEY=a1b2c3d4e5...  # Gerado com openssl
REVERB_APP_SECRET=f6g7h8i9... # Gerado com openssl
```

#### ⚠️ Cuidados

1. **Cache Flush**: `Cache::flush()` não respeita prefixos e limpa TUDO do Redis
2. **Unique Job Locks**: Jobs únicos com mesmo nome podem colidir entre projetos
3. **Rate Limiting**: Rate limiters compartilham contagem se tiverem mesmo nome
4. **Horizon**: Use `HORIZON_PREFIX` único se usar Laravel Horizon

```env
HORIZON_PREFIX="meuprojeto_horizon:"
```

---

## 9. SSL e Domínios

### 9.1 Certificados SSL

Gerados automaticamente via **mkcert**:

```bash
# Certificado *.localhost
mkcert -cert-file certs/localhost.crt \
       -key-file certs/localhost.key \
       "localhost" "*.localhost" "*.*.localhost"

# Certificado *.test
mkcert -cert-file certs/test.crt \
       -key-file certs/test.key \
       "test" "*.test" "*.*.test"
```

### 9.2 Domínios Suportados

| Padrão | Exemplo | Uso |
|--------|---------|-----|
| `*.test` | `meuprojeto.test` | Projeto principal |
| `*.*.test` | `api.meuprojeto.test` | Subdomínio do projeto |
| `*.localhost` | `traefik.localhost` | Serviços do ambiente |

### 9.3 Regenerar Certificados

```bash
composer cert:generate
docker-compose restart traefik
```

---

## 10. DNS e Subdomínios

### 10.1 Opção 1: dnsmasq (Recomendado)

Configura resolução wildcard automática:

```bash
composer docker:dns
```

Isso cria `/etc/dnsmasq.d/laravel-dev.conf`:
```
address=/.test/127.0.0.1
address=/.localhost/127.0.0.1
```

### 10.2 Opção 2: /etc/hosts (Manual)

Para cada projeto/subdomínio:

```bash
# Adicionar manualmente
sudo composer host:add meuprojeto.test api admin

# Resultado em /etc/hosts:
127.0.0.1 meuprojeto.test api.meuprojeto.test admin.meuprojeto.test
```

### 10.3 Verificação

```bash
ping meuprojeto.test
# Deve resolver para 127.0.0.1
```

---

## 11. Xdebug

### 11.1 Configuração Padrão

**Habilitado por padrão** com as seguintes configurações:

```ini
xdebug.mode=develop,debug
xdebug.client_host=host.docker.internal
xdebug.client_port=9003
xdebug.start_with_request=trigger
xdebug.idekey=PHPSTORM
```

### 11.2 Variáveis de Ambiente

```env
# No .env do docker-environment
XDEBUG_ENABLED=true
XDEBUG_MODE=develop,debug
```

### 11.3 Modos Disponíveis

| Modo | Descrição |
|------|-----------|
| `develop` | Mensagens de erro melhoradas |
| `debug` | Step debugging (IDEs) |
| `coverage` | Code coverage para testes |
| `profile` | Profiling de performance |
| `trace` | Function trace |

### 11.4 Configuração PhpStorm

1. `Settings > PHP > Debug` → Port: `9003`
2. `Settings > PHP > Servers`:
   - Name: `docker`
   - Host: `localhost`
   - Port: `443`
   - Use path mappings: 
     - `/var/www/meuprojeto` → `~/projects/meuprojeto`

### 11.5 Configuração VS Code

`.vscode/launch.json`:
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Listen for Xdebug",
            "type": "php",
            "request": "launch",
            "port": 9003,
            "pathMappings": {
                "/var/www": "${env:HOME}/projects"
            }
        }
    ]
}
```

### 11.6 Desabilitar Xdebug (Performance)

```env
# .env
XDEBUG_ENABLED=false
```

```bash
composer docker:build
composer docker:up
```

---

## 12. Extensões PHP

### 12.1 Extensões Instaladas

#### Core Laravel
- `pdo`, `pdo_mysql`, `pdo_pgsql`, `mysqli`
- `mbstring`, `xml`, `dom`, `simplexml`, `xmlwriter`, `xsl`
- `bcmath`, `gmp`, `intl`, `zip`, `opcache`
- `gd` (JPEG, PNG, WebP, AVIF), `exif`, `imagick`
- `pcntl`, `sockets`
- `sodium`, `calendar`, `gettext`

#### Cache & Queue
- `redis`, `memcached`, `apcu`
- `amqp` (RabbitMQ)

#### Performance & Debug
- `opcache` (com JIT)
- `xdebug`
- `pcov` (coverage rápido)

#### Outros
- `swoole` (Laravel Octane)
- `mongodb`
- `grpc`, `protobuf`
- `ffi`

### 12.2 Verificar Extensões

```bash
docker exec php php -m
```

---

## 13. URLs e Portas

### 13.1 URLs de Acesso

| Serviço | URL |
|---------|-----|
| Projeto Laravel | `https://[nome-projeto].test` |
| Subdomínio | `https://[sub].[nome-projeto].test` |
| Traefik Dashboard | `https://traefik.localhost` |
| Mailpit | `https://mail.localhost` |
| MinIO Console | `https://minio.localhost` |
| MinIO API (S3) | `https://s3.localhost` |

### 13.2 Portas Locais

| Serviço | Porta | Uso |
|---------|-------|-----|
| HTTP | 80 | Redireciona para HTTPS |
| HTTPS | 443 | Acesso web |
| Traefik Dashboard | 8080 | Dashboard admin |
| MySQL | 3306 | Conexão direta ao banco |
| PostgreSQL | 5432 | Conexão direta ao banco |
| Redis | 6379 | Conexão direta |
| MinIO API | 9000 | S3 API |
| MinIO Console | 9001 | Web interface |
| Mailpit SMTP | 1025 | Envio de emails |
| Mailpit Web | 8025 | Visualização de emails |

### 13.3 Hosts Internos (Docker Network)

Para uso nos arquivos `.env` dos projetos Laravel:

| Serviço | Host |
|---------|------|
| MySQL | `mysql` |
| PostgreSQL | `postgres` |
| Redis | `redis` |
| MinIO | `minio` |
| Mailpit | `mailpit` |

---

## 14. Requisitos do Sistema

### 14.1 Software Necessário

| Software | Versão Mínima | Instalação |
|----------|---------------|------------|
| Docker | 24.0+ | [docs.docker.com](https://docs.docker.com/get-docker/) |
| Docker Compose | 2.20+ | Incluído no Docker Desktop |
| Git | 2.30+ | `apt install git` |
| mkcert | 1.4+ | Instalado automaticamente |

### 14.2 Sistemas Operacionais

- ✅ Ubuntu 22.04+ / Debian 12+
- ✅ Fedora 38+
- ✅ Arch Linux
- ✅ macOS 12+ (Monterey)
- ⚠️ Windows (via WSL2)

### 14.3 Recursos de Hardware

| Recurso | Mínimo | Recomendado |
|---------|--------|-------------|
| RAM | 8GB | 16GB |
| CPU | 4 cores | 8 cores |
| Disco | 20GB livres | SSD recomendado |

---

## 15. Instalação

### 15.1 Instalação Rápida

```bash
# 1. Clonar/baixar para ~/docker-environment
cd ~
git clone <repo-url> docker-environment
# Ou extrair o zip para ~/docker-environment

# 2. Instalar CLI docker-local
cd docker-environment
./scripts/install-cli.sh

# 3. Executar setup completo
docker-local init

# 4. Configurar para PHP local (requer sudo)
sudo docker-local setup:hosts

# 5. Configurar DNS wildcard (requer sudo)
sudo docker-local setup:dns

# 6. Verificar instalação
docker-local config
```

### 15.2 O que o comando `init` faz

O comando `docker-local init` executa automaticamente:

1. ✅ Verifica se Docker está rodando
2. ✅ Cria `.env` a partir de `.env.example` (se não existir)
3. ✅ Gera certificados SSL com mkcert (se não existirem)
4. ✅ Cria diretório `~/projects` (se não existir)
5. ✅ Faz build das imagens Docker (se necessário)
6. ✅ Inicia todos os containers
7. ✅ Verifica status dos serviços
8. ✅ Informa quais comandos sudo ainda são necessários

**Características:**
- **Idempotente**: Pode ser executado múltiplas vezes sem problemas
- **Não requer sudo**: Comandos que precisam de sudo são separados
- **Feedback claro**: Mostra o que já está configurado e o que falta

### 15.3 Comandos que Requerem Sudo

Alguns comandos modificam arquivos do sistema e precisam de sudo:

```bash
# Adiciona hostnames ao /etc/hosts
# Permite que PHP local conecte aos serviços Docker
sudo docker-local setup:hosts

# Instala e configura dnsmasq
# Permite usar domínios *.test e *.localhost
sudo docker-local setup:dns
```

**Nota:** Esses comandos verificam se você está rodando como root e dão uma mensagem clara se não estiver:

```
Error: This command requires root privileges

Please run with sudo:
  sudo docker-local setup:hosts
```

### 15.4 Verificações de Idempotência

Todos os comandos de configuração verificam se a configuração já existe antes de fazer alterações:

**setup:hosts:**
```
✓ Docker hostnames already configured in /etc/hosts

Current entry:
127.0.0.1 mysql postgres redis minio mailpit

No changes needed.
```

**setup:dns:**
```
✓ DNS wildcard already configured!
✓ dnsmasq service is running

Testing DNS resolution:
  ✓ *.test resolves to 127.0.0.1

No changes needed.
```

### 15.5 Criar Primeiro Projeto

Com o CLI `docker-local` instalado:

```bash
# Criar projeto Laravel
docker-local make:laravel meuprojeto

# O projeto será criado em ~/projects/meuprojeto
# com .env já configurado para todos os serviços

# Acessar no navegador
# https://meuprojeto.test

# Entrar no projeto e executar migrations
cd ~/projects/meuprojeto
docker-local artisan migrate

# Outros comandos úteis
docker-local composer require laravel/sanctum
docker-local tinker
docker-local test
```

### 15.6 Projeto Existente

Para projetos Laravel já existentes:

```bash
# Mover projeto para ~/projects (se necessário)
mv ~/meu-projeto-existente ~/projects/meuprojeto

# Entrar no projeto
cd ~/projects/meuprojeto

# Gerar .env com configurações Docker
docker-local make:env

# Ou atualizar .env existente (preserva APP_KEY e APP_NAME)
docker-local update:env

# Gerar APP_KEY (se necessário)
docker-local artisan key:generate

# Executar migrations
docker-local artisan migrate

# Testar
curl -k https://meuprojeto.test
```

### 15.7 Verificar Configurações

```bash
# Ver todas as configurações .env disponíveis
docker-local show:env

# Ver status dos serviços
docker-local status

# Ver portas expostas
docker-local ports

# Ver configuração do CLI
docker-local config
```

### 15.8 Customizar Instalação de Novos Projetos

Edite os templates para customizar a criação de novos projetos:

```bash
# Script principal de customização
nano ~/docker-environment/templates/install.sh

# Hooks
nano ~/docker-environment/templates/hooks/pre-install.sh
nano ~/docker-environment/templates/hooks/post-install.sh
```

Veja a seção [7.3 Templates e Hooks](#73-templates-e-hooks-customizáveis) para detalhes.

---

## 16. Roadmap

### 16.1 Versão 1.0 (Atual)

- [x] Docker Compose com todos os serviços
- [x] PHP 8.4 com extensões completas
- [x] MySQL 9.1 / PostgreSQL 17
- [x] Redis 8
- [x] MinIO com bucket automático
- [x] Mailpit
- [x] Traefik com SSL
- [x] Xdebug configurado
- [x] Scripts de gerenciamento
- [x] Suporte a subdomínios wildcard

### 16.2 Versão 1.1 (Planejado)

- [ ] Comando `make:env` interativo
- [ ] Suporte a múltiplos buckets MinIO
- [ ] Healthcheck melhorado no status
- [ ] Profile de recursos (low/medium/high)
- [ ] Backup automático de volumes

### 16.3 Versão 1.2 (Futuro)

- [ ] Suporte a Elasticsearch/Meilisearch
- [ ] Suporte a MongoDB
- [ ] Dashboard web próprio
- [ ] Integração com Laravel Sail
- [ ] Suporte a múltiplas versões PHP simultâneas

### 16.4 Versão 2.0 (Longo Prazo)

- [ ] GUI para gerenciamento
- [ ] Suporte a clusters (múltiplas máquinas)
- [ ] Integração com cloud providers
- [ ] Marketplace de serviços adicionais

---

## 17. Decisões Técnicas

### 17.1 Por que Traefik em vez de Nginx Proxy?

| Aspecto | Traefik | Nginx Proxy |
|---------|---------|-------------|
| Configuração automática | ✅ Via labels | ❌ Arquivos manuais |
| Wildcards SSL | ✅ Nativo | ⚠️ Complexo |
| Dashboard | ✅ Incluído | ❌ Não tem |
| Hot reload | ✅ Automático | ❌ Requer restart |
| Documentação | ✅ Excelente | ⚠️ Fragmentada |

### 17.2 Por que mkcert em vez de Let's Encrypt?

- **mkcert**: Certificados locais, offline, confiáveis pelo sistema
- **Let's Encrypt**: Requer domínio real, DNS público, renovação

Para desenvolvimento local, mkcert é a escolha correta.

### 17.3 Por que Alpine Linux para containers?

- Imagens menores (5-10x)
- Menor superfície de ataque
- Inicialização mais rápida
- Amplamente testado em produção

### 17.4 Por que PHP-FPM em vez de Laravel Octane?

- Octane é opcional e pode ser habilitado no projeto
- PHP-FPM é o padrão e funciona com qualquer projeto
- Menos complexidade no ambiente base
- Swoole está disponível se necessário

### 17.5 Por que MySQL 9.1 como padrão?

- Versão Innovation com features mais recentes
- Para projetos que precisam de estabilidade máxima, usar `MYSQL_VERSION=8.4`
- PostgreSQL 17 também está disponível como alternativa

---

## Changelog

### [1.0.0] - 2025-12-30

#### Adicionado
- Versão inicial do PRD
- Stack completa: PHP 8.4, MySQL 9.1, PostgreSQL 17, Redis 8, Traefik 3.6
- Suporte a SSL com mkcert
- Subdomínios wildcard
- Xdebug habilitado por padrão
- Interface de comandos via Composer
- Comando make:env para gerar configurações

---

## Contribuindo

1. Fork o repositório
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

---

## Licença

MIT License - veja o arquivo [LICENSE](LICENSE) para detalhes.
