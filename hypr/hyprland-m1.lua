-- Hyprland config — BenM1Linux (M1 MacBook, Fedora Asahi Remix)
-- Keybinds match the Garuda desktop. M1-specific changes marked "M1:".

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- M1: foot -> kitty, thunar -> dolphin
local terminal     = "kitty"
local fileExplorer = "dolphin"
local editor       = "codium"
local browser      = "flatpak run app.zen_browser.zen"
local audioMixer   = "kitty --class pulsemixer -T Volume -e pulsemixer"

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    hl.exec_cmd("caelestia shell -d")
    hl.exec_cmd("flatpak run dev.vencord.Vesktop")
    hl.exec_cmd("wl-paste --watch cliphist store")
    -- hl.exec_cmd("noctalia")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.config({
    general = {
        gaps_in = 5, gaps_out = 10, border_size = 1,
        col = {
            active_border = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false, allow_tearing = false, layout = "dwindle",
    },
    decoration = {
        rounding = 15, rounding_power = 2,
        active_opacity = 1.0, inactive_opacity = 0.95,
        shadow = { enabled = true, range = 15, render_power = 4, color = 0xee1a1a1a },
        blur = { enabled = true, size = 8, passes = 2, vibrancy = 0.1696 },
    },
    animations = { enabled = true },
})

-- M1: Asahi DCP has no usable hardware cursor plane
hl.config({ cursor = { no_hardware_cursors = true } })

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })
hl.curve("easy", { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  spring = "easy", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

hl.config({ dwindle = { preserve_split = true } })
hl.config({ master = { new_status = "master" } })
hl.config({ scrolling = { fullscreen_on_one_column = true } })
hl.config({ misc = { force_default_wallpaper = -1, disable_hyprland_logo = false } })

hl.config({
    input = {
        kb_layout = "us", kb_variant = "", kb_model = "", kb_options = "", kb_rules = "",
        follow_mouse = 1, sensitivity = 0,
        touchpad = { natural_scroll = false, disable_while_typing = true, scroll_factor = 0.3 },
    },
})


local mainMod = "SUPER"
local ipc     = "caelestia shell "

-- apps
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(editor))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileExplorer))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(audioMixer))

-- window actions
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + P", hl.dsp.window.pin())
hl.bind(mainMod .. " + ALT + Space", hl.dsp.window.float({ action = "toggle" }))

-- vim focus
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- arrows
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- special workspace toggles
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("caelestia toggle music"))
hl.bind(mainMod .. " + D", hl.dsp.workspace.toggle_special("communication"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("caelestia toggle todo"))
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd("caelestia toggle sysmon"))

-- caelestia shell
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(ipc .. "drawers toggle launcher"))
hl.bind(mainMod .. " + N",     hl.dsp.exec_cmd(ipc .. "drawers toggle sidebar"))
hl.bind("CTRL + SUPER + K",    hl.dsp.exec_cmd(ipc .. "drawers toggle dashboard"))
hl.bind("CTRL + ALT + L",      hl.dsp.exec_cmd(ipc .. "lock lock"))
hl.bind("CTRL + SUPER + SHIFT + L", hl.dsp.exec_cmd("systemctl suspend-then-hibernate"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/screenshot-region"))
hl.bind(mainMod .. " + V",         hl.dsp.exec_cmd("caelestia clipboard"))
hl.bind(mainMod .. " + Period",    hl.dsp.exec_cmd("caelestia emoji"))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("/home/Ben/.local/bin/screenshot-full"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("/home/Ben/.local/bin/screenshot-window"))

-- workspaces
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,       hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + ALT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind("CTRL + SUPER + right", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("CTRL + SUPER + left",  hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + S",       hl.dsp.workspace.toggle_special("special"))
hl.bind(mainMod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:special" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mainMod .. " + Z",         hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + X",         hl.dsp.window.resize(), { mouse = true })

-- media / hardware keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 10%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
hl.bind("CTRL + SUPER + Space", hl.dsp.exec_cmd(ipc .. "mpris playPause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd(ipc .. "mpris next"),      { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(ipc .. "mpris playPause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd(ipc .. "mpris playPause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd(ipc .. "mpris previous"),  { locked = true })

-- window rules
hl.window_rule({ name = "suppress-maximize-events", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})
hl.window_rule({ name = "move-hyprland-run", match = { class = "hyprland-run" }, move = "20 monitor_h-120", float = true })
hl.window_rule({ match = { class = "pulsemixer" }, float = true, size = { 900, 600 } })
hl.window_rule({ match = { class = "vesktop" }, workspace = "special:communication" })

hl.config({
    gestures = {
        workspace_swipe_distance                 = 700,
        workspace_swipe_cancel_ratio             = 0.15,
        workspace_swipe_min_speed_to_force       = 5,
        workspace_swipe_direction_lock           = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_create_new               = true,
    },
})

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up", action = "special", workspace_name = "special" })
hl.gesture({
    fingers   = 4,
    direction = "down",
    action    = function()
        hl.exec_cmd("systemctl suspend-then-hibernate")
    end,
})

hl.gesture({ fingers = 3, direction = "horizontal", mods = "SUPER", action = "resize" })
hl.gesture({ fingers = 3, direction = "vertical", mods = "SUPER", action = "move" })
