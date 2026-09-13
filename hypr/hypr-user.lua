local hostname = io.popen("hostname"):read("*l")

hl.on("hyprland.start", function()
	hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/geforcenow-fullscreen.sh")
end)

if hostname == "BenX1" then
	hl.monitor({ output = "eDP-1", mode = "2880x1800@120", position = "0x0", scale = 2 })
else
	hl.monitor({ output = "DP-3", mode = "2560x1440@143.99", position = "0x0", scale = 1 }) --This Monitor is on the left side.
	hl.monitor({ output = "DP-1", mode = "2560x1440@143.99", position = "2560x0", scale = 1 }) --This Monitor is on the right side.
	hl.monitor({ output = "DVI-I-1", disabled = true })
	--monitor=DP-1,2560x1440@143.99,0x1440,1 #This Monitor will be the bottom one (use this only when you physically move the monitor to the bottom position, and don't forget to remove the hashtag symbol.
end

hl.bind("SUPER + Slash", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/cheatsheet-toggle.sh"))

-- ── vim-style window focus ────────────────────────────────
hl.bind("SUPER + H", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + J", hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + K", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + L", hl.dsp.focus({ direction = "right" }))

-- ── move windows ──────────────────────────────────────────
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- Lid switch (X1 clamshell)

-- Monitors (X1 dock)
hl.monitor({ output = "eDP-1", disabled = false, mode = "2880x1800@120", position = "0x0", scale = 2 })
hl.monitor({ output = "DP-1", mode = "2560x1440@180.063", position = "4000x0", scale = 1 })
hl.monitor({ output = "DP-2", mode = "2560x1440@200.013", position = "1440x0", scale = 1 })

-- Lid switch (clamshell)
hl.bind("switch:on:Lid Switch", function()
    hl.monitor({ output = "eDP-1", disabled = true })
    hl.dispatch(hl.dsp.exec_cmd("notify-send 'lid closed'"))
end, { locked = true })
hl.bind("switch:off:Lid Switch", function()
    hl.monitor({ output = "eDP-1", disabled = false, mode = "2880x1800@120", position = "0x0", scale = 2 })
    hl.dispatch(hl.dsp.exec_cmd("notify-send 'lid opened'"))
end, { locked = true })
