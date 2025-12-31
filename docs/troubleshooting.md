# Troubleshooting

Common issues and solutions for the Laravel Docker Development Environment.

## Diagnostic Commands

Before troubleshooting, run these commands:

```bash
# Full system health check
docker-local doctor

# Service status
docker-local status

# View logs
docker-local logs

# Check project configuration
docker-local env:check

# Check all projects for conflicts
docker-local env:check --all
```

---

## Installation Issues

### Docker Not Running

**Error:**
```
Error: Docker is not running
```

**Solution:**
```bash
# Start Docker daemon
sudo systemctl start docker

# Or on macOS/Windows, start Docker Desktop
```

### Permission Denied on Docker Socket

**Error:**
```
Got permission denied while trying to connect to the Docker daemon socket
```

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or run:
newgrp docker
```

### mkcert Not Installed

**Error:**
```
mkcert: command not found
```

**Solution:**
```bash
# Ubuntu/Debian
sudo apt install mkcert

# macOS
brew install mkcert

# Arch
sudo pacman -S mkcert

# Install CA
mkcert -install
```

---

## Container Issues

### Container Won't Start

**Check logs:**
```bash
docker-local logs <container>
```

**Common causes:**

1. **Port conflict:**
   ```bash
   # Check what's using the port
   sudo lsof -i :3306
   sudo lsof -i :80

   # Stop conflicting service
   sudo systemctl stop mysql
   sudo systemctl stop apache2
   ```

2. **Volume permission issues:**
   ```bash
   # Fix permissions
   sudo chown -R $(id -u):$(id -g) ~/projects
   ```

### PHP Container Keeps Restarting

**Check health of dependencies:**
```bash
docker-local status
docker-local logs php
docker-local logs mysql
```

PHP waits for MySQL, PostgreSQL, and Redis to be healthy. If any fails, PHP won't start.

### MySQL Fails to Start

**Check logs:**
```bash
docker-local logs mysql
```

**Common fixes:**

1. **Corrupted data volume:**
   ```bash
   # WARNING: This deletes all MySQL data
   docker volume rm laravel-dev-mysql
   docker-local up
   ```

2. **InnoDB recovery:**
   ```bash
   # Add to mysql/my.cnf temporarily
   innodb_force_recovery = 1
   ```

---

## DNS and Domain Issues

### *.test Domains Not Resolving

**Symptoms:**
- `curl: (6) Could not resolve host: myproject.test`
- Browser shows "Site can't be reached"

**Solution 1: Use dnsmasq (recommended)**
```bash
sudo docker-local setup:dns
```

**Solution 2: Manual /etc/hosts**
```bash
sudo docker-local setup:hosts

# Add entries manually
echo "127.0.0.1 myproject.test" | sudo tee -a /etc/hosts
```

**Solution 3: Use .localhost instead**
- Access via `https://myproject.localhost` (works without DNS config)

### SSL Certificate Not Trusted

**Symptoms:**
- Browser shows "Your connection is not private"
- `NET::ERR_CERT_AUTHORITY_INVALID`

**Solution:**
```bash
# Reinstall mkcert CA
mkcert -install

# Regenerate certificates
./scripts/generate-certs.sh

# Restart Traefik
docker-local restart
```

---

## Database Issues

### Cannot Connect to MySQL

**From Laravel:**
```
SQLSTATE[HY000] [2002] Connection refused
```

**Check connection:**
```bash
docker-local db:mysql
```

**Verify .env configuration:**
```env
DB_CONNECTION=mysql
DB_HOST=mysql          # Container name, not localhost
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret
```

### Cannot Connect to PostgreSQL

**Check connection:**
```bash
docker-local db:postgres
```

**Verify .env:**
```env
DB_CONNECTION=pgsql
DB_HOST=postgres       # Container name
DB_PORT=5432
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret
```

### Redis Connection Refused

**Check connection:**
```bash
docker-local db:redis
```

**Verify .env:**
```env
REDIS_HOST=redis       # Container name
REDIS_PASSWORD=null
REDIS_PORT=6379
```

### Local PHP Can't Connect to Services

When using local PHP (not Docker), services need to be accessible by hostname.

**Run:**
```bash
sudo docker-local setup:hosts
```

This adds to `/etc/hosts`:
```
127.0.0.1 mysql postgres redis minio mailpit
```

---

## Permission Issues

### Storage Not Writable

**Error:**
```
The stream or file "storage/logs/laravel.log" could not be opened
```

