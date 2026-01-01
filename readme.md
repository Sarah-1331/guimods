# Venus OS Widgets Overlay Installer

This repository contains a **ready-to-run installer** to safely apply custom edits to Venus OS widgets (`AcInputWidget.qml` and `AcLoadsWidget.qml`) using an overlay filesystem.  
The original system files are **never modified**.

## Features

- Creates an overlay for `/opt/victronenergy/gui-v2/Victron/VenusOS/components/widgets`
- Inserts custom blocks in the correct locations in both widgets
- Safely copies original files into the overlay
- Automatically restarts the GUI to apply changes

## Installation

1. Copy `install_widgets_overlay.sh` to your Venus OS system, e.g.:

chmod +x install_widgets_overlay.sh
bash install_widgets_overlay.sh

