#!/bin/bash
# Venus OS Widgets Overlay Installer
# Safely edits factory QML files using overlay-fs

set -e

# ------------------------------
# 0️⃣ Overlay paths
# ------------------------------
OVERLAY_ROOT="/data/apps/overlay-fs/data/gui-v2/upper"
SYSTEM_ROOT="/opt/victronenergy/gui-v2/Victron/VenusOS/components/widgets"

FILES=("AcInputWidget.qml" "AcLoadsWidget.qml")
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

echo "🚀 Starting Venus OS Widgets Overlay Installer"

# ------------------------------
# 1️⃣ Verify overlay path
# ------------------------------
if [ ! -d "$OVERLAY_ROOT" ]; then
    echo "❌ Overlay root not found: $OVERLAY_ROOT"
    exit 1
fi

# ------------------------------
# 2️⃣ Process each file
# ------------------------------
for file in "${FILES[@]}"; do
    ORIG_FILE="$SYSTEM_ROOT/$file"
    OVERLAY_DIR="$OVERLAY_ROOT"
    OVERLAY_FILE="$OVERLAY_DIR/$file"

    # Create overlay directory if it doesn't exist
    mkdir -p "$OVERLAY_DIR"

    # Copy original file if it doesn't exist yet in overlay
    if [ ! -f "$OVERLAY_FILE" ]; then
        cp "$ORIG_FILE" "$OVERLAY_FILE"
        echo "🕒 Copied original to overlay: $OVERLAY_FILE"
    else
        echo "ℹ Overlay copy already exists: $OVERLAY_FILE"
    fi

done

# ------------------------------
# 3️⃣ Patch AcInputWidget.qml (overlay)
# ------------------------------
ACINPUT="$OVERLAY_ROOT/AcInputWidget.qml"

awk -v block="$(cat <<'EOB'

//start edit//
VeQuickItem {
    id: acVoltage
    uid: "dbus/com.victronenergy.vebus.ttyS4/Ac/Out/L1/V"
}
VeQuickItem {
    id: acFrequency
    uid: "dbus/com.victronenergy.vebus.ttyS4/Ac/Out/L1/F"
}

// --- DERIVED AC INPUT CURRENT (Victron-style estimate) ---
Label {
    id: derivedInputCurrent

    readonly property real derivedCurrent:
        root.input && root.input.power !== undefined && acVoltage.valid && acVoltage.value > 0
            ? root.input.power / acVoltage.value
            : NaN

    text: (acVoltage.valid ? acVoltage.value.toFixed(0) + " V" : "--- V") + "  " +
          (!isNaN(derivedCurrent) ? derivedCurrent.toFixed(1) + " A" : "--.- A") + "  " +
          (acFrequency.valid ? acFrequency.value.toFixed(1) + " Hz" : "--.- Hz")

    font.pixelSize: 18
    color: Theme.color_font_primary
    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
        bottomMargin: Theme.geometry_baseline_spacing
    }

    visible: root.size >= VenusOS.OverviewWidget_Size_L &&
             root.inputOperational &&
             root.input.connected
}
//end edit//
EOB
)" '
/extraContentLoader\.sourceComponent: ThreePhaseDisplay/ {flag=1}
flag && /^\s*}\s*$/ {print; print block; flag=0; next}
1
' "$ACINPUT" > "${ACINPUT}.tmp" && mv "${ACINPUT}.tmp" "$ACINPUT"

echo "✅ AcInputWidget.qml patched (overlay)"

# ------------------------------
# 4️⃣ Patch AcLoadsWidget.qml (overlay)
# ------------------------------
ACLOADS="$OVERLAY_ROOT/AcLoadsWidget.qml"

awk -v block="$(cat <<'EOB'

//start edit//
////////////////////////////////////////////////////////////

// --- LIVE AC VOLTAGE, CURRENT, FREQUENCY ---
VeQuickItem {
    id: acVoltage
    uid: "dbus/com.victronenergy.vebus.ttyS4/Ac/Out/L1/V"
}
VeQuickItem {
    id: acCurrent
    uid: "dbus/com.victronenergy.vebus.ttyS4/Ac/Out/L1/I"
}
VeQuickItem {
    id: acFrequency
    uid: "dbus/com.victronenergy.vebus.ttyS4/Ac/Out/L1/F"
}

Label {
    text: (acVoltage.valid ? acVoltage.value.toFixed(0) + " V" : "--- V") + "  " +
          (acCurrent.valid ? acCurrent.value.toFixed(1) + " A" : "--.- A") + "  " +
          (acFrequency.valid ? acFrequency.value.toFixed(1) + " Hz" : "--.- Hz")

    font.pixelSize: 18
    color: Theme.color_font_primary
    anchors {
        bottom: parent.bottom
        horizontalCenter: parent.horizontalCenter
        bottomMargin: Theme.geometry_baseline_spacing
    }

    visible: root.size >= VenusOS.OverviewWidget_Size_L &&
             acVoltage.valid &&
             acVoltage.value >= 10
}
//end edit//
EOB
)" '
/extraContentLoader\.sourceComponent: ThreePhaseDisplay/ {print block}
1
' "$ACLOADS" > "${ACLOADS}.tmp" && mv "${ACLOADS}.tmp" "$ACLOADS"

echo "✅ AcLoadsWidget.qml patched (overlay)"

# ------------------------------
# 5️⃣ Restart GUI
# ------------------------------
echo "🔄 Restarting GUI..."
svc -t /service/gui-v2
svc -t /service/start-gui

echo "🎉 Done! Overlay modifications applied safely."
