# Install the patched Wallpaper Engine KDE plugin on CachyOS

This is the reinstall procedure for the experimental
[RainyPixel-based fork](https://github.com/pedroribeiro1718/wallpaper-engine-kde-plugin)
that fixes a reproduced `plasmashell` crash during frequent synchronized scene
changes. It is currently intended only for Plasma 6 on CachyOS/Arch-based
systems. The patch was produced by OpenAI Codex, has no qualified maintainer,
and is not production-ready.

## Install

Install the basic build tools, then build the repository's own Pacman package:

```bash
sudo pacman -S --needed base-devel git

git clone --recurse-submodules \
  https://github.com/pedroribeiro1718/wallpaper-engine-kde-plugin.git
cd wallpaper-engine-kde-plugin

# This must print the descriptor-layout reset added by the fix.
git grep -n 'descriptor_layouts.clear' -- \
  src/backend_scene/src/Vulkan/GraphicsPipeline.cpp

cd packaging
makepkg -si
systemctl --user restart plasma-plasmashell.service
```

Do not install `wallpaper-engine-kde-plugin` or
`wallpaper-engine-kde-plugin-git` from the AUR for this purpose; those packages
do not contain this patch. Pacman may ask to replace a conflicting installation.

Confirm the patched package is installed:

```bash
pacman -Q wallpaper-engine-kde-plugin-rainypixel-patched-git
```

## Configure

1. Open **Configure Desktop and Wallpaper** and select **Wallpaper Engine for
   KDE**.
2. Set the Steam library, normally `~/.local/share/Steam`.
3. Use the plugin's **Global Mode** when the same scene must be synchronized
   across multiple monitors.

The install does not replace Plasma's existing wallpaper selection.

## Update or roll back

To update:

```bash
cd wallpaper-engine-kde-plugin
git pull --ff-only
git submodule update --init --recursive
cd packaging
makepkg -si
systemctl --user restart plasma-plasmashell.service
```

To remove it:

```bash
sudo pacman -R wallpaper-engine-kde-plugin-rainypixel-patched-git
systemctl --user restart plasma-plasmashell.service
```

The source-only upstream submission is
[RainyPixel PR #20](https://github.com/RainyPixel/wallpaper-engine-kde-plugin/pull/20).