**Solution:**
```bash
cd ~/projects/myproject
chmod -R 775 storage bootstrap/cache
```

### Composer Cache Issues

**Error:**
```
Cannot create cache directory
```

**Solution:**
```bash
# Fix Composer cache permissions
sudo chown -R $(id -u):$(id -g) ~/.composer
```

### Docker Volume Permissions

**Solution:**
```bash
# Set correct UID/GID in .env
echo "UID=$(id -u)" >> ~/docker-environment/.env
echo "GID=$(id -g)" >> ~/docker-environment/.env

# Rebuild PHP container
docker-local down
docker compose build php
docker-local up
```

---

## Performance Issues

### Slow File Operations (macOS)

**Symptom:** Extremely slow page loads on macOS.

**Solution:** Volumes use `:cached` flag by default. If still slow:

```yaml
# docker-compose.override.yml
services:
  php:
    volumes:
      - ${PROJECTS_PATH}:/var/www:delegated
```

### High Memory Usage

**Check container stats:**
```bash
docker stats
```

**Reduce memory:**
```bash
# Disable Xdebug when not debugging
docker-local xdebug off

# Limit Redis memory
# Edit redis/redis.conf
maxmemory 128mb
```

### Xdebug Slows Everything

**Solution:**
```bash
# Disable when not debugging
docker-local xdebug off
```

---

## Multi-Project Conflicts

### Cache Conflicts

**Symptoms:**
- One project shows data from another
- Weird session behavior

**Check:**
```bash
docker-local env:check --all
```

**Solution:**
Ensure unique `CACHE_PREFIX` in each project:
```env
# Project A
CACHE_PREFIX=projecta_cache_

# Project B
CACHE_PREFIX=projectb_cache_
```

### WebSocket Conflicts

**Solution:**
Each project needs unique Reverb IDs:
```env
# Project A
REVERB_APP_ID=123456
REVERB_APP_KEY=<unique-key-a>

# Project B
REVERB_APP_ID=789012
REVERB_APP_KEY=<unique-key-b>
```

---

## Xdebug Issues

### Xdebug Not Connecting

**Check status:**
```bash
docker-local xdebug status
```

**Verify configuration:**

1. **Port 9003** is not blocked by firewall
2. **IDE is listening** on port 9003
3. **Path mappings** are correct:
   - Container: `/var/www/myproject`
   - Local: `~/projects/myproject`

### Xdebug Works But Breakpoints Don't Hit

**PhpStorm:**
1. Settings → PHP → Servers
2. Add server: `docker` with host `localhost`
3. Map `/var/www/project` → `~/projects/project`

**VS Code:**
```json
{
  "version": "0.2.0",
  "configurations": [{
    "name": "Listen for Xdebug",
    "type": "php",
    "request": "launch",
    "port": 9003,
    "pathMappings": {
      "/var/www/myproject": "${workspaceFolder}"
    }
  }]
}
```

---

## MinIO/S3 Issues

### S3 Upload Fails

**Error:**
```
Error executing "PutObject"
```

**Check MinIO status:**
```bash
docker-local logs minio
docker-local open --minio
```

**Verify .env:**
```env
AWS_ENDPOINT=http://minio:9000          # From container
AWS_USE_PATH_STYLE_ENDPOINT=true        # Required for MinIO
```

### Public URLs Don't Work

**For public file access:**
```env
AWS_URL=http://localhost:9000/laravel   # For browser access
```

---

## Email Issues

### Emails Not Appearing in Mailpit

**Check configuration:**
```env
MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
```

**View Mailpit:**
```bash
docker-local open --mail
# or visit https://mail.localhost
```

### SMTP Connection Refused

**Verify Mailpit is running:**
```bash
docker-local status
docker-local logs mailpit
```

---

## Clean Restart

If all else fails, do a complete reset:

```bash
# Stop everything
docker-local down

# Remove all containers and volumes (WARNING: loses data)
docker-local clean --all

# Remove and recreate volumes
docker volume rm laravel-dev-mysql laravel-dev-postgres laravel-dev-redis

# Start fresh
docker-local init
```

---

## Getting Help

### Collect Diagnostic Info

```bash
# System info
docker-local doctor > doctor-output.txt
docker-local config >> doctor-output.txt

# Logs
docker-local logs > logs-output.txt 2>&1

# Container status
docker ps -a > containers.txt
docker volume ls > volumes.txt
```

### Check Documentation

- [Getting Started](getting-started.md)
- [CLI Reference](cli-reference.md)
- [Services](services.md)
- [Architecture](architecture.md)
