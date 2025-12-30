#!/bin/bash
# Venus OS AC L1 Publisher Installer
set -e

INSTALL_DIR="/data/apps/mygui"
SCRIPT_NAME="publish_ac_l1_values.py"
RC_LOCAL="/etc/rc.local"

echo "=== Venus OS AC L1 Publisher Installer ==="

# Create directory
echo "Creating install directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Copy the script
echo "Copying $SCRIPT_NAME to $INSTALL_DIR"
cp "./data/apps/mygui/$SCRIPT_NAME" "$INSTALL_DIR/"

# Make script executable
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# Add to rc.local if not already added
if ! grep -q "$SCRIPT_NAME" "$RC_LOCAL"; then
    echo "Adding startup command to $RC_LOCAL"
    sed -i "/^exit 0/i $INSTALL_DIR/$SCRIPT_NAME &" "$RC_LOCAL"
else
    echo "Startup command already exists in $RC_LOCAL"
fi

echo "Installation complete!"
echo "You can reboot or run the script manually with:"
echo "$INSTALL_DIR/$SCRIPT_NAME &"
