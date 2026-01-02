# Venus OS Widgets Overlay Installer

This repository contains a **ready-to-run installer** to safely apply custom edits to Venus OS widgets (`AcInputWidget.qml` and `AcLoadsWidget.qml`) using an overlay filesystem.  
The original system files are **never modified**.

---

## Features

- Creates an overlay for `/opt/victronenergy/gui-v2/Victron/VenusOS/components/widgets`  
  
- Safely copies original files to.bak  
- Automatically restarts the GUI to apply changes  

---

## Installation

SSH into your Venus OS device and run the following commands:

```bash
# Download the installer
wget https://raw.githubusercontent.com/Sarah-1331/guimods/main/install_widgets.sh -O /data/install_widgets.sh

# Make it executable
chmod +x /data/install_widgets.sh

# Run the installer
bash /data/install_widgets.sh



🗑️ Uninstall / Reset

To remove the custom overlay and revert to the original wigets:



# Restore the orignals 
cd /opt/victronenergy/gui-v2/Victron/VenusOS/components/widgets && \
for f in AcInputWidget.qml AcLoadsWidget.qml; do \
  [ -f "$f" ] && cp "$f" "$f.pre-restore-$(date +%Y%m%d-%H%M%S)"; \
  b=$(ls -t "$f".bak-* 2>/dev/null | head -n1) && \
  [ -n "$b" ] && cp "$b" "$f"; \
done && \
svc -t /service/gui-v2 && svc -t /service/start-gui



