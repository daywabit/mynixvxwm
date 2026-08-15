{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader configuration (standard UEFI setup)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network & Timezone
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  time.timeZone = "Asia/Yangon";

  # Placing it here is totally valid:
  programs.bash.interactiveShellInit = ''
    fetch
  '';

  # 1. Enable Flake features so builtins.getFlake works
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";

  # Custom vxwm Package Overlay
  nixpkgs.overlays = [
    (final: prev: {
      vxwm = prev.stdenv.mkDerivation {
        pname = "vxwm";
        version = "unstable";

        src = prev.fetchFromGitHub {
          owner = "wh1tepearll";
          repo = "vxwm";
          rev = "main";
          hash = "sha256-W7BYpvU1oBfHN3QzZDvDhWVEQ4w/1hKRFdiDzpqfhJ8=";
        };

        # Inject custom config.h located in /etc/nixos/config.h
        postPatch = ''
          cp ${./config.h} config.h
        '';

        nativeBuildInputs = with prev; [ gnumake pkg-config ];
        buildInputs = with prev; [ libX11 libXft libXinerama ];

        makeFlags = [ "PREFIX=$(out)" ];

        # Generates desktop session entry for display managers
        postInstall = ''
          mkdir -p $out/share/xsessions
          cat > $out/share/xsessions/vxwm.desktop <<EOT
[Desktop Entry]
Name=vxwm
Comment=Versatile X Window Manager
Exec=$out/bin/vxwm
Type=Application
EOT
        '';

        passthru.providedSessions = [ "vxwm" ];
      };
    })
  ];

  # Display & X11 Configuration
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    desktopManager.cinnamon.enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # SDDM Display Manager & Custom Session Registration
  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = false;
    };
    sessionPackages = [ pkgs.vxwm ];
  };

  # Wayland Compositors
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  programs.niri.enable = true;

  # OpenGL / Graphics
  hardware.graphics.enable = true;

  # NVIDIA Driver & Hybrid Graphics Configuration (Offload Mode)
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Sound / PipeWire setup
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Hardware & Laptop Services
  services.asusd.enable = true;

  # File Manager Features (Thunar + USB/Trash support)
  programs.thunar.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # Applications
  programs.firefox.enable = true;
  programs.steam.enable = true;

  # Allow unfree packages (Needed for NVIDIA drivers & Steam)
  nixpkgs.config.allowUnfree = true;

  # User Account Configuration
  users.users.daywa = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    packages = with pkgs; [];
  };

  # System-wide packages
  environment.systemPackages = with pkgs; [
    # Custom WM & Terminals
    vxwm
    kitty
    alacritty
    discord
   
    screenfetch
    hyfetch    
    (builtins.getFlake "github:areofyl/fetch").packages.${system}.default   

    # Launchers, Wallpaper & Utilities
    rofi
    feh
    jq
    nitrogen
    fastfetch
    brave
    telegram-desktop
    wget
    unzip

    # Screenshot & Clipboard tools
    maim
    xclip
    libnotify
    xdotool
    viewnior

    # Hardware Controls
    brightnessctl
    pamixer

    # File Managers
    yazi
    ranger
    pcmanfm
    picom
    pywal
    # Core Build Tools & Git
    git
    curl
    gnumake
    pkg-config
  ];

  system.stateVersion = "24.05";
}
