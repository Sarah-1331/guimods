#!/bin/bash
# Venus OS Widgets Overlay Installer - robust version
# Installs overlay-fs if needed, then applies custom GUI edits safely

OVERLAY_NAME="widgets-overlay"
OVERLAY_BASE="/data/apps/overlay-fs/data/$OVERLAY_NAME"
UPPER="$OVERLAY_BASE/upper"
WORK="$OVERLAY_BASE/work"
TARGET="/opt/victronenergy/gui-v2/Victron/VenusOS/components/widgets"

echo "🚀 Starting Venus OS Widgets Overlay Installer..."

# ------------------------------
# 1️⃣ Check for overlay-fs
# ------------------------------
if [ ! -d /data/apps/overlay-fs ]; then
    echo "⚠ overlay-fs not found. Installing overlay-fs..."
    
    wget -q https://raw.githubusercontent.com/victronenergy/venus-overlay-fs/main/install.sh -O /data/install-overlay-fs.sh
    chmod +x /data/install-overlay-fs.sh
    bash /data/install-overlay-fs.sh
    
    echo "✅ overlay-fs installed."
else
    echo "✅ overlay-fs already installed."
fi

# ------------------------------
# 2️⃣ Add overlay for widgets
# ------------------------------
bash /data/apps/overlay-fs/add-app-and-directory.sh "$OVERLAY_NAME" "$TARGET"

# ------------------------------
# 3️⃣ Create overlay directories
# ------------------------------
mkdir -p "$UPPER" "$WORK"

# ------------------------------
# 4️⃣ Mount overlay manually
# ------------------------------
mount -t overlay overlay \
  -o lowerdir="$TARGET",upperdir="$UPPER",workdir="$WORK" \
  "$TARGET"

# ------------------------------
# 5️⃣ Copy original files if missing
# ------------------------------
for file in AcInputWidget.qml AcLoadsWidget.qml; do
    if [ ! -f "$UPPER/$file" ]; then
        cp "$TARGET/$file" "$UPPER/"
    fi
done

# ------------------------------
# 6️⃣ Edit AcInputWidget.qml (after ThreePhaseDisplay block)
# ------------------------------
ACINPUT="$UPPER/AcInputWidget.qml"

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
# Flag for detecting ThreePhaseDisplay closing
/extraContentLoader\.sourceComponent: ThreePhaseDisplay/ {flag=1}
flag && /^\s*}\s*$/ {print; print block; flag=0; next}1
' "$ACINPUT" > tmp && mv tmp "$ACINPUT"

echo "✅ AcInputWidget.qml edited correctly."

# ------------------------------
# 7️⃣ Edit AcLoadsWidget.qml (above ThreePhaseDisplay block)
# ------------------------------
ACLOADS="$UPPER/AcLoadsWidget.qml"

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
/extraContentLoader\.sourceComponent: ThreePhaseDisplay/ {print block}1
' "$ACLOADS" > tmp && mv tmp "$ACLOADS"

echo "✅ AcLoadsWidget.qml edited successfully."

# ------------------------------
# 8️⃣ Restart GUI
# ------------------------------
svc -t /service/gui-v2
svc -t /service/start-gui

echo "🎉 All edits applied. GUI restarted successfully!"
