# Ollama AI Server Service Design

## Overview

Add an Ollama inference server to docker-local, providing CPU-only local LLM capabilities for Laravel projects. The service auto-pulls three required models on first start and runs as an always-on service (consistent with all other services in the project).

## Required Models

| Model | Size | Purpose | RAM Usage |
|-------|------|---------|-----------|
| nomic-embed-text | ~275MB | Embeddings (768 dims) | ~300MB |
| llama3.2:3b | ~2GB | Text generation (markdown, summaries, chat) | ~2.5GB |
| llava | ~4.7GB | Vision (image/chart/table description) | ~5GB |

## Architecture

### Approach: Single Container with Entrypoint Script

One `ollama` service using the official `ollama/ollama:latest` image. A custom entrypoint starts the Ollama server daemon, waits for readiness via a polling loop, then pulls missing models in the background. Models persist in a named Docker volume.

### Why This Approach

- Mirrors existing patterns (Whisper uses official image + volume for cache)
- Single container to manage, no build step needed
- Official image stays updatable with `docker pull`
- First-boot model download (~7GB) is a one-time cost
- Alternatives considered and rejected:
  - Two containers (server + init): unnecessary complexity for a straightforward service
  - Baked-in models: ~7GB+ image, painful rebuilds on model updates

### No Docker Profiles

The project does not use Docker profiles for any existing service. Introducing profiles would require changes to `cmd_up`, `cmd_down`, and `cmd_status` to handle profiled services. To stay consistent, Ollama runs as an always-on service like LiveKit, Whisper, RTMP, and all other optional-in-practice services.

## Docker Compose Service

Added to both `docker-compose.yml` (root working copy) and `resources/docker/docker-compose.yml` (template). Both files get identical changes.

```yaml
# ============================================================================
# Ollama - Local AI/LLM Inference Server (CPU-only)
# API: http://ollama:11434 (internal) / http://localhost:11434 (external)
# Models auto-pulled on first start: nomic-embed-text, llama3.2:3b, llava
# Documentation: https://github.com/ollama/ollama
# ============================================================================
ollama:
  image: ollama/ollama:latest
  container_name: ollama
  restart: unless-stopped
  ports:
    - "${OLLAMA_PORT:-11434}:11434"
  environment:
    OLLAMA_HOST: "0.0.0.0"
    OLLAMA_NUM_PARALLEL: "1"
    OLLAMA_MAX_LOADED_MODELS: "1"
  volumes:
    - ollama_data:/root/.ollama
  networks:
    - laravel-dev
  entrypoint: ["/bin/sh", "-c"]
  command:
    - |
      ollama serve &
      until ollama list >/dev/null 2>&1; do sleep 1; done
      echo 'Ollama server ready, pulling models...'
      for model in nomic-embed-text llama3.2:3b llava; do
        echo "Pulling $$model..."
        ollama pull "$$model"
      done
      echo 'All models pulled.'
      wait
  healthcheck:
    test: ["CMD", "ollama", "list"]
    interval: 15s
    timeout: 10s
    retries: 5
    start_period: 30s
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.ollama.rule=Host(`ollama.localhost`)"
    - "traefik.http.routers.ollama.entrypoints=websecure"
    - "traefik.http.routers.ollama.tls=true"
    - "traefik.http.services.ollama.loadbalancer.server.port=11434"
```

### Volume

```yaml
ollama_data:
  name: laravel-dev-ollama
```

### Key Design Decisions

- **`OLLAMA_HOST=0.0.0.0`** — Listen on all interfaces (required for Docker networking)
- **`OLLAMA_NUM_PARALLEL=1`** — CPU-only: process one request at a time to avoid thrashing
- **`OLLAMA_MAX_LOADED_MODELS=1`** — CPU-only: keep only one model in memory, swap as needed
- **Readiness loop** (`until ollama list`) replaces fragile `sleep 5` — polls the server until it accepts connections before pulling models
- **Health check uses `ollama list`** — No dependency on `curl` being in the image; validates server is functional, not just listening
- **`$$model` in command** — Double `$` escapes the shell variable in docker-compose YAML
- **No `OLLAMA_MODELS` env var** — The volume mounts to `/root/.ollama` which already contains the default models directory; setting it explicitly is redundant

## CLI Commands

Added to `bin/docker-local`, following the LiveKit pattern.

### Command Table

| Command | Function | Description |
|---------|----------|-------------|
| `docker-local ollama` | `cmd_ollama()` | Help, config, URLs |
| `docker-local ollama status` | `cmd_ollama_status()` | Server health, loaded models |
| `docker-local ollama restart` | `cmd_ollama_restart()` | Restart server, wait for healthy |
| `docker-local ollama logs` | inline | `docker logs -f ollama` |
| `docker-local ollama pull <model>` | `cmd_ollama_pull()` | Pull a model via `docker exec ollama ollama pull <model>` |
| `docker-local ollama models` | `cmd_ollama_models()` | List models via `docker exec ollama ollama list` |

