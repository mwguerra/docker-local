#!/bin/bash

# =============================================================================
# Docker-Local Release Script
# =============================================================================
# This script automates the release process:
# 1. Gets the last git tag
# 2. Prompts for a new version (validates format and ensures it's higher)
# 3. Commits any uncommitted changes
# 4. Pushes to remote
# 5. Creates and pushes the new git tag
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get script directory and package root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to package root
cd "$PACKAGE_ROOT"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║           Docker-Local Release Script                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# =============================================================================
# Helper Functions
# =============================================================================

# Validate semver format (v1.0.0 or 1.0.0)
validate_version_format() {
    local version="$1"
    # Remove 'v' prefix if present for validation
    version="${version#v}"

    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?(\+[a-zA-Z0-9.]+)?$ ]]; then
        return 1
    fi
    return 0
}

# Compare two semver versions
# Returns: 0 if v1 > v2, 1 if v1 <= v2
version_greater_than() {
    local v1="$1"
    local v2="$2"

    # Remove 'v' prefix if present
    v1="${v1#v}"
    v2="${v2#v}"

    # Remove pre-release and build metadata for comparison
    v1="${v1%%-*}"
    v1="${v1%%+*}"
    v2="${v2%%-*}"
    v2="${v2%%+*}"

    # Split into major.minor.patch
    IFS='.' read -r v1_major v1_minor v1_patch <<< "$v1"
    IFS='.' read -r v2_major v2_minor v2_patch <<< "$v2"

    # Compare major
    if (( v1_major > v2_major )); then
        return 0
    elif (( v1_major < v2_major )); then
        return 1
    fi

    # Compare minor
    if (( v1_minor > v2_minor )); then
        return 0
    elif (( v1_minor < v2_minor )); then
        return 1
    fi

    # Compare patch
    if (( v1_patch > v2_patch )); then
        return 0
    fi

    return 1
}

# Suggest next version based on current version
suggest_next_version() {
    local current="$1"
    local type="${2:-patch}"

    # Remove 'v' prefix if present
    current="${current#v}"

    # Remove pre-release and build metadata
    current="${current%%-*}"
    current="${current%%+*}"

    IFS='.' read -r major minor patch <<< "$current"

    case "$type" in
        major)
            echo "v$((major + 1)).0.0"
            ;;
        minor)
            echo "v${major}.$((minor + 1)).0"
            ;;
        patch|*)
            echo "v${major}.${minor}.$((patch + 1))"
            ;;
    esac
}

# =============================================================================
# Step 1: Get Last Tag
# =============================================================================

echo -e "${BLUE}Step 1: Getting last git tag...${NC}"
echo ""

# Fetch tags from remote
git fetch --tags 2>/dev/null || true

# Get the last tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [[ -z "$LAST_TAG" ]]; then
    echo -e "${YELLOW}No existing tags found. This will be the first release.${NC}"
    LAST_TAG="v0.0.0"
    SUGGESTED_VERSION="v1.0.0"
else
    echo -e "${GREEN}Last tag: ${CYAN}$LAST_TAG${NC}"
    SUGGESTED_VERSION=$(suggest_next_version "$LAST_TAG" "patch")
fi

echo ""

# =============================================================================
# Step 2: Ask for New Version
# =============================================================================

echo -e "${BLUE}Step 2: Enter new version...${NC}"
echo ""

# Show version suggestions
SUGGEST_PATCH=$(suggest_next_version "$LAST_TAG" "patch")
SUGGEST_MINOR=$(suggest_next_version "$LAST_TAG" "minor")
SUGGEST_MAJOR=$(suggest_next_version "$LAST_TAG" "major")

echo -e "Suggested versions:"
echo -e "  ${CYAN}patch${NC}: $SUGGEST_PATCH (bug fixes)"
echo -e "  ${CYAN}minor${NC}: $SUGGEST_MINOR (new features, backwards compatible)"
echo -e "  ${CYAN}major${NC}: $SUGGEST_MAJOR (breaking changes)"
echo ""

