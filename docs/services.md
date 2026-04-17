# Services Configuration

Detailed configuration for all Docker services in the environment.

## Overview

All services run on a shared Docker network (`laravel-dev`) and are configured for development use.

| Service | Container | Port | Purpose |
|---------|-----------|------|---------|
| Traefik | traefik | 80, 443, 8080 | Reverse proxy, SSL |
| PHP-FPM | php | 9000 | Application runtime |
| Nginx | nginx | - | Web server |
| MySQL | mysql | 3306 | Database |
| PostgreSQL | postgres | 5432 | Database |
| Redis | redis | 6379 | Cache/Queue |
| MinIO | minio | 9000, 9001 | Object storage |
| Mailpit | mailpit | 1025, 8025 | Email testing |

---

## PHP 8.4

### Container Details

- **Image:** `php:8.4-fpm-alpine` (custom build)
- **Container:** `php`
- **Working Directory:** `/var/www`

### Installed Extensions

**Core Laravel Extensions:**
- PDO, pdo_mysql, pdo_pgsql, mysqli
- GD (JPEG, PNG, WebP, AVIF, FreeType)
- Redis, ImageMagick
- ZIP, Intl, Mbstring
- XML, DOM, SimpleXML, SOAP, XSL
- BCMath, GMP, OPcache, PCNTL, Sockets

**Optional Extensions:**
- Swoole (Laravel Octane)
- MongoDB, gRPC, Protobuf
- AMQP (RabbitMQ)
- Memcached, APCu
- PCOV (code coverage)

### Configuration Files

**php/php.ini:**
```ini
memory_limit = 512M
upload_max_filesize = 100M
post_max_size = 100M
max_execution_time = 300
```

**php/xdebug.ini:**
```ini
xdebug.mode = develop,debug
xdebug.start_with_request = yes
xdebug.client_host = host.docker.internal
xdebug.client_port = 9003
xdebug.idekey = VSCODE
```

### Xdebug Usage

```bash
# Enable (for debugging)
docker-local xdebug on

# Disable (better performance)
docker-local xdebug off

# Check status
docker-local xdebug status
```

---

## MySQL 9.1

### Container Details

- **Image:** `mysql:9.1` (or `mysql:8.4-lts` for LTS)
- **Container:** `mysql`
- **Port:** 3306

### Default Credentials

| Setting | Value |
|---------|-------|
| Root Password | `secret` |
| Database | `laravel` |
| Username | `laravel` |
| Password | `secret` |

### Configuration

**mysql/my.cnf:**
```ini
[mysqld]
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
max_connections = 200
slow_query_log = 1
slow_query_log_file = /var/lib/mysql/slow.log
long_query_time = 2
```

### Laravel .env Configuration

```env
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret
```

### CLI Access

```bash
docker-local db:mysql
```

---

## PostgreSQL 17

### Container Details

- **Image:** `postgres:17-alpine`
- **Container:** `postgres`
- **Port:** 5432

### Default Credentials

| Setting | Value |
|---------|-------|
| Database | `laravel` |
| Username | `laravel` |
| Password | `secret` |

### Pre-installed Extensions

- `uuid-ossp` - UUID generation
- `pgcrypto` - Cryptographic functions

### Laravel .env Configuration

```env
DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret
```

### CLI Access

```bash
docker-local db:postgres
```

---

## Redis 8

### Container Details

- **Image:** `redis:8-alpine`
- **Container:** `redis`
- **Port:** 6379

### Configuration

**redis/redis.conf:**
```conf
maxmemory 256mb
maxmemory-policy allkeys-lru
appendonly yes
appendfsync everysec
io-threads 4
io-threads-do-reads yes
activedefrag yes
```

### Laravel .env Configuration

```env
REDIS_HOST=redis
REDIS_PASSWORD=null
REDIS_PORT=6379

# Cache
CACHE_STORE=redis
CACHE_PREFIX=myproject_cache_

# Session
SESSION_DRIVER=redis

# Queue
QUEUE_CONNECTION=redis
```

### CLI Access

```bash
docker-local db:redis
```

