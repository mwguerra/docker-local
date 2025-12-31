# Architecture

System design, request flow, and technical architecture of the Laravel Docker Development Environment.

## Overview

This environment provides a complete, containerized development stack that mirrors production environments while optimizing for developer experience.

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Browser                                     │
│                    https://myproject.test                           │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     DNS Resolution                                   │
│              (dnsmasq or /etc/hosts)                                │
│                    *.test → 127.0.0.1                               │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Traefik (443)                                   │
│              SSL Termination + Routing                              │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       Nginx (80)                                     │
│         Multi-project routing via hostname                          │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     PHP-FPM (9000)                                   │
│                   Laravel Application                               │
└─────────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│    MySQL      │     │  PostgreSQL   │     │    Redis      │
│    (3306)     │     │    (5432)     │     │    (6379)     │
└───────────────┘     └───────────────┘     └───────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│    MinIO      │     │   Mailpit     │     │   Traefik     │
│ (9000/9001)   │     │ (1025/8025)   │     │  Dashboard    │
└───────────────┘     └───────────────┘     └───────────────┘
```

---

## Request Flow

### Step-by-Step Request Processing

1. **DNS Resolution**
   - Browser requests `https://myproject.test`
   - DNS (dnsmasq or `/etc/hosts`) resolves `*.test` → `127.0.0.1`

2. **Traefik Routing**
   - Traefik receives request on port 443
   - Matches hostname against routing rules
   - Terminates SSL using mkcert certificates
   - Forwards to appropriate backend service

3. **Nginx Processing**
   - Receives plain HTTP from Traefik
   - Extracts project name from hostname
   - Sets document root to `/var/www/{project}/public`
   - For PHP files, forwards to PHP-FPM

4. **Laravel Execution**
   - PHP-FPM processes the Laravel application
   - Connects to databases, cache, etc.
   - Returns response through the chain

### Hostname Extraction

Nginx uses regex to extract project name:

```nginx
map $host $project_name {
    # myproject.test → myproject
    ~^(?<proj>[^.]+)\.test$ $proj;

    # api.myproject.test → myproject (subdomain support)
    ~^[^.]+\.(?<proj>[^.]+)\.test$ $proj;
}
```

---

## Network Architecture

### Docker Network

All containers share a bridge network:

```yaml
networks:
  laravel-dev:
    name: laravel-dev
    driver: bridge
```

### Service Discovery

Containers can reach each other by container name:
- `mysql` → MySQL server
- `postgres` → PostgreSQL server
- `redis` → Redis server
- `minio` → MinIO S3 API
- `mailpit` → SMTP server
- `php` → PHP-FPM

### Port Exposure

| Port | Service | External Access |
|------|---------|-----------------|
| 80 | Traefik | Yes |
| 443 | Traefik | Yes |
| 8080 | Traefik Dashboard | Yes |
| 3306 | MySQL | Yes |
| 5432 | PostgreSQL | Yes |
| 6379 | Redis | Yes |
| 9000 | MinIO API | Yes |
| 9001 | MinIO Console | Yes |
| 1025 | Mailpit SMTP | Yes |
| 8025 | Mailpit Web | Yes |
| 9000 | PHP-FPM | No (internal) |
| 80 | Nginx | No (internal) |

---

## Volume Mounts

### Project Files

```yaml
php:
  volumes:
    - ${PROJECTS_PATH:-../projects}:/var/www:cached

nginx:
  volumes:
    - ${PROJECTS_PATH:-../projects}:/var/www:cached
```

Projects in `~/projects` are mounted at `/var/www`:
- `~/projects/blog` → `/var/www/blog`
- `~/projects/api` → `/var/www/api`

### Configuration Files

The package uses a hybrid approach: defaults from the package, with user overrides from config directory.

```yaml
php:
  volumes:
    # Package default or user override
    - ${DOCKER_LOCAL_PACKAGE_DIR}/resources/docker/php/php.ini:/usr/local/etc/php/conf.d/custom.ini:ro
    - ${DOCKER_LOCAL_PACKAGE_DIR}/resources/docker/php/xdebug.ini:/usr/local/etc/php/conf.d/xdebug.ini:ro

nginx:
  volumes:
    - ${DOCKER_LOCAL_PACKAGE_DIR}/resources/docker/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
```

Users can override by placing files in `~/.config/docker-local/`:
- `~/.config/docker-local/php/php.ini` - Custom PHP settings
- `~/.config/docker-local/nginx/default.conf` - Custom Nginx config

### Data Volumes

```yaml
volumes:
  mysql_data:      # Persistent MySQL data
  postgres_data:   # Persistent PostgreSQL data
  redis_data:      # Persistent Redis data (RDB + AOF)
  minio_data:      # Persistent object storage
  mailpit_data:    # Persistent email storage
```

