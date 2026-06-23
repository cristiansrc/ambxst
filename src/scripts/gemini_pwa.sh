#!/usr/bin/env bash
# Helper script to open/close/resize Gemini PWA floating window exactly over the assistant sidebar

exec > /home/cristiansrc/.local/src/ambxst/pwa_debug.log 2>&1
echo "Running gemini_pwa.sh with args: $@"

CMD="${1:-}"

if [ "$CMD" = "open" ]; then
    X="${2:-0}"
    Y="${3:-0}"
    W="${4:-400}"
    H="${5:-600}"

    echo "Opening/Updating PWA at X=$X, Y=$Y, W=$W, H=$H"

    # Set new rules for when it spawns
    hyprctl keyword windowrulev2 "float, class:^(gemini-pwa)$"
    hyprctl keyword windowrulev2 "pin, class:^(gemini-pwa)$"
    hyprctl keyword windowrulev2 "move $X $Y, class:^(gemini-pwa)$"
    hyprctl keyword windowrulev2 "size $W $H, class:^(gemini-pwa)$"
    hyprctl keyword windowrulev2 "noborder, class:^(gemini-pwa)$"
    hyprctl keyword windowrulev2 "noshadow, class:^(gemini-pwa)$"
    hyprctl keyword windowrulev2 "noblur, class:^(gemini-pwa)$"

    if hyprctl clients | grep -q "class: gemini-pwa"; then
        echo "Gemini window already exists. Moving and resizing..."
        hyprctl dispatch 'hl.dsp.window.move({ x = '$X', y = '$Y', relative = false, window = "class:gemini-pwa" })'
        hyprctl dispatch 'hl.dsp.window.resize({ x = '$W', y = '$H', relative = false, window = "class:gemini-pwa" })'
    else
        echo "Launching brave..."
        brave --app=https://gemini.google.com/ --class=gemini-pwa &
        echo "Brave launched in background."
    fi
    
elif [ "$CMD" = "close" ]; then
    echo "Closing PWA..."
    hyprctl dispatch 'hl.dsp.window.close("class:gemini-pwa")' || true
fi
