# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      <nixos-hardware/common/pc/laptop>
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];
  
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/home/jeff/projects/nix-config/${config.networking.hostName}/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];

  hardware.bluetooth.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  boot.binfmt.registrations.aarch64-linux = {
    interpreter = "${pkgs.pkgsStatic.qemu-user.override { hostCpuTargets = ["aarch64-linux-user"];}}/bin/qemu-aarch64";
    fixBinary = true;
    matchCredentials = true;
  };

  # This allows stuff like MakeMKV to see the bluray reader
  # It's not clear why I need this, but it worked!
  # The answer came from here: https://bbs.archlinux.org/viewtopic.php?pid=2226368#p2226368
  boot.kernelModules = [
    "sg"
  ];

  boot.supportedFilesystems = [ "nfs" ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    fuse
    # Add any missing dynamic libraries for unpackaged programs
    # here, NOT in environment.systemPackages
  ];

  networking.hostName = "lychee"; # Define your hostname.

  networking.hosts = {
    "144.202.9.49" = ["dragonfruit"];
  };

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
  
  services.rpcbind.enable = true; # needed for NFS

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  # Configure keymap in X11
  services.xserver = {
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [pkgs.cnijfilter2];

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    extraConfig.pipewire-pulse."fix-mopidy" = {
      pulse.properties = {
      # the addresses this server listens on
        server.address = [
            "unix:native"
            "tcp:4713"                         # IPv4 and IPv6 on all addresses
        ];
      };
    };
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  users.defaultUserShell = pkgs.fish;
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jeff = {
    isNormalUser = true;
    description = "Jeff";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      discord
      rust-analyzer # Rust language server
      cargo
      cargo-watch
      rustc
      gcc
      godot_4
      any-nix-shell
      pgcli
      tmux
      wl-clipboard
      inetutils
      tuxguitar
      unzip
      prismlauncher
      kubectl
      tiled
      aseprite
      obs-studio
      kdePackages.kdenlive
      mkvtoolnix
      tageditor
      yt-dlp
      imagemagick
      gimp
      osu-lazer-bin
      vlc
      android-studio


      # This is version 1.17.7
      # Later versions are broken on linux (unless you flash your drive with libredrive firmware maybe?)
      # https://forum.makemkv.com/forum/viewtopic.php?p=183190#p183190
      (import (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/ab7b6889ae9d484eed2876868209e33eb262511d.tar.gz";
      }) {config.allowUnfree = true;}).makemkv

      runelite
      bolt-launcher
      thunderbird

      skyemu

      gst_all_1.gst-plugins-rs
    ];
  };

  home-manager.users.jeff = { pkgs, ... }: {
    programs.direnv.enable = true;
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        any-nix-shell fish --info-right | source
        direnv hook fish | source
        function fish_prompt
          set -l namecol  white
          set -l dircol green
          set -l branchcol purple
          # Print username:
          set_color $namecol -b normal
          echo -n (whoami)":"

          # Print git_branch_name
          set_color $branchcol -b normal
          echo -n (git rev-parse --abbrev-ref HEAD 2>/dev/null)

          # Print a ":"
          set_color $namecol -b normal
          echo -n ":"

          # Print current directory
          set_color $dircol -b normal
          set working_dir (echo $PWD | sed -e "s|^$HOME|~|")
          echo -n "$working_dir"

          # Print a ">"
          set_color $namecol
          echo -n ">"
        end
        alias k kubectl
      '';
    };
    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "24.05";
      programs.neovim = {
      plugins = [
        pkgs.vimPlugins.lazy-nvim
      ];
      extraLuaConfig = builtins.readFile ../shared/nvim/init.lua;
      enable = true;
      viAlias = true;
      vimAlias = true;
    };
    programs.git = {
      enable = true;
      settings = {
        user = {
            name = "Jeff Smith";
            email = "ToxicGLaDOS@gmail.com";
        };
        push = { autoSetupRemote = true; };
      };
    };
  };

  programs.fish = {
    enable = true;
  };

  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    #remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    #dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };

  programs.git = {
    enable = true;
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
