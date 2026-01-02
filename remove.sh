#!/bin/bash

WIDGET_DIR="/opt/victronenergy/gui-v2/Victron/VenusOS/components/widgets"
FILES=("AcInputWidget.qml" "AcLoadsWidget.qml")

for FILE in "${FILES[@]}"; do
    BACKUP=$(ls -t "$WIDGET_DIR/$FILE.bak"* 2>/dev/null | head -n1)
    if [ -n "$BACKUP" ]; then
        # Safety copy of current file
        [ -f "$WIDGET_DIR/$FILE" ] && cp "$WIDGET_DIR/$FILE" "$WIDGET_DIR/${FILE}.pre-restore-$(date +%Y%m%d-%H%M%S)"
        
        # Restore the backup
        cp "$BACKUP" "$WIDGET_DIR/$FILE"
        echo "✅ $FILE restored from $BACKUP"
    else
        echo "❌ No backup found for $FILE"
    fi
done

# Restart GUI in background so terminal is not killed
( svc -t /service/gui-v2 && svc -t /service/start-gui ) &
echo "🔄 GUI restart triggered in background"
