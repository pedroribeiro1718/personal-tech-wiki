# PlasmaZones on KDE: Omarchy tiling and FancyZones snapping

This setup keeps KDE/KWin and provides two modes:

| Mode | Behavior |
| --- | --- |
| **Omarchy** | Automatic per-monitor tiling, keyboard focus/swaps, and fixed tiled windows |
| **FancyZones** | Fixed layouts, drag overlay, and multi-zone spanning |

Reference system: CachyOS, Plasma 6 Wayland, and mixed-DPI monitors.

## Preconditions

- Install and enable [PlasmaZones](https://phosphor-works.github.io/plasmazones/getting-started/).
- Remove or disable every other automatic KWin tiler, including Krohnkite, KZones, and Polonium.
- Use KDE **Click to focus**; disable PlasmaZones **Focus follows mouse**.
- Remove KDE shortcuts that conflict with the table below.
- Review KDE Window Rules that force geometry, maximization, borders, or a monitor.
- Back up `~/.config/plasmazones/`, `kglobalshortcutsrc`, `kwinrc`, and `kwinrulesrc` before migrating.

The JSON profile cannot perform those machine-level changes.

## Install

1. Import [`omarchy-on-kde-profile.json`](../../examples/plasmazones/omarchy-on-kde-profile.json) under **PlasmaZones Settings → Profiles** and select **Omarchy on KDE**. Changes apply immediately; there is no Save button.
2. In **Overview**, assign a fixed layout and an automatic algorithm to every monitor/desktop/activity context. Choose from the output's logical size, not its native resolution: Master + Stack works well on smaller workspaces; BSP suits larger ones.
3. Install the mode helper and Omarchy mouse guard:

   ```bash
   install -Dm755 examples/plasmazones/plasmazones-mode-toggle \
     ~/.local/bin/plasmazones-mode-toggle
   install -Dm644 examples/plasmazones/plasmazones-mode-toggle.desktop \
     ~/.local/share/applications/plasmazones-mode-toggle.desktop
   install -Dm644 examples/plasmazones/plasmazones-omarchy-lock/metadata.json \
     ~/.local/share/kwin/scripts/plasmazones-omarchy-lock/metadata.json
   install -Dm644 examples/plasmazones/plasmazones-omarchy-lock/contents/code/main.js \
     ~/.local/share/kwin/scripts/plasmazones-omarchy-lock/contents/code/main.js
   kwriteconfig6 --file kwinrc --group Plugins \
     --key plasmazones-omarchy-lockEnabled true
   kbuildsycoca6 --noincremental
   ```

4. Clear `Super+Shift+T` from PlasmaZones' native three-mode cycle, then assign it to **Toggle PlasmaZones Mode** in KDE Shortcuts.
5. Log out/in once, or toggle modes once, to load the guard.

## Daily use

Press `Super+Shift+T` to switch every current monitor together.

- **Omarchy:** normal windows tile automatically and retiles apply simultaneously. Tiled windows ignore mouse move and frame-resize gestures. The default cap is six; excess windows float. Float a window first if it must move freely.
- **FancyZones:** hold `Alt` while dragging for the overlay; hold `Ctrl+Alt` and drag across adjacent zones to span them.

The fixed-zone overlay and multi-zone spanning are FancyZones features; they do not appear while automatic tiling owns the screen. Spans stay within one physical monitor.

## Keyboard cheat sheet

`Super` is KDE's `Meta` key.

| Shortcut | Action |
| --- | --- |
| `Super+Arrow` | Focus in that direction |
| `Super+Shift+Arrow` | Swap in that direction |
| `Super+G` | Open layout/algorithm picker |
| `Super+Shift+G` | Open zone editor |
| `Super+T` | Toggle focused window between tiled and floating |
| `Super+-` / `Super+=` | Adjust automatic split ratio |
| `Super+Ctrl+T` | Retile current context |
| `Super+Shift+T` | Toggle Omarchy/FancyZones on all monitors |

| FancyZones gesture | Action |
| --- | --- |
| `Alt` + drag | Show overlay and snap |
| `Ctrl+Alt` + drag | Span adjacent zones |

## KDE shortcut conflicts

Clear the current KDE binding for each chord, then confirm PlasmaZones owns it:

| Chord | Common KDE owner |
| --- | --- |
| `Super+T` | KWin **Edit Tiles** |
| `Super+G` | KWin **Grid View** |
| `Super+Arrow` | KWin **Quick Tile Window…** |
| `Super+Shift+Left/Right` | KWin **Move Window to Previous/Next Screen** |
| `Super+-` / `Super+=` | KWin desktop zoom |
| `Super+Ctrl+T` | Wacom **Enable/Disable Touch Tool** |

## Mixed DPI and floating exceptions

PlasmaZones tiles in each output's **logical** coordinate space. At 150% scale, the tested outputs are 2560×1440 and 1707×960 logical pixels. The guard resolves the output directly, so it needs no scale-specific rule, but the tiling algorithm still matters: use BSP on the larger workspace and Master + Stack on the smaller one. Keep **Respect minimum size** enabled, cap tiles at six, and float overflow.

Applications can enforce a minimum logical size larger than they declare. If Dwindle produces narrow leaves that an app refuses, change that output to Master + Stack instead of disabling minimum-size handling. Steam is floated only when `app-id = steam` and `mode = tiling`; game windows are unaffected. Avoid a global `STEAM_FORCE_DESKTOPUI_SCALING` value or a hard-coded connector route.

In Omarchy mode, `Super+T` is the escape hatch: floating windows remain movable and resizable; tiled windows do not.

## Troubleshooting

### A normal application reopens floating

PlasmaZones persists per-window floating state independently of the profile. First use `Super+T`, then `Super+Ctrl+T`. If stale state affects several applications, reset only placement history:

```bash
systemctl --user mask --runtime plasmazones.service
systemctl --user stop plasmazones.service
cp ~/.config/plasmazones/session.json \
  ~/.config/plasmazones/session.json.before-placement-reset
jq '.WindowTracking.WindowPlacements = {} |
    .WindowTracking.UserSnappedClasses = []' \
  ~/.config/plasmazones/session.json > /tmp/plasmazones-session-clean.json
install -m 0600 /tmp/plasmazones-session-clean.json \
  ~/.config/plasmazones/session.json
systemctl --user unmask --runtime plasmazones.service
systemctl --user start plasmazones.service
```

Reload the `kwin_effect_plasmazones` effect or log out/in afterward. This preserves profiles, rules, layouts, and shortcuts but removes remembered placements.

### The grid or spanning overlay does not appear

Switch to FancyZones with `Super+Shift+T`. Use `Super+G` for the picker. `Ctrl+Alt` spanning requires adjacent zones in the active fixed layout.

### Keyboard focus snaps back

Use KDE **Click to focus** and keep both PlasmaZones focus-follows-mouse settings off.

### Windows move erratically before settling

Use the included mode helper and profile together. Omarchy uses all-at-once placement, disables PlasmaZones window animations through the `Stable geometry in Omarchy mode` rule, respects minimum sizes, and floats windows beyond the six-slot cap. FancyZones restores the normal animation cascade.

### A tiled window still moves or resizes

Confirm the window is not floating, then check that the guard is loaded:

```bash
qdbus6 org.kde.KWin /Scripting \
  org.kde.kwin.Scripting.isScriptLoaded plasmazones-omarchy-lock
```

The answer should be `true`. The guard deliberately does nothing in FancyZones mode.

## Validated behavior

- Six temporary Konsole windows were opened on each 150%-scaled monitor while ChatGPT stayed open.
- The unstable Dwindle baseline kept changing AORUS geometries for roughly 44–47 seconds. Master + Stack plus simultaneous placement stopped post-launch motion after the initial configure burst.
- AORUS used Master + Stack; Dell used BSP. Both kept at least five tiled windows, with excess windows floating instead of violating minimum sizes.
- Steam opened at 1111×660, matched the Omarchy-only float rule, and did not enter either tiling tree.
- The mode switch preserved each monitor's fixed layout and automatic algorithm.

To roll back, disable PlasmaZones and the guard, restore the backed-up files, and restore any desired KDE shortcuts. Re-enable at most one automatic tiler.
