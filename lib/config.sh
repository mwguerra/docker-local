#!/bin/bash
# ==============================================================================
# Configuration Helper for docker-local
# Provides consistent configuration loading for all bash scripts
# ==============================================================================

# Get the directory where this script is located
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(cd "$LIB_DIR/.." && pwd)"

# ==============================================================================
# Platform Detection
# ==============================================================================

# Detect the current platform
detect_platform() {
    case "$(uname -s)" in
        Linux*)
            # Check if running in WSL
            if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        Darwin*)
            echo "macos"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "windows-git-bash"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

PLATFORM="$(detect_platform)"

# Check if we're on a supported platform
check_platform() {
    case "$PLATFORM" in
        linux|macos|wsl)
            return 0
            ;;
        windows-git-bash)
            print_warning "Running in Git Bash on Windows."
            print_warning "For best experience, use WSL2 instead."
            print_info "See: https://docs.microsoft.com/en-us/windows/wsl/install"
            return 0
            ;;
        *)
            print_error "Unsupported platform: $PLATFORM"
            print_error "docker-local requires Linux, macOS, or Windows with WSL2."
            return 1
            ;;
    esac
}

# Configuration directory (XDG compliant)
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/docker-local"
CONFIG_FILE="$CONFIG_DIR/config.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m' # No Color

# ==============================================================================
# Configuration Functions
# ==============================================================================

# Check if jq is available, fall back to PHP if not
has_jq() {
    command -v jq &> /dev/null
}

# Get a configuration value
# Usage: get_config "key" "default_value"
get_config() {
    local key="$1"
    local default="$2"

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "$default"
        return
    fi

    local value
    if has_jq; then
        # Use jq for JSON parsing
        value=$(jq -r ".$key // empty" "$CONFIG_FILE" 2>/dev/null)
    else
        # Fall back to PHP cli-helper
        value=$(php "$PACKAGE_DIR/src/cli-helper.php" get "$key" 2>/dev/null)
    fi

    # Expand tilde in paths
    if [ -n "$value" ] && [ "$value" != "null" ]; then
        echo "${value/#\~/$HOME}"
    else
        echo "$default"
    fi
}

# Get nested configuration value (using dot notation)
# Usage: get_nested_config "mysql.port" "3306"
get_nested_config() {
    local key="$1"
    local default="$2"

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "$default"
        return
    fi

    local value
    if has_jq; then
        # Convert dot notation to jq path
        local jq_path
        jq_path=$(echo ".$key" | sed 's/\././g')
        value=$(jq -r "$jq_path // empty" "$CONFIG_FILE" 2>/dev/null)
    else
        # Fall back to PHP cli-helper
        value=$(php "$PACKAGE_DIR/src/cli-helper.php" get "$key" 2>/dev/null)
    fi

    if [ -n "$value" ] && [ "$value" != "null" ]; then
        echo "${value/#\~/$HOME}"
    else
        echo "$default"
    fi
}

# Check if configuration file exists
config_exists() {
    [ -f "$CONFIG_FILE" ]
}

# Check if docker-local is initialized
is_initialized() {
    [ -f "$CONFIG_FILE" ] && [ -d "$CONFIG_DIR" ]
}

# ==============================================================================
# Path Resolution
# ==============================================================================

# Get projects directory
get_projects_dir() {
    get_config "projects_path" "$HOME/projects"
}

# Get docker files directory (user overrides)
get_docker_files_dir() {
    get_config "docker_files_path" "$CONFIG_DIR"
}

# Resolve a docker file path (user override or package default)
# Usage: resolve_docker_file "docker-compose.yml"
resolve_docker_file() {
    local relative_path="$1"
    local user_path="$(get_docker_files_dir)/$relative_path"
    local package_path="$PACKAGE_DIR/resources/docker/$relative_path"

    if [ -f "$user_path" ]; then
        echo "$user_path"
    else
        echo "$package_path"
    fi
}

# ==============================================================================
# Environment Variables
# ==============================================================================

# Export common paths as environment variables
export_paths() {
    export DOCKER_LOCAL_PACKAGE_DIR="$PACKAGE_DIR"
    export DOCKER_LOCAL_CONFIG_DIR="$CONFIG_DIR"
    export PROJECTS_PATH="$(get_projects_dir)"
    export DOCKER_FILES_PATH="$(get_docker_files_dir)"
}

