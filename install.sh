#!/bin/bash
#
# install.sh - SA120 Fan Speed Controller Installer
# For Synology DSM 7.x / Xpenology / Arc Loader
#

set -e

INSTALL_DIR="/volume1/apps/sa120"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================="
echo "SA120 Fan Speed Controller Installer"
echo "=========================================="
echo ""

# Check root
if [[ $EUID -ne 0 ]]; then
    echo "Error: Must run as root (use sudo)"
    exit 1
fi
echo "[OK] Running as root"

# Check if running on Synology
if [[ ! -f /etc.defaults/VERSION ]]; then
    echo "[WARN] Not a Synology system - proceeding anyway"
else
    DSM_VERSION=$(grep productversion /etc.defaults/VERSION | cut -d'"' -f2)
    echo "[OK] DSM Version: $DSM_VERSION"
fi

# Check for Entware
if [[ -d /opt/bin ]]; then
    echo "[OK] Entware detected"
    OPKG="/opt/bin/opkg"
    SG_SES="/opt/bin/sg_ses"
else
    echo "[WARN] Entware not found at /opt/bin"
    OPKG=""
    SG_SES="sg_ses"
fi

# Check/install sg3_utils
if command -v sg_ses &> /dev/null; then
    echo "[OK] sg_ses found"
elif [[ -n "$OPKG" ]]; then
    echo "[..] Installing sg3_utils via Entware..."
    $OPKG update
    $OPKG install sg3_utils
    echo "[OK] sg3_utils installed"
else
    echo ""
    echo "Error: sg_ses not found and Entware not available."
    echo "Please install sg3_utils manually or set up Entware first."
    echo ""
    echo "Entware setup: https://github.com/Entware/Entware/wiki/Install-on-Synology-NAS"
    exit 1
fi

# Create install directory
echo "[..] Creating $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"

# Copy script
echo "[..] Installing fanspeed.sh..."
cp "$SCRIPT_DIR/fanspeed.sh" "$INSTALL_DIR/fanspeed.sh"
chmod +x "$INSTALL_DIR/fanspeed.sh"

# Test enclosure detection
echo ""
echo "[..] Testing SA120 detection..."
if "$INSTALL_DIR/fanspeed.sh" --status --quiet 2>/dev/null; then
    echo "[OK] SA120 enclosure detected"
else
    echo "[WARN] Could not detect SA120 - check connections"
fi

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Usage:"
echo "  $INSTALL_DIR/fanspeed.sh --status    # Check fan speeds"
echo "  $INSTALL_DIR/fanspeed.sh 2           # Set fans to speed 2"
echo ""
echo "=========================================="
echo "DSM Task Scheduler Setup (for boot)"
echo "=========================================="
echo ""
echo "1. Open DSM > Control Panel > Task Scheduler"
echo "2. Create > Triggered Task > User-defined script"
echo "3. Settings:"
echo "   - Task:    SA120-Fanspeed"
echo "   - User:    root"
echo "   - Event:   Boot-up"
echo "   - Enabled: Yes"
echo ""
echo "4. Task Settings > User-defined script:"
echo ""
echo "   $INSTALL_DIR/fanspeed.sh 2"
echo ""
echo "   (Change '2' to your preferred speed 1-6)"
echo ""
