#!/usr/bin/env python3
"""
Venus OS compatible Python publisher for AC L1 Voltage and Current
Publishes values on system bus so VeQuickItem can display them
"""

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

# --- VE.Bus constants ---
VE_BUS_SERVICE = "com.victronenergy.vebus.ttyS4"
VE_BUS_INTERFACE = "com.victronenergy.BusItem"

# --- Custom DBus service and object paths ---
PUBLISH_PATHS = {
    "L1_V": "/Ac/ActiveIn/L1/V/Value",
    "L1_I": "/Ac/ActiveIn/L1/I/Value"
}

POLL_ITEMS = {
    "L1_V": {"path": "/Ac/ActiveIn/L1/V", "round": 0},
    "L1_I": {"path": "/Ac/ActiveIn/L1/I", "round": 1}
}

# Setup DBus main loop
dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
system_bus = dbus.SystemBus()

# Custom DBus object
class DBusValue(dbus.service.Object):
    def __init__(self, bus, path):
        super().__init__(bus, path)
        self.value = 0.0

    @dbus.service.method("com.victronenergy.BusItem", in_signature='', out_signature='d')
    def GetValue(self):
        return self.value

# Initialize publishers
publishers = {}
for key, item in POLL_ITEMS.items():
    publishers[key] = DBusValue(system_bus, PUBLISH_PATHS[key])

# Poll function (every second)
def poll_values():
    for key, item in POLL_ITEMS.items():
        try:
            obj = system_bus.get_object(VE_BUS_SERVICE, item["path"])
            val = obj.GetValue(dbus_interface=VE_BUS_INTERFACE)
            if item["round"] == 0:
                publishers[key].value = round(float(val))
            else:
                publishers[key].value = round(float(val), item["round"])
            print(f"{key} published: {publishers[key].value}")
        except Exception as e:
            print(f"Error polling {key}:", e)
    return True

GLib.timeout_add_seconds(1, poll_values)
loop = GLib.MainLoop()
loop.run()