### Multi-Project Isolation

Use different `REDIS_DB` values (0-15) for each project:

```env
# Project A
REDIS_DB=0

# Project B
REDIS_DB=1
```

---

## MinIO (S3 Storage)

### Container Details

- **Image:** `minio/minio:latest`
- **Container:** `minio`
- **API Port:** 9000
- **Console Port:** 9001

### Default Credentials

| Setting | Value |
|---------|-------|
| Username | `minio` |
| Password | `minio123` |
| Default Bucket | `laravel` |

### URLs

| Service | URL |
|---------|-----|
| Console | `https://minio.localhost` |
| API | `https://s3.localhost` |

### Laravel .env Configuration

```env
FILESYSTEM_DISK=s3

AWS_ACCESS_KEY_ID=minio
AWS_SECRET_ACCESS_KEY=minio123
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=laravel
AWS_ENDPOINT=http://minio:9000
AWS_USE_PATH_STYLE_ENDPOINT=true
AWS_URL=http://localhost:9000/laravel
```

### Automatic Setup

The `minio-setup` container automatically:
- Creates the default bucket
- Sets public access on `/public` prefix

---

## Mailpit (Email Testing)

### Container Details

- **Image:** `axllent/mailpit:latest`
- **Container:** `mailpit`
- **SMTP Port:** 1025
- **Web UI Port:** 8025

### URL

- Web UI: `https://mail.localhost`

### Laravel .env Configuration

```env
MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"
```

### Features

- Stores up to 5000 messages
- Full attachment support
- API for automated testing
- Search and filtering

---

## Ollama (Local LLM Inference)

### Container Details

- **Image:** `ollama/ollama:latest`
- **Container:** `ollama`
- **Port:** 11434 (host) → 11434 (container)
- **URL (internal):** `http://ollama:11434`
- **URL (host):** `http://localhost:11434`
- **URL (Traefik):** `https://ollama.localhost`

### Pre-pulled Models

On first start, the container pulls:
- `nomic-embed-text` — 768-dim embeddings (OpenAI-compatible `/v1/embeddings`)
- `llama3.2:3b` — small, fast general-purpose chat model
- `llava` — vision-capable multimodal model

### OpenAI-compatible endpoint