Both subcommand style (`docker-local ollama status`) and colon style (`docker-local ollama:status`) work, matching the LiveKit pattern.

### Help Output

```
Ollama AI Server (Local LLM Inference)

Commands:
  ollama status              - Show server status and loaded models
  ollama restart             - Restart server
  ollama logs                - View server logs
  ollama pull <model>        - Pull/update a model
  ollama models              - List available models

Configuration:
  Port: 11434
  Mode: CPU-only

URLs:
  * https://ollama.localhost  - Ollama API (via Traefik)
  * http://localhost:11434    - Ollama API (direct)
```

### Status Output

```
Ollama AI Server Status

  Server: [green] Running (healthy)
  API:    [green] Accessible (localhost:11434)

Models:
  NAME                SIZE     MODIFIED
  nomic-embed-text    275MB    2 hours ago
  llama3.2:3b         2.0GB    2 hours ago
  llava               4.7GB    2 hours ago

URLs:
  * https://ollama.localhost   - Via Traefik (HTTPS)
  * http://localhost:11434     - Direct access

Laravel .env Configuration:
  OLLAMA_BASE_URL=http://ollama:11434
```

### Command Routing (main case block)

```bash
# Ollama
ollama) shift; cmd_ollama "$@" ;;
ollama:status) cmd_ollama_status ;;
ollama:restart) cmd_ollama_restart ;;
ollama:pull) shift; cmd_ollama_pull "$@" ;;
ollama:models) cmd_ollama_models ;;
```

### show_help() Addition

```bash
echo -e "${WHITE}Ollama Commands:${NC}"
echo -e "  ${GREEN}ollama${NC}                Manage Ollama AI server"
```

### open Command

Add `--ollama` flag to `cmd_open()`:
```bash
--ollama|ollama)
    echo -e "${BLUE}Opening Ollama API...${NC}"
    open_browser "https://ollama.localhost"
    ;;
```

## Configuration

### stubs/config.json.stub

```json
"ollama": {
  "port": 11434
}
```

Note: The models list is intentionally hardcoded in the entrypoint rather than driven by config. The default models are a fixed set needed for the document processing pipeline. Users who want additional models use `docker-local ollama pull <model>`. The config stub is already incomplete (missing livekit, whisper sections) — this follows the same pattern where `lib/config.sh` provides defaults.

### lib/config.sh load_env()

```bash
# Load Ollama settings
export OLLAMA_PORT=$(get_nested_config "ollama.port" "11434")
```

Note: `load_env()` is called early in `bin/docker-local` before any command dispatch, so `OLLAMA_PORT` is available to all ollama commands.

### stubs/laravel.env.stub

Add to the services section:

```env
# Ollama - Local AI/LLM
OLLAMA_BASE_URL=http://ollama:11434
```

## Integration Points

### Network Connectivity

- **PHP container -> Ollama:** `http://ollama:11434` via Docker `laravel-dev` network
- **Host -> Ollama:** `http://localhost:11434` (direct port) or `https://ollama.localhost` (Traefik)
- **Queue workers** (running on host): Use `http://localhost:11434` or `https://ollama.localhost`

### Port Checking

Add `11434` to the port list in `cmd_ports()`. The `cmd_doctor()` function does not currently check LiveKit, Whisper, or other newer services, so adding Ollama to doctor is out of scope.

### Container List

Add `"ollama"` to the containers array in status/clean functions (line ~440 in `bin/docker-local`).

### SSL

No changes needed. `ollama.localhost` is covered by the existing `*.localhost` wildcard certificate.

## Files Modified

1. **`docker-compose.yml`** (root working copy) — Add ollama service + volume
2. **`resources/docker/docker-compose.yml`** (template) — Add ollama service + volume (identical changes)
3. **`bin/docker-local`** — Add CLI commands (`cmd_ollama`, `cmd_ollama_status`, `cmd_ollama_restart`, `cmd_ollama_pull`, `cmd_ollama_models`), help text, open flag, port check entry, container list entry
4. **`lib/config.sh`** — Add Ollama env export in `load_env()`
5. **`stubs/config.json.stub`** — Add ollama config section
6. **`stubs/laravel.env.stub`** — Add `OLLAMA_BASE_URL`

## Testing

- `docker-local ollama`: should show help with config and URLs
- `docker-local ollama status`: should show running/healthy status and model list
- `docker-local ollama restart`: should restart and wait for healthy
- `docker-local ollama models`: should list pulled models
- `docker-local ollama pull mistral`: should pull a new model
- From PHP container: `docker exec php curl http://ollama:11434/api/tags` should respond
- From host: `curl http://localhost:11434/api/tags` should respond
- `https://ollama.localhost` should route through Traefik with valid SSL
