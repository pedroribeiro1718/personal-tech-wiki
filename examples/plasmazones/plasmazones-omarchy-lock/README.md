# PlasmaZones Omarchy Mouse Lock

- FancyZones mode (`mode = 0`) is untouched.
- Omarchy mode (`mode = 1`) blocks mouse dragging and frame resizing for tiled windows.
- Explicitly floating windows remain movable and resizable.

The KWin script resolves PlasmaZones state per output and virtual desktop. It uses logical output identity rather than pixel coordinates, so mixed-DPI displays need no special case.

It clears PlasmaZones' in-flight drag transaction instead of calling `cancelSnap()`. On an auto-tiling screen, `cancelSnap()` can otherwise turn a blocked drag into a floating window when the mouse button is released.
