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

## Preconditions and tradeoffs

> **The JSON profile is not a complete system migration.** It contains
> PlasmaZones preferences and PlasmaZones shortcut definitions. It cannot
> disable other KWin tilers, release KDE global shortcuts, assign placement
> modes to screens, or change KWin window rules.

Before importing the profile, account for these machine-level conditions:

1. **Use only one automatic tiling engine.** Disable or uninstall competing
   KWin scripts such as Krohnkite, KZones, or Polonium before enabling
   PlasmaZones. Two placement engines can move the same window, steal focus,
   or immediately undo one another's layout decisions.
2. **Give the chosen chords to PlasmaZones.** KDE's global shortcut service
   must release any existing owners listed in the table below. Importing the
   profile does not do this for you.
3. **Assign every intended display context.** Each relevant combination of
   screen, virtual desktop, and activity must use **Tiling** mode with the
   **Dwindle** placement algorithm. These assignments are local state and are
   not carried by the profile.
4. **Use stable keyboard focus semantics.** The reference setup uses KDE's
   normal click-to-focus behavior and disables PlasmaZones' focus-follows-mouse
   option. Otherwise, moving focus with the keyboard can appear to work only
   until the shortcut is released, when the pointer's window takes focus back.
5. **Review KWin window rules.** Rules that force an application to be
   borderless, floating, maximized, or assigned to a particular screen can
   override the profile. App-specific exceptions are not portable and should
   be assessed on the target machine.

### KDE shortcuts relinquished by the reference setup

These are intentional tradeoffs, not accidental losses:

| Chord | Previous KDE owner or behavior | PlasmaZones behavior |
| --- | --- | --- |
| `Super+T` | KWin **Edit Tiles** | Toggle floating |
| `Super+G` | KWin **Grid View** | Open layout picker / show the grid |
| `Super+Arrow` | KWin **Quick Tile** | Focus a window directionally |
| `Super+Shift+Left/Right` | Move window to previous/next screen | Swap the focused window directionally |
| `Super+-` / `Super+=` | KWin desktop zoom | Adjust the Dwindle split ratio |
| `Super+Ctrl+T` | Wacom **Toggle touch tool**, when present | Retile the current context |

`Super++` remains available for KWin zoom-in on the reference system. The
Wacom conflict applies only when that component and shortcut are present.

### Back up before changing host-level settings

Keep a copy of the following before removing scripts, shortcuts, or rules:

- `~/.config/plasmazones/`
- `~/.config/kglobalshortcutsrc`
- `~/.config/kwinrc`
- `~/.config/kwinrulesrc`

The first path holds PlasmaZones state; the remaining files hold KDE shortcut,
window-management, and window-rule state. Do not publish these files without
reviewing them for machine-specific or personal data.

### What travels with the profile

| Included in the JSON profile | Remains machine-local |
| --- | --- |
| PlasmaZones gaps and Dwindle behavior | PlasmaZones installation and service state |
| PlasmaZones shortcut choices | KDE/KGlobalAccel shortcut removals |
| PlasmaZones decorations and animation preferences | Competing KWin-script installation or enablement |
| PlasmaZones focus preference | Screen, desktop, and activity mode assignments |
| General PlasmaZones placement preferences | KWin window rules and current floating/session state |

### Rollback

To return toward the stock KDE behavior:

1. Disable PlasmaZones or switch the affected contexts from **Tiling** to
   **Snapping**.
2. Restore the backed-up configuration files, or reassign the displaced KDE
   actions in **System Settings → Keyboard → Shortcuts**.
3. Re-enable at most one previous tiling script if it is still wanted.
4. Log out and back in if KWin or the global shortcut service retains stale
   runtime state.

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

Complete the relevant preconditions above first. In particular, an imported
profile can display its shortcut choices while KDE's global shortcut service
still owns the same chords.

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
- keyboard-stable focus with focus-new-windows enabled;
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
- Removed the obsolete Krohnkite, KZones, and Polonium scripts. Disabled but
  still installed scripts should also be checked after a Plasma or KWin
  restart; stale, unbound shortcut records are harmless, active handlers are
  not.
- Created and activated the **Omarchy on KDE** profile.
- Assigned both monitors, in their active desktop/activity contexts, to
  Dwindle tiling.
- Removed every KDE global-shortcut collision listed above.
- Assigned `Super+G` to the PlasmaZones picker and `Super+Shift+G` to its
  editor.
- Kept KDE on click-to-focus and disabled PlasmaZones focus-follows-mouse so
  directional keyboard focus persists after releasing the chord.
- Changed border scope from tiled-only to all windows.
- Increased inactive-border visibility.
- Cleared Zen Browser's stale floating state and retiled the display.
- Saved rollback copies before changing PlasmaZones and KDE shortcut files.

The border and Zen Browser items are reference-machine corrections, not
universal requirements. Apply them only when the corresponding application
symptom exists.

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