# Load environment from config
load_env() {
    # Export paths first
    export_paths

    # Load service ports
    export MYSQL_PORT=$(get_nested_config "mysql.port" "3306")
    export POSTGRES_PORT=$(get_nested_config "postgres.port" "5432")
    export REDIS_PORT=$(get_nested_config "redis.port" "6379")
    export MINIO_API_PORT=$(get_nested_config "minio.api_port" "9000")
    export MINIO_CONSOLE_PORT=$(get_nested_config "minio.console_port" "9001")
    export MAILPIT_WEB_PORT=$(get_nested_config "mailpit.web_port" "8025")
    export MAILPIT_SMTP_PORT=$(get_nested_config "mailpit.smtp_port" "1025")

    # Load MySQL settings
    export MYSQL_VERSION=$(get_nested_config "mysql.version" "9.1")
    export MYSQL_ROOT_PASSWORD=$(get_nested_config "mysql.root_password" "secret")
    export MYSQL_DATABASE=$(get_nested_config "mysql.database" "laravel")
    export MYSQL_USER=$(get_nested_config "mysql.user" "laravel")
    export MYSQL_PASSWORD=$(get_nested_config "mysql.password" "secret")

    # Load PostgreSQL settings
    export POSTGRES_DATABASE=$(get_nested_config "postgres.database" "laravel")
    export POSTGRES_USER=$(get_nested_config "postgres.user" "laravel")
    export POSTGRES_PASSWORD=$(get_nested_config "postgres.password" "secret")

    # Load MinIO settings
    export MINIO_ROOT_USER=$(get_nested_config "minio.root_user" "minio")
    export MINIO_ROOT_PASSWORD=$(get_nested_config "minio.root_password" "minio123")
    export MINIO_BUCKET=$(get_nested_config "minio.bucket" "laravel")

    # Load Xdebug settings
    export XDEBUG_ENABLED=$(get_nested_config "xdebug.enabled" "true")
    export XDEBUG_MODE=$(get_nested_config "xdebug.mode" "develop,debug")

    # Load Reverb settings
    export REVERB_PORT=$(get_nested_config "reverb.port" "8080")
    export REVERB_PROJECT_NAME=$(get_nested_config "reverb.project_name" "myapp")
    export REVERB_APP_ID=$(get_nested_config "reverb.app_id" "my-app-id")
    export REVERB_APP_KEY=$(get_nested_config "reverb.app_key" "my-app-key")
    export REVERB_APP_SECRET=$(get_nested_config "reverb.app_secret" "my-app-secret")
    export REVERB_SCALING_ENABLED=$(get_nested_config "reverb.scaling_enabled" "false")

    # Load user settings (using DOCKER_ prefix to avoid readonly UID/GID)
    export DOCKER_UID="${DOCKER_UID:-$(id -u)}"
    export DOCKER_GID="${DOCKER_GID:-$(id -g)}"
}

# ==============================================================================
# Docker Compose Helpers
# ==============================================================================

# Get docker-compose command with proper file resolution
get_docker_compose_cmd() {
    local base_compose="$(resolve_docker_file "docker-compose.yml")"
    local override_compose="$CONFIG_DIR/docker-compose.override.yml"

    local cmd="docker compose -f \"$base_compose\""

    if [ -f "$override_compose" ]; then
        cmd="$cmd -f \"$override_compose\""
    fi

    echo "$cmd"
}

# Run docker-compose with proper configuration
docker_compose() {
    load_env
    local compose_cmd="$(get_docker_compose_cmd)"
    eval "$compose_cmd $*"
}

# ==============================================================================
# Output Helpers
# ==============================================================================

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_info() {
    echo -e "${BLUE}→${NC} $1"
}

# ==============================================================================
# Validation
# ==============================================================================

# Check if required tools are available
check_requirements() {
    local missing=()

    if ! command -v docker &> /dev/null; then
        missing+=("docker")
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        missing+=("docker-compose")
    fi

    if ! command -v php &> /dev/null; then
        missing+=("php")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing[*]}"
        return 1
    fi

    return 0
}

# Check if Docker daemon is running
check_docker_running() {
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running"
        return 1
    fi
    return 0
}

# ==============================================================================
# Initialize on source
# ==============================================================================

# Automatically export paths when this script is sourced
export_paths
