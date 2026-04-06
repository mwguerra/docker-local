# Ollama AI Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an Ollama local LLM inference server as a service in docker-local with CLI management commands.

**Architecture:** Single container using official `ollama/ollama:latest` image, CPU-only mode, auto-pulling 3 models on first start. Named Docker volume for model persistence. Traefik route at `ollama.localhost`. CLI commands follow the LiveKit pattern.

**Tech Stack:** Docker Compose, Bash (CLI), Traefik labels, Ollama API

**Spec:** `docs/superpowers/specs/2026-04-05-ollama-service-design.md`

---

### Task 1: Add Ollama service to docker-compose files

**Files:**
- Modify: `docker-compose.yml` (root) — insert service before `volumes:` block, add volume
- Modify: `resources/docker/docker-compose.yml` — identical changes

- [ ] **Step 1: Add Ollama service to root `docker-compose.yml`**

Insert the ollama service block before the `volumes:` section (before line 505 in `docker-compose.yml`). Add after the LiveKit service block (after line 503):

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

Add the volume in the `volumes:` block:

```yaml
  ollama_data:
    name: laravel-dev-ollama
```

- [ ] **Step 2: Add identical Ollama service to `resources/docker/docker-compose.yml`**

**Important:** This file does NOT have LiveKit/Whisper/RTMP services — its last service is `reverb` (ending at line 345). Insert the ollama service block after the reverb service (after line 345), before the `volumes:` section (line 347). Add the `ollama_data` volume entry in the `volumes:` block.

- [ ] **Step 3: Verify YAML syntax**

Run: `docker compose -f docker-compose.yml config --quiet`
Expected: No output (valid YAML)

Run: `docker compose -f resources/docker/docker-compose.yml config --quiet`
Expected: No output (valid YAML)

- [ ] **Step 4: Commit**

```bash
git add docker-compose.yml resources/docker/docker-compose.yml
git commit -m "feat: add Ollama AI server to docker-compose"
```

---

### Task 2: Add Ollama configuration loading

**Files:**
- Modify: `lib/config.sh:237` — add Ollama port export after LiveKit settings
- Modify: `stubs/config.json.stub:45` — add ollama section before closing brace

- [ ] **Step 1: Add Ollama env export to `lib/config.sh`**

After the LiveKit settings block (after line 237, before the user settings comment), add:

```bash
    # Load Ollama settings
    export OLLAMA_PORT=$(get_nested_config "ollama.port" "11434")
```

- [ ] **Step 2: Add Ollama section to `stubs/config.json.stub`**