---

## Multi-Project Isolation

### Problem

Multiple Laravel projects sharing services can conflict:
- Cache keys overlap
- WebSocket channels mix
- Session data interferes

### Solution

Each project gets unique identifiers:

| Variable | Generation | Example |
|----------|------------|---------|
| `CACHE_PREFIX` | `{project}_cache_` | `blog_cache_` |
| `REVERB_APP_ID` | Random 6 digits | `847291` |
| `REVERB_APP_KEY` | `openssl rand -base64 32` | `abc123...` |
| `REVERB_APP_SECRET` | `openssl rand -base64 32` | `xyz789...` |

### Conflict Detection

```bash
# Check current project
docker-local env:check

# Audit all projects
docker-local env:check --all
```

Example conflict output:
```
┌─ Cross-Project Conflicts ────────────────────────────────────────┐
  ⚠ CACHE_PREFIX conflict with 'other-project'
    Both projects use: laravel_cache_

  Why: Cache data will be shared/corrupted between projects
  Fix: Change CACHE_PREFIX in one of the projects' .env files
```

---

## SSL/TLS Architecture

### Certificate Generation

Using mkcert for locally-trusted certificates:

```bash
mkcert -install
mkcert "*.test" "*.localhost"
```

### Certificate Storage

Certificates are stored in the user's config directory:

```
~/.config/docker-local/certs/
├── localhost.crt
├── localhost.key
├── test.crt
└── test.key
```

### Traefik TLS Configuration

**resources/docker/traefik/dynamic/tls.yml:**
```yaml
tls:
  certificates:
    - certFile: /etc/certs/localhost.crt
      keyFile: /etc/certs/localhost.key
    - certFile: /etc/certs/test.crt
      keyFile: /etc/certs/test.key
```

---

## Service Dependencies

```yaml
php:
  depends_on:
    mysql:
      condition: service_healthy
    postgres:
      condition: service_healthy
    redis:
      condition: service_healthy

nginx:
  depends_on:
    - php

minio-setup:
  depends_on:
    minio:
      condition: service_healthy
```

### Startup Order

1. **Phase 1:** Database services start
   - MySQL, PostgreSQL, Redis
   - Wait for health checks

2. **Phase 2:** PHP-FPM starts
   - Depends on healthy databases

3. **Phase 3:** Web layer starts
   - Nginx (depends on PHP)
   - Traefik (independent)

4. **Phase 4:** Support services
   - MinIO, Mailpit (independent)
   - MinIO-setup (after MinIO healthy)

---

## Xdebug Integration

### Architecture

```
IDE (PhpStorm/VS Code)    PHP-FPM Container
      ↑                         │
      │    Port 9003            │
      └─────────────────────────┘
          host.docker.internal
```

### Configuration

```ini
xdebug.mode = develop,debug
xdebug.start_with_request = yes
xdebug.client_host = host.docker.internal
xdebug.client_port = 9003
```

### Path Mapping

Container path → Local path:
- `/var/www/blog` → `~/projects/blog`

---

## Performance Optimizations

### Volume Caching

```yaml
volumes:
  - ${PROJECTS_PATH}:/var/www:cached
```

The `:cached` flag optimizes for read-heavy workloads.

### OPcache

**php/php.ini:**
```ini
opcache.enable = 1
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 16
opcache.max_accelerated_files = 20000
opcache.validate_timestamps = 1
opcache.revalidate_freq = 0
```

### Redis I/O Threads

**redis/redis.conf:**
```conf
io-threads 4
io-threads-do-reads yes
```

---

## Security Considerations

### Non-Root User

PHP container runs as non-root:

```dockerfile
RUN addgroup -g ${GID} laravel && \
    adduser -D -u ${UID} -G laravel laravel
USER laravel
```

### Network Isolation

Services only exposed as needed:
- PHP-FPM: Internal only
- Nginx: Internal only (accessed via Traefik)

### Docker Socket

Traefik accesses Docker socket read-only:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

---

## Extensibility

### Adding New Services

1. Create a `docker-compose.override.yml` in `~/.config/docker-local/`
2. Add your service definition
3. Add Traefik labels for routing
4. Join `laravel-dev` network
5. Add health check

The override file will be automatically merged with the base configuration.

### Example: Adding Elasticsearch

Create `~/.config/docker-local/docker-compose.override.yml`:

```yaml
services:
  elasticsearch:
    image: elasticsearch:8.11.0
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
    volumes:
      - elasticsearch_data:/usr/share/elasticsearch/data
    networks:
      - laravel-dev
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9200/_cluster/health"]
      interval: 30s
      timeout: 10s
      retries: 5

volumes:
  elasticsearch_data:
```

Then restart the environment:
```bash
docker-local restart
```
