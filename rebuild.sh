#!/usr/bin/env zsh
# NixOS Rebuild & Maintenance Script
# Overhauled for stability and clean output

set -e

# --- Config ---
CONFIG_DIR="$HOME/nixos-config"
HOSTNAME="nixos"
MODE=${1:-switch} # switch, boot, test, build

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if we are in the right place
if [[ ! -d "$CONFIG_DIR" ]]; then
    echo -e "${RED}Error: $CONFIG_DIR not found.${NC}"
    exit 1
fi

cd "$CONFIG_DIR"

echo -e "${BLUE}=== 🛡️  NixOS Rebuild: $MODE ===${NC}"

# 1. Verification Block
echo -e "🔍 ${YELLOW}Running pre-flight checks...${NC}"

# Check for required tools
for tool in nh nvd git; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}Error: '$tool' is not installed. Add it to your configuration!${NC}"
        exit 1
    fi
done

# Check Nix syntax
if ! find . -name "*.nix" -exec nix-instantiate --parse {} + > /dev/null; then
    echo -e "${RED}FAILED: Syntax error in Nix files.${NC}"
    exit 1
fi

# 2. Show Pending Changes
if ! git diff --quiet; then
    echo -e "📝 ${YELLOW}Changes detected in config:${NC}"
    git --no-pager diff --stat
fi

# 3. The Build process
echo -e "🚀 ${GREEN}Executing $MODE...${NC}"

# Note: We use -- --quiet or similar if needed, but nh is usually fine.
# We handle the 'no new privileges' error by checking sudo availability.
if ! sudo -n true 2>/dev/null; then
    echo -e "� ${YELLOW}Sudo access required for activation.${NC}"
fi

# Try to run nh
if nh os "$MODE" . --hostname "$HOSTNAME"; then
    echo -e "--------------------------------------------------"
    
    # 4. Success & Git Management
    # Only commit if we entered a configuration change
    if ! git diff --quiet || [[ -n $(git ls-files --others --exclude-standard) ]]; then
        git add .
        COMMIT_MSG="rebuild($MODE): $(date '+%Y-%m-%d %H:%M')"
        git commit -m "$COMMIT_MSG"
        echo -e "✅ ${GREEN}Changes committed to Git.${NC}"
    else
        echo -e "ℹ️ ${BLUE}No changes to commit.${NC}"
    fi

    echo -e "✨ ${GREEN}System updated successfully!${NC}"
else
    echo -e "\n${RED}❌ Error: Rebuild failed.${NC}"
    echo -e "${YELLOW}Common fix: If you get 'no new privileges', run the script in your main terminal (Ctrl+Alt+T)${NC}"
    exit 1
fi