Ollama exposes an OpenAI-compatible API at `/v1/*`. This lets you reuse any OpenAI SDK (including Laravel AI SDK's `openai` driver) pointed at `http://ollama:11434/v1` — useful for embeddings and chat when the target SDK doesn't have a native Ollama driver.

### CLI

```bash
docker exec ollama ollama pull <model>
docker exec ollama ollama list
docker exec ollama ollama run <model> "hello"
```

---

## Whisper ASR (Speech-to-Text)

### Container Details

- **Image:** `fedirz/faster-whisper-server:latest-cpu`
- **Container:** `whisper`
- **Port:** 9501 (host) → 8000 (container)
- **URL (internal):** `http://whisper:8000`
- **URL (host):** `http://localhost:9501`
- **URL (Traefik):** `https://whisper.localhost`
- **Docs UI:** `http://localhost:9501/docs`

### OpenAI-compatible endpoint

Exposes `/v1/audio/transcriptions` (OpenAI-compatible). Laravel AI SDK's `openai` driver works as-is when `OPENAI_URL` is pointed at `http://whisper:8000/v1`.

### Example

```bash
curl -X POST http://localhost:9501/v1/audio/transcriptions \
  -F "file=@audio.mp3" \
  -F "model=Systran/faster-whisper-base" \
  -F "response_format=json"
```

### Model selection

`.env` — `WHISPER_MODEL=Systran/faster-whisper-{tiny,base,small,medium,large-v3}`.
Larger models are more accurate but slower. `base` is a good default.

---

## tusd (Resumable uploads)

### Container Details

- **Image:** `tusproject/tusd:latest`
- **Container:** `tusd`
- **Port:** 1080 (host) → 1080 (container)
- **URL (internal):** `http://tusd:1080`
- **URL (host):** `http://localhost:1080`
- **URL (Traefik):** `https://tusd.localhost`
- **Base path:** `/files/`

### Backing store

tusd writes chunks directly to MinIO (S3-compatible) at `http://minio:9000`, using `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` for auth. Target bucket defaults to `TUSD_S3_BUCKET=laravel`; override per-project via `.env`.

### Client wiring

```js
// Uppy.js
new Uppy().use(Tus, { endpoint: 'http://localhost:1080/files/' })
```

Upload IDs returned by tusd can be persisted in your application to locate the final S3 object.

### Authorization (optional)

Use `-hooks-http=http://<your-app>/tus/hooks` to validate each pre-create request against your Laravel app (user identity, bucket prefix, plan limits). Omitted in the default docker-local config — uploads are unauthenticated inside the dev environment.

---

## Traefik 3.6 (Reverse Proxy)

### Container Details

- **Image:** `traefik:v3.6`
- **Container:** `traefik`
- **Ports:** 80, 443, 8080

### Dashboard

URL: `https://traefik.localhost`

### Features

- Automatic SSL termination
- HTTP to HTTPS redirect
- Dynamic routing via Docker labels
- Wildcard certificate support

### SSL Certificates

Generated with mkcert and stored in `./certs/`:
- `*.test` wildcard
- `*.localhost` wildcard

### Routing Rules

| Pattern | Example | Routes To |
|---------|---------|-----------|
| `*.test` | `blog.test` | Nginx → PHP |
| `*.*.test` | `api.blog.test` | Nginx → PHP |
| `traefik.localhost` | - | Dashboard |
| `mail.localhost` | - | Mailpit |
| `minio.localhost` | - | MinIO Console |
| `s3.localhost` | - | MinIO API |

---

## Nginx (Web Server)

### Container Details

- **Image:** `nginx:alpine`
- **Container:** `nginx`

### Multi-Project Routing

**nginx/default.conf:**
```nginx
map $host $project_name {
    # myproject.test → myproject
    ~^(?<proj>[^.]+)\.test$ $proj;
    # api.myproject.test → myproject
    ~^[^.]+\.(?<proj>[^.]+)\.test$ $proj;
}

server {
    listen 80;
    root /var/www/$project_name/public;
    index index.php;

    location ~ \.php$ {
        fastcgi_pass php:9000;
        # ... PHP-FPM configuration
    }
}
```

### Request Flow

1. Browser → `https://myproject.test`
2. Traefik (443) → SSL termination
3. Nginx → Route to `/var/www/myproject/public`
4. PHP-FPM → Process Laravel request

---

## Data Persistence

All data is stored in named Docker volumes:

| Volume | Service | Path |
|--------|---------|------|
| `laravel-dev-mysql` | MySQL | `/var/lib/mysql` |
| `laravel-dev-postgres` | PostgreSQL | `/var/lib/postgresql/data` |
| `laravel-dev-redis` | Redis | `/data` |
| `laravel-dev-minio` | MinIO | `/data` |
| `laravel-dev-mailpit` | Mailpit | `/data` |

### Backup Volumes

```bash
# List volumes
docker volume ls | grep laravel-dev

# Backup MySQL data
docker run --rm -v laravel-dev-mysql:/data -v $(pwd):/backup alpine tar czf /backup/mysql-backup.tar.gz -C /data .
```

---

## Health Checks

All services include health checks:

| Service | Check | Interval |
|---------|-------|----------|
| MySQL | `mysqladmin ping` | 10s |
| PostgreSQL | `pg_isready` | 10s |
| Redis | `redis-cli ping` | 10s |
| MinIO | `mc ready local` | 30s |

PHP-FPM depends on all database services being healthy before starting.

---

## Customization

### Change MySQL Version

In `.env`:
```env
MYSQL_VERSION=8.4-lts
```

### Disable Xdebug

In `.env`:
```env
XDEBUG_ENABLED=false
```

### Change Ports

In `.env`:
```env
MYSQL_PORT=3307
POSTGRES_PORT=5433
REDIS_PORT=6380
MINIO_API_PORT=9002
MINIO_CONSOLE_PORT=9003
```
