# Venus OS Widgets Overlay Installer

This repository contains a **ready-to-run installer** to safely apply custom edits to Venus OS widgets (`AcInputWidget.qml` and `AcLoadsWidget.qml`) using an overlay filesystem.  
The original system files are **never modified**.

---

## Features

- Creates an overlay for `/opt/victronenergy/gui-v2/Victron/VenusOS/components/widgets`  
- Inserts custom blocks in the correct locations in both widgets  
- Safely copies original files into the overlay  
- Automatically restarts the GUI to apply changes  

---

## Installation

SSH into your Venus OS device and run the following commands:

```bash
# Download the installer
wget https://raw.githubusercontent.com/Sarah-1331/guimods/main/install_widgets_overlay.sh -O /data/custom_gui_patch.sh

# Make it executable
chmod +x /data/custom_gui_patch.sh

# Run the installer
bash /data/custom_gui_patch.sh
