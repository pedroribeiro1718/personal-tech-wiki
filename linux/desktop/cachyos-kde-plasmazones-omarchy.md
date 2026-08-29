# Omarchy-style keyboard tiling on KDE with PlasmaZones

This setup keeps KDE Plasma and KWin while adding an Omarchy/Hyprland-like
keyboard workflow through
[PlasmaZones](https://github.com/fuddlesworth/PlasmaZones). It combines Dwindle
auto-tiling with a FancyZones-style layout picker, drag overlay, and multi-zone
spanning.

The reference system is CachyOS with Plasma 6 on Wayland. The final setup uses
the importable
[`omarchy-on-kde-profile.json`](../../examples/plasmazones/omarchy-on-kde-profile.json)
profile included in this repository.

## Keyboard cheat sheet

`Super` is KDE's name for the `Meta` key.

| Shortcut | Action |
| --- | --- |
| `Super` + `Left` | Focus the window to the left |
| `Super` + `Right` | Focus the window to the right |
| `Super` + `Up` | Focus the window above |
| `Super` + `Down` | Focus the window below |
| `Super` + `Shift` + `Left` | Swap the focused window left |
| `Super` + `Shift` + `Right` | Swap the focused window right |
| `Super` + `Shift` + `Up` | Swap the focused window upward |
| `Super` + `Shift` + `Down` | Swap the focused window downward |
| `Super` + `G` | Show the PlasmaZones layout grid/picker |
| `Super` + `Shift` + `G` | Open the PlasmaZones zone editor |
| `Super` + `T` | Toggle the focused window between tiled and floating |
| `Super` + `-` | Decrease the Dwindle master/split ratio |
| `Super` + `=` | Increase the Dwindle master/split ratio |
| `Super` + `Shift` + `T` | Cycle Snapping → Tiling → Scrolling |
| `Super` + `Ctrl` + `T` | Retile all managed windows |

### Mouse-assisted FancyZones controls

| Gesture | Action |
| --- | --- |
| Hold `Alt` while dragging | Show the live zone overlay |
| Hold `Alt` + `Ctrl` while dragging across zones | Span adjacent zones |

## Install and import

Install and enable PlasmaZones using its official
[Getting Started guide](https://phosphor-works.github.io/plasmazones/getting-started/).
It runs as a user-session service and does not require `sudo` for profile or
shortcut changes.

Then import the profile:

1. Download
   [`omarchy-on-kde-profile.json`](../../examples/plasmazones/omarchy-on-kde-profile.json).
2. Open **PlasmaZones Settings → Profiles**.
3. Import the downloaded JSON file.
4. Select **Omarchy on KDE** and activate it.
5. In **Overview**, assign each monitor/desktop to **Tiling** with the
   **Dwindle** algorithm.

The profile configures:

- one Dwindle master window;
- 8 px inner and 12 px outer gaps;
- a 50% initial split with 5% adjustment steps;
- focus-follows-mouse and focus-new-windows;
- insertion after the focused window and drag-to-reorder behavior;
- hidden title bars for tiled windows;
- 2 px borders on all windows, including floating windows;
- blue active and visible gray inactive borders; and
- a 10 px corner radius with a 180 ms focus fade.

## Daily use

Normal application windows join the Dwindle tree automatically. Use
`Super` + an arrow to move focus and add `Shift` to move the focused window
within the tree.

`Super` + `G` displays the visual layout picker. Choose a layout with the mouse
or arrow keys. `Super` + `Shift` + `G` opens the editor when the zone geometry
itself needs to change.

Use `Super` + `T` for dialogs, media players, picture-in-picture windows, or
anything else that should float. Press it again to return the window to the
tiling tree.

Use `Super` + `-` or `Super` + `=` to change the main split. The effect is most
obvious with at least two tiled windows. Use `Super` + `Ctrl` + `T` to rebuild
the layout if geometry becomes stale.

`Super` + `Shift` + `T` changes the entire placement engine. Keep the screen in
**Tiling** for this workflow. If it is pressed accidentally, continue cycling
until the PlasmaZones OSD reports **Tiling**.

## Remove KDE shortcut conflicts

KDE ships several global shortcuts that overlap the profile. In **System
Settings → Keyboard → Shortcuts**, remove the current assignments below. Leave
their defaults intact if KDE presents current and default bindings separately.

### KWin

- **Edit Tiles** — remove `Super+T`
- **Grid View** — remove `Super+G`
- **Quick Tile Window Left/Right/Top/Bottom** — remove `Super+Arrow`
- **Move Window to Previous/Next Screen** — remove
  `Super+Shift+Left/Right`
- **Zoom Out** — remove `Super+-`
- **Zoom In** — remove `Super+=`; `Super++` may remain

### Wacom Tablet

- **Enable/Disable the Touch Tool** — remove `Super+Ctrl+T`

Afterward, verify that the corresponding shortcuts under the **PlasmaZones**
component match the cheat sheet. KDE's global accelerator can retain the same
chord for multiple actions, but only one owner receives it reliably.

## Changes made on the reference system

- Installed and enabled PlasmaZones.
- Removed the obsolete Krohnkite, KZones, and Polonium scripts.
- Created and activated the **Omarchy on KDE** profile.
- Assigned both monitors on the active desktop to Dwindle tiling.
- Removed every KDE global-shortcut collision listed above.
- Assigned `Super+G` to the PlasmaZones picker and `Super+Shift+G` to its
  editor.
- Changed border scope from tiled-only to all windows.
- Increased inactive-border visibility.
- Cleared Zen Browser's stale floating state and retiled the display.
- Saved rollback copies before changing PlasmaZones and KDE shortcut files.

## Troubleshooting

### A shortcut does nothing

Search for the exact chord in **System Settings → Keyboard → Shortcuts** and
remove every competing assignment. Also confirm that the affected screen is
currently in **Tiling** mode. Split-ratio and retile commands have nothing to
operate on while the screen is in Snapping mode.

### The layout grid does not appear

The old `Super+T` binding opened KWin's native tile editor and was removed to
make room for the PlasmaZones floating toggle. Use `Super+G` for the
PlasmaZones layout picker and `Super+Shift+G` for its zone editor.

### A window has no PlasmaZones border

Set **PlasmaZones Settings → Appearance → Window appearance → Border → Apply
to** to **All windows**. A tiled-only scope excludes deliberately floating
windows.

If one application still differs, inspect both **KDE Window Rules** and its
PlasmaZones floating state. An old application-specific no-border rule or a
restored floating state can survive other configuration changes.

### Windows stay floating after switching to Tiling

Focus each affected window and press `Super` + `T`, then use
`Super` + `Ctrl` + `T` once to rebuild the Dwindle tree.

