#!/bin/bash
# Captures a screenshot and a short video of each menu bar app's popover.
#
# Needs two permissions for whatever runs it (Terminal, or Claude):
#   Privacy & Security > Accessibility            (to click the status items)
#   Privacy & Security > Screen & System Audio Recording  (to capture pixels)
#
#   ./tools/capture-mac-apps.sh            # all five
#   ./tools/capture-mac-apps.sh VolBoost   # just one
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=media
APPS=("${@:-VolBoost ClipStack Vigil Shelf Tidy}")
[ $# -eq 0 ] && APPS=(VolBoost ClipStack Vigil Shelf Tidy)

status_item_frame() {  # -> "x y w h" of the app's status item, in screen points
  osascript -e "tell application \"System Events\" to tell process \"$1\" to get {position, size} of menu bar item 1 of menu bar 1" \
    | tr -d ' ' | tr ',' ' '
}

for app in "${APPS[@]}"; do
  pgrep -xq "$app" || { echo "$app is not running, skipping"; continue; }
  read -r x y w h <<<"$(status_item_frame "$app")"
  # The popover hangs below the status item, centred on it. Capture a generous
  # region and let the app's own popover size decide what is in frame.
  W=380; H=560
  RX=$(( x + w/2 - W/2 )); RY=$(( y + h ))
  osascript -e "tell application \"System Events\" to tell process \"$app\" to click menu bar item 1 of menu bar 1" >/dev/null
  sleep 1.2
  screencapture -x -R "$RX,$RY,$W,$H" -t png "$OUT/${app,,}.png"
  # Eight seconds of the popover, so hover states and live values show.
  screencapture -x -v -V 8 -R "$RX,$RY,$W,$H" "$OUT/${app,,}.mov"
  osascript -e 'tell application "System Events" to key code 53' >/dev/null   # esc closes the popover
  echo "captured $app"
done
echo "Trim transparent margins and convert .mov to .mp4 before publishing."
