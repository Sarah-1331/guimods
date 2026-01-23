#!/bin/bash
# Venus OS Widgets Direct Installer (NO overlay-fs)
# Safely edits factory QML files with timestamped backups in-place

# ------------------------------
# Overlay-aware widgets path logic
# ------------------------------



set -e

ORIG_WIDGET_DIR="/opt/victronenergy/gui-v2/Victron/VenusOS/components/widgets"
OVERLAY_UPPER="/data/apps/overlay-fs/data/gui-v2/upper"
OVERLAY_WIDGET_DIR="$OVERLAY_UPPER/Victron/VenusOS/components/widgets"

FILES=("AcInputWidget.qml" "AcLoadsWidget.qml")

if [ -d "$OVERLAY_UPPER" ]; then
    echo "✅ Overlay upper found, using overlay widgets."

    # Ensure full directory structure exists
    mkdir -p "$OVERLAY_WIDGET_DIR"

    # Copy BOTH widget files if missing
    for file in "${FILES[@]}"; do
        if [ ! -f "$OVERLAY_WIDGET_DIR/$file" ]; then
            cp "$ORIG_WIDGET_DIR/$file" "$OVERLAY_WIDGET_DIR/$file" || {
                echo "❌ Failed to copy $file to overlay"
                exit 1
            }
            echo "📝 Copied $file to overlay."
        else
            echo "ℹ $file already exists in overlay."
        fi
    done

    TARGET_DIR="$OVERLAY_WIDGET_DIR"
else
    echo "⚠ Overlay not found, using original widgets."
    TARGET_DIR="$ORIG_WIDGET_DIR"
fi

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

echo "🚀 Starting Venus OS Widgets Direct Installer (no overlay-fs)"

# ------------------------------
# 1️⃣ Verify target directory
# ------------------------------
if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Target directory not found: $TARGET_DIR"
    exit 1
fi

cd "$TARGET_DIR"

# ------------------------------
# 2️⃣ Backup originals (in-place)
# ------------------------------
for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Missing file: $file"
        exit 1
    fi

    BACKUP="${file}.bak-${TIMESTAMP}"

    if [ ! -f "$BACKUP" ]; then
        cp "$file" "$BACKUP"
        echo "🕒 Backup created: $BACKUP"
    else
        echo "ℹ Backup already exists: $BACKUP"
    fi
done

# ------------------------------
# 3️⃣ Patch AcInputWidget.qml
#    (insert AFTER ThreePhaseDisplay block)
# ------------------------------
ACINPUT="AcInputWidget.qml"

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

echo "✅ AcInputWidget.qml patched"

# ------------------------------
# 4️⃣ Patch AcLoadsWidget.qml
#    (insert BEFORE ThreePhaseDisplay block)
# ------------------------------
ACLOADS="AcLoadsWidget.qml"

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

echo "✅ AcLoadsWidget.qml patched"

# ------------------------------
# 5️⃣ Reboot
# ------------------------------
echo "🔄 Rebooting ..."
sleep 10 && reboot

echo "🎉 Done! Factory files modified safely with timestamped backups."
