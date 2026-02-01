
.. raw:: html

   <div align="center">

=============
nixos-config
=============

**my nixos setup**

*one config, any machine, always the same*

.. raw:: html

   </div>

--------

About
-----

This is my NixOS config. It has everything for my system. All the packages, settings, drivers, fonts, everything.

If my computer breaks I just run one command and its back to normal.

--------

What's inside
-------------

::

    nixos-config/
    ├── configuration.nix      the main config
    ├── hardware-configuration.nix   hardware stuff
    ├── flake.nix              dependencies
    ├── bootstrap.sh           recovery script
    ├── nix-add.sh             adds packages
    ├── rebuild.sh             rebuilds the system
    └── hyprland.conf          window manager

--------

The system
----------

**Hardware**
    AMD Ryzen 7800X3D, 96GB RAM, NVIDIA RTX 40-series

**Kernel**
    XanMod with performance tweaks

**Desktop**
    KDE Plasma 6 and Hyprland

**Shell**
    Zsh with Oh My Zsh

**Editors**
    Neovim, VS Code, JetBrains

**Virtualization**
    Docker and QEMU

**Gaming**
    Steam, Proton-GE, MangoHud, Gamescope, Lutris, Heroic

--------

Fresh install
-------------

Boot into NixOS live USB. Connect to internet. Open terminal.

Run this::

    curl -fsSL https://raw.githubusercontent.com/compiledkernel-idk/nixos-config/master/bootstrap.sh | bash

It does everything for you:

1. Clones this repo to ``~/nixos-config``
2. Makes the hardware config for your machine
3. Sets up symlinks
4. Rebuilds the system

Reboot when its done.

--------

Daily usage
-----------

**Adding packages**

::

    nix-add neofetch

Adds the package and rebuilds.

**Rebuilding**

::

    ./rebuild.sh

Rebuilds and commits to git.

--------

Structure
---------

**configuration.nix**
    The main file. Has everything.

**hardware-configuration.nix**
    Auto generated for your machine. Dont edit this.

**flake.nix**
    Dependencies and stuff.

**bootstrap.sh**
    Recovery script. Makes a fresh install into my setup.

**rebuild.sh**
    Rebuilds with syntax checking and git commits.

**nix-add.sh**
    Adds packages to the config.

--------

Performance tuning
------------------

This config is fast:

- XanMod kernel
- CPU governor set to performance
- ZRAM swap
- Ananicy for process priority
- TCP BBR
- Low swappiness
- NVMe and SATA scheduler tweaks
- NVIDIA open drivers

--------

License
-------

MIT. Use it however you want.

--------

.. raw:: html

   <div align="center">

*made for me but maybe useful for you too*

.. raw:: html

   </div>
