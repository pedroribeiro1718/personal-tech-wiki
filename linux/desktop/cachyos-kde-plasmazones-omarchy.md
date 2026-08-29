# PlasmaZones Hybrid on KDE

[PlasmaZones Hybrid](https://github.com/pedroribeiro1718/plasmazones-hybrid) keeps KDE/KWin and provides two coordinated modes:

- **Omarchy:** automatic keyboard tiling with fixed tiled windows.
- **FancyZones:** a drag overlay, six-zone layout, and multi-zone spanning.

Switching modes with `Super+Shift+T` automatically rearranges existing windows. The setup is mixed-DPI aware: larger logical workspaces use BSP; smaller ones use Master + Stack.

## Install

Install [PlasmaZones](https://phosphor-works.github.io/plasmazones/getting-started/), disable other KWin tilers, then run:

```bash
git clone https://github.com/pedroribeiro1718/plasmazones-hybrid.git
cd plasmazones-hybrid
./install.sh
```

No `sudo` is used. The installer backs up affected user configuration and includes a reversible `./uninstall.sh`.

See the [repository README](https://github.com/pedroribeiro1718/plasmazones-hybrid#readme) for shortcuts, behavior, troubleshooting, and implementation details.