while true; do
    read -p "Enter new version [$SUGGESTED_VERSION]: " NEW_VERSION

    # Use suggested version if empty
    if [[ -z "$NEW_VERSION" ]]; then
        NEW_VERSION="$SUGGESTED_VERSION"
    fi

    # Add 'v' prefix if not present
    if [[ ! "$NEW_VERSION" =~ ^v ]]; then
        NEW_VERSION="v$NEW_VERSION"
    fi

    # Validate format
    if ! validate_version_format "$NEW_VERSION"; then
        echo -e "${RED}Invalid version format. Please use semantic versioning (e.g., v1.2.3 or 1.2.3)${NC}"
        continue
    fi

    # Check if version is greater than last tag
    if [[ "$LAST_TAG" != "v0.0.0" ]]; then
        if ! version_greater_than "$NEW_VERSION" "$LAST_TAG"; then
            echo -e "${RED}New version ($NEW_VERSION) must be greater than last tag ($LAST_TAG)${NC}"
            continue
        fi
    fi

    # Check if tag already exists
    if git rev-parse "$NEW_VERSION" >/dev/null 2>&1; then
        echo -e "${RED}Tag $NEW_VERSION already exists. Please choose a different version.${NC}"
        continue
    fi

    break
done

echo ""
echo -e "${GREEN}✓ Version ${CYAN}$NEW_VERSION${GREEN} is valid${NC}"
echo ""

# =============================================================================
# Step 3: Check for Uncommitted Changes
# =============================================================================

echo -e "${BLUE}Step 3: Checking for uncommitted changes...${NC}"
echo ""

# Check git status
CHANGES=$(git status --porcelain)

if [[ -n "$CHANGES" ]]; then
    echo -e "${YELLOW}Uncommitted changes detected:${NC}"
    echo ""
    git status --short
    echo ""

    read -p "Do you want to commit these changes? [Y/n]: " COMMIT_CHANGES
    COMMIT_CHANGES="${COMMIT_CHANGES:-Y}"

    if [[ "$COMMIT_CHANGES" =~ ^[Yy]$ ]]; then
        # Default commit message
        DEFAULT_MSG="chore: prepare release $NEW_VERSION"
        read -p "Enter commit message [$DEFAULT_MSG]: " COMMIT_MSG
        COMMIT_MSG="${COMMIT_MSG:-$DEFAULT_MSG}"

        # Stage all changes
        git add -A

        # Commit
        git commit -m "$COMMIT_MSG"

        echo -e "${GREEN}✓ Changes committed${NC}"
    else
        echo -e "${YELLOW}Skipping commit. Uncommitted changes will not be included in the release.${NC}"
    fi
else
    echo -e "${GREEN}✓ Working directory is clean${NC}"
fi

echo ""

# =============================================================================
# Step 4: Push to Remote
# =============================================================================

echo -e "${BLUE}Step 4: Pushing to remote...${NC}"
echo ""

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# Check if we have a remote
REMOTE=$(git remote | head -n1)

if [[ -z "$REMOTE" ]]; then
    echo -e "${YELLOW}No remote configured. Skipping push.${NC}"
else
    echo -e "Pushing to ${CYAN}$REMOTE/$CURRENT_BRANCH${NC}..."
    git push "$REMOTE" "$CURRENT_BRANCH"
    echo -e "${GREEN}✓ Pushed to remote${NC}"
fi

echo ""

# =============================================================================
# Step 5: Create and Push Tag
# =============================================================================

echo -e "${BLUE}Step 5: Creating and pushing tag...${NC}"
echo ""

# Ask for tag message
DEFAULT_TAG_MSG="Release $NEW_VERSION"
read -p "Enter tag message [$DEFAULT_TAG_MSG]: " TAG_MSG
TAG_MSG="${TAG_MSG:-$DEFAULT_TAG_MSG}"

# Create annotated tag
git tag -a "$NEW_VERSION" -m "$TAG_MSG"
echo -e "${GREEN}✓ Tag ${CYAN}$NEW_VERSION${GREEN} created${NC}"

# Push tag
if [[ -n "$REMOTE" ]]; then
    echo -e "Pushing tag to ${CYAN}$REMOTE${NC}..."
    git push "$REMOTE" "$NEW_VERSION"
    echo -e "${GREEN}✓ Tag pushed to remote${NC}"
fi

echo ""

# =============================================================================
# Summary
# =============================================================================

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║           Release Complete!                               ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "  ${GREEN}✓${NC} Version: ${CYAN}$NEW_VERSION${NC}"
echo -e "  ${GREEN}✓${NC} Tag created and pushed"
echo ""

if [[ -n "$REMOTE" ]]; then
    # Try to get the repository URL
    REPO_URL=$(git remote get-url "$REMOTE" 2>/dev/null || echo "")
    if [[ "$REPO_URL" =~ github\.com ]]; then
        # Convert SSH URL to HTTPS if needed
        REPO_URL="${REPO_URL/git@github.com:/https://github.com/}"
        REPO_URL="${REPO_URL%.git}"
        echo -e "View release: ${CYAN}$REPO_URL/releases/tag/$NEW_VERSION${NC}"
    fi
fi

echo ""