Replace lines 44-46 (the closing `}` of the reverb block through the file's closing `}`) to add the ollama section:

Replace:
```json
  }
}
```

With:
```json
  },
  "ollama": {
    "port": 11434
  }
}
```

- [ ] **Step 3: Add Ollama to `stubs/laravel.env.stub`**

After the Whisper section (after line 147), add:

```env

# ==============================================================================
# Optional: Ollama - Local AI/LLM Inference Server
# ==============================================================================
OLLAMA_BASE_URL=http://ollama:11434
```

- [ ] **Step 4: Commit**

```bash
git add lib/config.sh stubs/config.json.stub stubs/laravel.env.stub
git commit -m "feat: add Ollama configuration and env stubs"
```

---

### Task 3: Add Ollama to container and port lists in CLI

**Files:**
- Modify: `bin/docker-local:412-426` — add ollama to services port array
- Modify: `bin/docker-local:440` — add "ollama" to containers array

- [ ] **Step 1: Add Ollama port to `check_init_conflicts()` services array**

In `bin/docker-local`, in the `check_init_conflicts()` function, add after the `"livekit:${livekit_rtc_port}:LiveKit RTC"` entry (line 425):

```bash
        "ollama:${OLLAMA_PORT:-11434}:Ollama API"
```

- [ ] **Step 2: Add "ollama" to containers array**

On line 440, add `"ollama"` to the containers array:

```bash
    local containers=("traefik" "mysql" "postgres" "redis" "minio" "minio-setup" "mailpit" "nginx" "php" "reverb" "livekit" "node" "whisper" "rtmp" "ollama")
```

- [ ] **Step 3: Commit**

```bash
git add bin/docker-local
git commit -m "feat: add Ollama to port checks and container list"
```

---

### Task 4: Add Ollama CLI commands

**Files:**
- Modify: `bin/docker-local` — add 5 functions after the LiveKit section (~line 1960), add help text (~line 190), add command routing (~line 5687), add open flag (~line 956), add shell completion (~line 2867)

- [ ] **Step 1: Add Ollama command functions**

Insert after the LiveKit token function (after the `cmd_livekit_token` function ends, around line 1980). Add a section comment and all 5 functions:

```bash
# ==============================================================================
# Ollama AI Server Management
# ==============================================================================

cmd_ollama() {
    local subcommand="${1:-}"
    shift 2>/dev/null || true

    case "$subcommand" in
        ""|help)
            echo ""
            echo -e "${WHITE}Ollama AI Server (Local LLM Inference)${NC}"
            echo ""
            echo "Commands:"
            echo "  ${CYAN}ollama status${NC}              - Show server status and loaded models"
            echo "  ${CYAN}ollama restart${NC}             - Restart server"
            echo "  ${CYAN}ollama logs${NC}                - View server logs"
            echo "  ${CYAN}ollama pull <model>${NC}        - Pull/update a model"
            echo "  ${CYAN}ollama models${NC}              - List available models"
            echo ""
            echo "Configuration:"
            echo "  Port: ${OLLAMA_PORT:-11434}"
            echo "  Mode: CPU-only"
            echo ""
            echo "URLs:"
            echo "  * https://ollama.localhost     - Ollama API (via Traefik)"
            echo "  * http://localhost:${OLLAMA_PORT:-11434}         - Ollama API (direct)"
            echo ""
            ;;
        status)
            cmd_ollama_status
            ;;
        restart)
            cmd_ollama_restart
            ;;
        logs)
            docker logs -f ollama
            ;;
        pull)
            cmd_ollama_pull "$@"
            ;;
        models)
            cmd_ollama_models
            ;;
        *)
            echo -e "${RED}Unknown command: $subcommand${NC}"
            echo "Run 'docker-local ollama' for help"
            exit 1
            ;;
    esac
}

cmd_ollama_status() {
    echo ""
    echo -e "${WHITE}Ollama AI Server Status${NC}"
    echo ""

    # Check container status
    printf "  Server: "
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^ollama$"; then
        local health=$(docker inspect --format='{{.State.Health.Status}}' ollama 2>/dev/null || echo "unknown")
        if [ "$health" = "healthy" ]; then
            echo -e "${GREEN}● Running (healthy)${NC}"
        elif [ "$health" = "starting" ]; then
            echo -e "${YELLOW}● Starting${NC}"
        else
            echo -e "${GREEN}● Running${NC}"
        fi
    else
        echo -e "${RED}○ Stopped${NC}"
        echo ""
        echo -e "Start with: ${CYAN}docker-local up${NC}"
        return 1
    fi

    # Test connectivity
    printf "  API:    "
    if timeout 2 bash -c "</dev/tcp/127.0.0.1/${OLLAMA_PORT:-11434}" 2>/dev/null; then
        echo -e "${GREEN}✓ Accessible${NC} (localhost:${OLLAMA_PORT:-11434})"
    else
        echo -e "${YELLOW}○ Not accessible${NC}"
    fi

    # Show models
    echo ""
    echo -e "${WHITE}Models:${NC}"
    docker exec ollama ollama list 2>/dev/null || echo "  (no models loaded yet)"

    # Show URLs
    echo ""
    echo -e "${WHITE}URLs:${NC}"
    echo "  * https://ollama.localhost     - Via Traefik (HTTPS)"
    echo "  * http://localhost:${OLLAMA_PORT:-11434}         - Direct access"

    # Show .env configuration hints
    echo ""
    echo -e "${WHITE}Laravel .env Configuration:${NC}"
    echo "  OLLAMA_BASE_URL=http://ollama:11434"
    echo ""
}

cmd_ollama_restart() {
    echo -e "${BLUE}Restarting Ollama server...${NC}"
    docker restart ollama > /dev/null 2>&1

    # Wait for healthy
    echo -n "  Waiting for server..."
    local attempts=0
    while [ $attempts -lt 30 ]; do
        if timeout 2 bash -c "</dev/tcp/127.0.0.1/${OLLAMA_PORT:-11434}" 2>/dev/null; then
            echo -e " ${GREEN}✓${NC}"
            echo -e "${GREEN}✓ Ollama restarted${NC}"
            return 0
        fi
        echo -n "."
        sleep 2
        ((attempts++))
    done
    echo -e " ${RED}✗${NC}"
    echo -e "${RED}✗ Timeout waiting for Ollama${NC}"
    return 1
}

cmd_ollama_pull() {
    local model_name="${1:-}"

    if [ -z "$model_name" ]; then
        echo -e "${RED}Error: Model name is required${NC}"
        echo ""
        echo "Usage: docker-local ollama pull <model-name>"
        echo ""
        echo "Examples:"
        echo "  docker-local ollama pull mistral"
        echo "  docker-local ollama pull codellama:7b"
        echo "  docker-local ollama pull phi3"
        return 1
    fi

    echo -e "${BLUE}Pulling model: $model_name${NC}"
    docker exec -it ollama ollama pull "$model_name"
}

cmd_ollama_models() {
    if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^ollama$"; then
        echo -e "${RED}Ollama is not running${NC}"
        echo -e "Start with: ${CYAN}docker-local up${NC}"
        return 1
    fi

    echo ""
    echo -e "${WHITE}Ollama Models:${NC}"
    echo ""
    docker exec ollama ollama list
    echo ""
}
```

- [ ] **Step 2: Add Ollama to `show_help()` output**

In `bin/docker-local`, after the LiveKit Commands block (after line 189, before the "Other Commands" section), add:

```bash
    echo -e "${WHITE}Ollama Commands:${NC}"
    echo -e "  ${GREEN}ollama${NC}                Manage Ollama AI server"
    echo -e "  ${GREEN}ollama status${NC}         Show server status and models"
    echo -e "  ${GREEN}ollama pull${NC} <model>   Pull/update a model"
    echo -e "  ${GREEN}ollama models${NC}         List available models"
    echo ""
```

- [ ] **Step 3: Add `--ollama` flag to `cmd_open()`**

In `bin/docker-local`, in `cmd_open()`, after the `--livekit|livekit)` case (after line 956), add:

```bash
        --ollama|ollama)
            url="https://ollama.localhost"
            echo -e "${BLUE}Opening Ollama API...${NC}"
            ;;
```

Also update the usage string (line 966) to include `--ollama`:
```bash
                echo -e "Usage: docker-local open [project-name|--mail|--minio|--traefik|--livekit|--ollama]"
```

- [ ] **Step 4: Add command routing to main case block**

In `bin/docker-local`, after the LiveKit routing (after line 5687), add:

```bash

    # Ollama
    ollama) shift; cmd_ollama "$@" ;;
    ollama:status) cmd_ollama_status ;;
    ollama:restart) cmd_ollama_restart ;;
    ollama:pull) shift; cmd_ollama_pull "$@" ;;
    ollama:models) cmd_ollama_models ;;
```

- [ ] **Step 5: Add Ollama to shell completion**

In `bin/docker-local`, on line 2862, add `ollama ollama:status ollama:restart ollama:pull ollama:models` to the `commands` string.

On line 2867, add `--ollama` to the open completions:
```bash
            COMPREPLY=($(compgen -W "$projects --mail --minio --traefik --livekit --ollama" -- "$cur"))
```

- [ ] **Step 6: Commit**

```bash
git add bin/docker-local
git commit -m "feat: add Ollama CLI commands and help text"
```

---

### Task 5: Manual verification

No automated tests exist for the CLI (it's a bash script). Verify manually.

- [ ] **Step 1: Verify CLI help shows Ollama**

Run: `docker-local help`
Expected: "Ollama Commands:" section visible in output

- [ ] **Step 2: Verify `docker-local ollama` shows help**

Run: `docker-local ollama`
Expected: Help output with commands, config, and URLs

- [ ] **Step 3: Verify docker-compose config is valid**

Run: `docker compose -f docker-compose.yml config --services`
Expected: `ollama` appears in the service list

- [ ] **Step 4: Start Ollama and verify health**

Run: `docker-local up` (or `docker compose up -d ollama` if env is already running)
Wait for healthy, then run: `docker-local ollama status`
Expected: Server running, API accessible

- [ ] **Step 5: Verify model auto-pull (check logs)**

Run: `docker-local ollama logs` (or `docker logs ollama`)
Expected: Logs show "Ollama server ready, pulling models..." and pull progress for the 3 models

- [ ] **Step 6: Verify `ollama models` lists pulled models**

Run: `docker-local ollama models`
Expected: Table showing nomic-embed-text, llama3.2:3b, llava (once pulls complete)

- [ ] **Step 7: Verify Traefik route**

Run: `curl -sk https://ollama.localhost/api/tags`
Expected: JSON response with model list

- [ ] **Step 8: Verify Docker network access**

Run: `docker exec php curl -s http://ollama:11434/api/tags`
Expected: JSON response (confirms PHP container can reach Ollama)
