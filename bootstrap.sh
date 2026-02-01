#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/compiledkernel-idk/nixos-config.git}"
CONFIG_DIR="$HOME/nixos-config"
NIXOS_DIR="/etc/nixos"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       NixOS Configuration Bootstrap          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"

[[ -f /etc/NIXOS ]] || { echo -e "${RED}Error: Must run on NixOS${NC}"; exit 1; }

if [[ -d "$CONFIG_DIR" ]]; then
    cd "$CONFIG_DIR"
    git pull --ff-only || { git fetch origin && git reset --hard origin/master; }
else
    git clone "$REPO_URL" "$CONFIG_DIR"
    cd "$CONFIG_DIR"
fi

chmod +x "$CONFIG_DIR"/*.sh 2>/dev/null || true
chmod +x "$CONFIG_DIR"/*.py 2>/dev/null || true

sudo nixos-generate-config --show-hardware-config > "$CONFIG_DIR/hardware-configuration.nix"

sudo rm -f "$NIXOS_DIR/configuration.nix" "$NIXOS_DIR/hardware-configuration.nix" "$NIXOS_DIR/flake.nix" 2>/dev/null || true
sudo ln -sf "$CONFIG_DIR/configuration.nix" "$NIXOS_DIR/configuration.nix"
sudo ln -sf "$CONFIG_DIR/hardware-configuration.nix" "$NIXOS_DIR/hardware-configuration.nix"
sudo ln -sf "$CONFIG_DIR/flake.nix" "$NIXOS_DIR/flake.nix"

sudo nixos-rebuild switch --flake "$CONFIG_DIR#nixos"

echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            Bootstrap complete!               ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
