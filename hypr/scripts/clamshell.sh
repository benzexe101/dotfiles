#!/usr/bin/env bash

# Wait for lid sensor to settle
sleep 0.5

# Check physical lid state
if grep -qi 'closed' /proc/acpi/button/lid/*/state; then

    # Only disable laptop display if external monitor is active
    if hyprctl monitors | grep -Eq '^Monitor (DP-1|DP-2) '; then

        if hyprctl monitors | grep -q '^Monitor eDP-1 '; then
            hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })'

            notify-send -r 4242 \
                "Clamshell Mode" \
                "Enabled - Laptop display disabled"
        fi
    fi

else
    # Restore laptop display only if currently disabled
    if ! hyprctl monitors | grep -q '^Monitor eDP-1 '; then

        ##hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = false, mode = "2880x1800@120", position = "0x0", scale = 2 })' ## Remove the Hashtag if you have this on the book holder
        hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = false, mode = "2880x1800@120", position = "4640x0", scale = 2 })' # Remove the Hashtag in case you have the laptop on top of the desktop tower        


        notify-send -r 4242 \
            "Clamshell Mode" \
            "Disabled - Laptop display restored"
    fi
fi
