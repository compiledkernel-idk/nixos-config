{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      max-jobs = 16;
      cores = 16;
      download-buffer-size = 268435456;
      http-connections = 50;
      trusted-users = [ "root" "@wheel" ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://cuda-maintainers.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 1;
    };
    initrd.systemd.enable = true;
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    kernelParams = [
      "quiet"
      "mitigations=off"
      "nowatchdog"
      "nmi_watchdog=0"
      "processor.max_cstate=1"
      "amd_pstate=active"
      "transparent_hugepage=always"
      "split_lock_detect=off"
      "fastboot"
      "noresume"
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
      "usbcore.autosuspend=-1"
      "acpi_enforce_resources=lax"
      # Additional perf params for 7800X3D
      "preempt=full"
      "tsc=reliable"
      "clocksource=tsc"
      "idle=nomwait"
      "pcie_aspm=off"
      # NVIDIA memory optimization
      "NVreg_UsePageAttributeTable=1"
    ];
    kernel.sysctl = {
      # VM tuning for 96GB RAM
      "vm.swappiness" = 1;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_ratio" = 10;
      "vm.dirty_background_ratio" = 5;
      "vm.dirty_writeback_centisecs" = 1500;
      "vm.page-cluster" = 0;
      "vm.max_map_count" = 2147483642;
      # Scheduler tuning
      "kernel.sched_autogroup_enabled" = 1;
      "kernel.sched_cfs_bandwidth_slice_us" = 3000;
      # Network performance
      "net.core.rmem_max" = 67108864;
      "net.core.wmem_max" = 67108864;
      "net.core.rmem_default" = 16777216;
      "net.core.wmem_default" = 16777216;
      "net.core.optmem_max" = 65536;
      "net.core.netdev_max_backlog" = 16384;
      "net.ipv4.tcp_rmem" = "4096 1048576 67108864";
      "net.ipv4.tcp_wmem" = "4096 1048576 67108864";
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_slow_start_after_idle" = 0;
      "net.ipv4.tcp_mtu_probing" = 1;
      "net.core.default_qdisc" = "fq";
      # FS limits
      "fs.inotify.max_user_watches" = 1048576;
      "fs.inotify.max_user_instances" = 8192;
      "fs.file-max" = 2097152;
      "fs.aio-max-nr" = 1048576;
    };
    initrd.kernelModules = [ ];
    kernelModules = [ "i2c-dev" "i2c-piix4" "kvm-amd" ];
    blacklistedKernelModules = [ "nouveau" ];
    tmp.useTmpfs = true;
    tmp.tmpfsSize = "16G";
  };

  hardware = {
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = true;  # Recommended for Ada Lovelace (RTX 40-series)
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
      forceFullCompositionPipeline = false;
    };
    openrazer.enable = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  services.tailscale.enable = true;

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
  };

  # ZRAM swap (faster than disk swap, good for 96GB RAM)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall.enable = true;
  };

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
    };
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      theme = "breeze";
    };
    desktopManager.plasma6.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
    fstrim.enable = true;
    thermald.enable = false;
    irqbalance.enable = true;
    earlyoom = {
      enable = true;
      freeMemThreshold = 3;
      freeSwapThreshold = 3;
    };
    udev.extraRules = ''
      ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="bfq"
    '';
    flatpak.enable = true;
    # Automatic process niceness daemon
    ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos;
    };
    mullvad-vpn.enable = true;
    tor.enable = true;
    hardware.openrgb.enable = true;
  };

  systemd = {
    services.NetworkManager-wait-online.enable = false;
    services.systemd-udev-settle.enable = false;
    settings.Manager = {
      DefaultTimeoutStartSec = "10s";
      DefaultTimeoutStopSec = "10s";
      RuntimeWatchdogSec = "0";
      RebootWatchdogSec = "0";
    };
  };

 

  security = {
    rtkit.enable = true;
    polkit.enable = true;
    pam.loginLimits = [
      { domain = "*"; type = "soft"; item = "nofile"; value = "524288"; }
      { domain = "*"; type = "hard"; item = "nofile"; value = "524288"; }
    ];
  };

  users.users.sultan = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" "render" "openrazer" "i2c" "libvirtd" "kvm" ];
    shell = pkgs.zsh;
  };

  programs = {
    zsh = {
      enable = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;
      interactiveShellInit = ''
        setopt CORRECT
        export SPROMPT="zsh: correct '%R' to '%r' [nyae]? "
      '';
      ohMyZsh = {
        enable = true;
        theme = "agnoster";
        plugins = [ "git" "docker" "kubectl" "fzf" "z" "sudo" ];
      };
      shellAliases = {
        nix-add = "~/nixos-config/nix-add.sh";
        nix-switch = "~/nixos-config/rebuild.sh";
        nix-config = "cd ~/nixos-config && code-cursor configuration.nix";
      };
    };
    git.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraCompatPackages = [
        pkgs.proton-ge-bin
      ];
    };
    gamemode.enable = true;
    dconf.enable = true;
    nix-ld.enable = true;
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };



  environment.systemPackages = with pkgs; [
    wget curl git htop btop fastfetch neofetch cpufetch
    firefox tor-browser ungoogled-chromium
    discord vesktop telegram-desktop signal-desktop
    vscode jetbrains.idea jetbrains.clion code-cursor
    kitty alacritty wezterm ghostty
    fzf ripgrep fd bat eza zoxide delta 
    unzip zip p7zip
    ntfs3g
    exfatprogs
    ffmpeg imagemagick
    vlc mpv obs-studio
    gimp inkscape blender
    libreoffice-qt
    docker docker-compose kubectl k9s
    python3 nodejs rustup go
    gcc clang cmake ninja meson gnumake
    gdb valgrind
    nasm yasm fasm
    radare2 ghidra rizin cutter
    hexedit xxd binutils patchelf
    strace ltrace
    elfutils bpftrace bcc
    qemu_kvm virt-manager virt-viewer bridge-utils
    nvidia-vaapi-driver nvtopPackages.full
    mangohud goverlay lutris heroic bottles wine winetricks
    protonup-qt gamescope
    scummvm dosbox-staging
    spotify
    thunderbird
    qbittorrent
    kdePackages.filelight baobab
    nh nix-output-monitor nvd
    starship direnv
    jq yq-go
    tmux screen
    tree ncdu
    duf dua
    procs
    bandwhich
    bottom
    hyperfine
    tealdeer
    wofi rofi
    swww hyprpaper
    hyprlock hypridle
    wl-clipboard cliphist
    grim slurp swappy
    mako libnotify
    brightnessctl playerctl
    networkmanagerapplet
    nwg-look
    thunar
    papirus-icon-theme
    adwaita-icon-theme
    qt6Packages.qt6ct
    adwaita-qt6
    kdePackages.polkit-kde-agent-1
    mullvad-vpn
    gh
    cifs-utils
    samba
    nmap
    polychromatic
    openrgb-with-all-plugins
    i2c-tools
    file
    pulseaudio
    raylib
    cloc
    mesa
    whois
    lmstudio
    linux-wallpaperengine
    mov-cli
    gparted
    ventoy-full
    elfutils
    
    
    tokei
    monero-gui
    gpu-screen-recorder
  ];

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.hack
      nerd-fonts.iosevka
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      ubuntu-classic
      inter
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Inter" "Noto Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
      };
      antialias = true;
      hinting.enable = true;
      subpixel.rgba = "rgb";
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  hardware.nvidia-container-toolkit.enable = true;

  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "ventoy-1.1.10"
    ];
  };

  fileSystems."/mnt/nas/data" = {
    device = "//192.168.1.24/nas_data";
    fsType = "cifs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=60" "x-systemd.mount-timeout=5s" "username=pi" "password=0507" "uid=1000" "gid=100" ];
  };

  fileSystems."/mnt/nas/data2" = {
    device = "//192.168.1.24/nas_data2";
    fsType = "cifs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=60" "x-systemd.mount-timeout=5s" "username=pi" "password=0507" "uid=1000" "gid=100" ];
  };

  system.stateVersion = "24.11";
}
