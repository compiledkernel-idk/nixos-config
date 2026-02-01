#!/usr/bin/env zsh

PACKAGE=$1
CONFIG_FILE="$HOME/nixos-config/configuration.nix"
REBUILD_SCRIPT="$HOME/nixos-config/rebuild.sh"

if [ -z "$PACKAGE" ]; then
    echo "❌ Usage: nix-add <package-name>"
    exit 1
fi

# Check if package is already in the file
if grep -qE "^\s+$PACKAGE(\s|$)" "$CONFIG_FILE"; then
    echo "⚠️  Package '$PACKAGE' is already in your configuration."
    exit 0
fi

# Find the end of the environment.systemPackages block
# We look for the '];' that comes after 'environment.systemPackages'
LINE_NUM=$(awk '/environment.systemPackages = with pkgs; \[/ {found=1} found && /  \];/ {print NR; exit}' "$CONFIG_FILE")

if [ -z "$LINE_NUM" ]; then
    echo "❌ Could not find the end of the environment.systemPackages block in $CONFIG_FILE"
    exit 1
fi

# Insert before the closing bracket
sed -i "${LINE_NUM}i \    $PACKAGE" "$CONFIG_FILE"

echo "✅ Added '$PACKAGE' to configuration.nix at line $LINE_NUM"

# Trigger the rebuild
if [ -f "$REBUILD_SCRIPT" ]; then
    echo "🚀 Triggering rebuild..."
    "$REBUILD_SCRIPT"
else
    echo "❌ Rebuild script not found at $REBUILD_SCRIPT"
fi
