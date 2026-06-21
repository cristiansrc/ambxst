#!/bin/bash
# Safety checks
UPDATES_ARCH=0
UPDATES_AUR=0

if command -v checkupdates >/dev/null 2>&1; then
    UPDATES_ARCH=$(checkupdates 2>/dev/null | wc -l)
fi

if command -v paru >/dev/null 2>&1; then
    UPDATES_AUR=$(paru -Qua 2>/dev/null | wc -l)
fi

TOTAL=$((UPDATES_ARCH + UPDATES_AUR))
echo "$TOTAL"
