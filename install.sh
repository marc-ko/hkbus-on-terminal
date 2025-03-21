#!/bin/bash

# Define the installation directory
INSTALL_DIR="$HOME/.hkbus"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Copy scripts to installation directory
cp -r "$SCRIPT_DIR/ust-eta" "$INSTALL_DIR/"

# Set up shell configuration
SHELL_CONFIG=""
if [[ "$SHELL" == *"zsh"* ]]; then
  SHELL_CONFIG="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
  SHELL_CONFIG="$HOME/.bashrc"
else
  echo "Unsupported shell. Please manually add the bus command to your shell configuration."
  exit 1
fi

# Add to path only if not already there
if ! grep -q "alias bus=" "$SHELL_CONFIG"; then
  echo "" >> "$SHELL_CONFIG"
  echo "# HK Bus terminal tool" >> "$SHELL_CONFIG"
  echo "alias bus=\"$INSTALL_DIR/ust-eta/bus.sh\"" >> "$SHELL_CONFIG"
fi

echo "HK Bus terminal tool installed successfully!"
echo "Please restart your terminal or run 'source $SHELL_CONFIG' to use the 'bus' command."
echo "Usage: bus [stop_id|stop_name] [route_number]"
