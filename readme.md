
---

# Venus OS AC Widgets Installer ⚡

This repository provides a **ready-to-run installer** to safely enhance your Venus OS GUI with **live AC widgets**:

* **V (Voltage)**
* **A (Current)**
* **Hz (Frequency)**

for both **AC Input** and **AC Output**.

The installer **backs up your original QML files** before applying any changes, so your system is fully recoverable. 🛡️

---

## Features ✨

* Directly modifies `/opt/victronenergy/gui-v2/Victron/VenusOS/components/widgets`
* Safely backs up original files with timestamps 🕒
* Adds **live AC Input & Output widgets**: V, A, Hz ⚡
* Automatically restarts the GUI to apply changes 🔄
* Fully **no-overlay**, works directly on factory files
* Safe to re-run multiple times ✅

---

## Installation 🚀

SSH into your Venus OS device and run the following commands:

```bash
# Download the installer
wget https://raw.githubusercontent.com/Sarah-1331/guimods/main/install_widgets.sh -O /data/install_widgets.sh

# Make it executable
chmod +x /data/install_widgets.sh

# Run the installer
bash /data/install_widgets.sh
```


---

## 🔹 Restore the Originals 🛠️

If you ever want to revert to the original system files:

```bash
# Download the restore script
wget https://raw.githubusercontent.com/Sarah-1331/guimods/main/remove.sh -O /data/remove.sh

# Run it to restore backups
bash /data/remove.sh
```

This restores **all backed-up QMLs** (widgets) to their original state safely. 🕒

---

## Notes 📝

* All backups are timestamped and stored **next to the original files**.
* The installer only modifies the **widgets**; other GUI files are untouched.
* Works safely on Venus OS **without overlay-fs**.

---


