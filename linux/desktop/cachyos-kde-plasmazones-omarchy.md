# PlasmaZones on KDE: Omarchy tiling and FancyZones snapping

This setup keeps KDE Plasma and KWin while adding two predictable window-management modes:

| Mode | Behavior |
| --- | --- |
| **Omarchy** | Automatic Dwindle/BSP tiling with keyboard focus, swaps, gaps, and floating exceptions |
| **FancyZones** | Fixed zones, a drag overlay, and multi-zone spanning |

The reference system is CachyOS, Plasma 6, Wayland, and mixed-DPI monitors.

## Preconditions

- Install and enable [PlasmaZones](https://phosphor-works.github.io/plasmazones/getting-started/).
- Use only one automatic tiler. Remove or disable Krohnkite, KZones, Polonium, and similar KWin scripts.
- Use KDE **Click to focus** and keep PlasmaZones **Focus follows mouse** off.
- Back up `~/.config/plasmazones/`, `~/.config/kglobalshortcutsrc`, `~/.config/kwinrc`, and `~/.config/kwinrulesrc`.
- Review KDE Window Rules that force borders, geometry, maximization, or a monitor.

The profile cannot remove competing scripts, release KDE shortcuts, or assign layouts to monitor/desktop/activity contexts.

## Install

1. Import [`omarchy-on-kde-profile.json`](../../examples/plasmazones/omarchy-on-kde-profile.json) in **PlasmaZones Settings → Profiles**.
2. Select **Omarchy on KDE**. PlasmaZones applies profile edits immediately; there is no Save button.
3. Assign a snapping layout and tiling algorithm to every monitor context in **Overview**.
4. Install the two-mode helper:

   ```bash
   install -Dm755 examples/plasmazones/plasmazones-mode-toggle \
     ~/.local/bin/plasmazones-mode-toggle
   install -Dm644 examples/plasmazones/plasmazones-mode-toggle.desktop \
     ~/.local/share/applications/plasmazones-mode-toggle.desktop
   kbuildsycoca6 --noincremental
   ```

5. In **System Settings → Keyboard → Shortcuts**, clear `Super+Shift+T` from PlasmaZones' three-mode cycle and assign it to **Toggle PlasmaZones Mode**.

The profile uses 8 px inner/12 px outer gaps, keyboard-stable focus, hidden tiled title bars, 2 px borders, rounded corners, and an Omarchy-only floating rule for the Steam client.

## Daily use

Press `Super+Shift+T` to switch all current monitors together:

- **Omarchy mode:** new normal windows tile automatically. `Super+G` selects Dwindle, BSP, or another automatic algorithm.
- **FancyZones mode:** `Super+G` selects a fixed layout. Hold `Alt` while dragging for the overlay; hold `Ctrl+Alt` and drag across adjacent zones to span them.

PlasmaZones does not show the fixed-zone drag overlay while automatic tiling owns the screen. Multi-zone spans stay within one physical monitor.

## Keyboard cheat sheet

`Super` is KDE's `Meta` key.

| Shortcut | Action |
| --- | --- |
| `Super+Arrow` | Focus in that direction |
| `Super+Shift+Arrow` | Swap the focused window in that direction |
| `Super+G` | Open the layout/algorithm picker |
| `Super+Shift+G` | Open the zone editor |
| `Super+T` | Toggle the focused window between tiled and floating |
| `Super+-` / `Super+=` | Decrease/increase the automatic split ratio |
| `Super+Ctrl+T` | Retile the current context |
| `Super+Shift+T` | Toggle Omarchy/FancyZones mode on all monitors |

| FancyZones gesture | Action |
| --- | --- |
| `Alt` + drag | Show the zone overlay and snap |
| `Ctrl+Alt` + drag | Span adjacent zones |

## Release conflicting KDE shortcuts

Clear these current bindings in **System Settings → Keyboard → Shortcuts**:

| PlasmaZones chord | KDE action to clear |
| --- | --- |
| `Super+T` | KWin **Edit Tiles** |
| `Super+G` | KWin **Grid View** |
| `Super+Arrow` | KWin **Quick Tile Window…** |
| `Super+Shift+Left/Right` | KWin **Move Window to Previous/Next Screen** |
| `Super+-` / `Super+=` | KWin desktop zoom |
| `Super+Ctrl+T` | Wacom **Enable/Disable Touch Tool**, if present |

Defaults may remain listed; remove the active/current assignments. Verify the intended owner under the **PlasmaZones** component afterward.

## Mixed DPI and application constraints

Layouts use each output's **logical** geometry. A window can therefore fit a tile on one scaled display but not another.

Steam is the practical example: its client advertises a minimum logical size larger than a half-tile on the smaller logical output. KWin must honor that client minimum, so forcing geometry makes Steam overlap neighboring tiles. A global `STEAM_FORCE_DESKTOPUI_SCALING` value is also wrong for displays with different scaling.

The profile instead floats only app ID `steam` when the mode is `tiling`. This follows Omarchy's current Steam-client convention and leaves `steam_app_*` game windows alone. In FancyZones mode the client remains managed and can still be dragged into a sufficiently large zone.

Do not hard-route Steam to a connector unless that placement is intentional; connector names, primary-output state, and logical geometry can change. Use `Super+T` for any other application whose minimum size cannot fit its tile.

### Why frame resizing remains enabled

Omarchy mode constrains placement, not a client's legal size range. PlasmaZones detects an interactive border resize and reflows neighboring tiled windows around it. Disabling KWin resizing globally would also break floating windows, dialogs, and mixed-DPI recovery without solving hard client minimums.

Dragging a tiled window is configured to reorder the tree. Use `Super+T` before free-form moving or sizing, then press it again to rejoin the layout.

## Troubleshooting

### The grid or spanning overlay does not appear

Switch to **FancyZones mode** with `Super+Shift+T`. Use `Super+G` for the picker and `Super+Shift+G` for the editor. `Ctrl+Alt` spanning needs adjacent zones in the active fixed layout.

### Keyboard focus snaps back

Use KDE **Click to focus** and disable PlasmaZones **Focus follows mouse**. Pointer-driven focus can reclaim focus as soon as the shortcut is released.

### A shortcut does nothing

Search the exact chord in KDE Shortcuts and remove every competing current assignment. Split-ratio and retile actions only operate in Omarchy mode.

### A window has no border

Set **Appearance → Window appearance → Border → Apply to** to **All windows**. Then inspect any application-specific KDE Window Rule and the window's floating state.

### A tiled application overlaps its neighbors

The application probably enforces a minimum size larger than its logical tile. Float it with `Super+T`, enlarge the layout cell, or add a mode-scoped PlasmaZones float rule. Do not use a global scaling override on mixed-DPI outputs.

### Windows remain floating after returning to Omarchy mode

Focus an affected window, press `Super+T`, then press `Super+Ctrl+T` once.

## Reference-system changes

- Removed Krohnkite, KZones, and Polonium.
- Released the KDE shortcut collisions listed above.
- Assigned both monitor contexts and installed the two-mode helper.
- Kept click-to-focus and disabled pointer-driven focus.
- Applied borders to all windows and cleared stale Zen Browser floating state.
- Added a `steam` + `tiling` → **Float** PlasmaZones rule; no global Steam scale or monitor route is used.

To roll back, disable PlasmaZones, restore the backed-up configuration files, and restore any desired KDE shortcuts. Re-enable at most one automatic tiler.
