# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ config, lib, pkgs, ... }:

let
  stableTarball =
    fetchTarball
      https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz;
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
    ];

  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/home/jeff/projects/nix-config/${config.networking.hostName}/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];


  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    #extraPackages = with pkgs; [
    #    vaapiIntel
    #    vaapiVdpau
    #    libvdpau-va-gl
    #  ];
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  # only needed if an actual amd gpu is in another pcie slot.
  boot.blacklistedKernelModules = [
    "amdgpu"
  ];

  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  boot.binfmt.registrations.aarch64-linux = {
    interpreter = "${pkgs.pkgsStatic.qemu-user.override { hostCpuTargets = ["aarch64-linux-user"];}}/bin/qemu-aarch64";
    fixBinary = true;
    matchCredentials = true;
  };


  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
        # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  boot.initrd.luks.devices."luks-b68cf105-2e59-4ef2-b5f0-a6e53840fc6f".device = "/dev/disk/by-uuid/b68cf105-2e59-4ef2-b5f0-a6e53840fc6f";
  networking.hostName = "papaya"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

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

  # Enable sddm display manager
  services.displayManager = {
    sddm.enable = true;
    defaultSession = "none+i3";
  };

  services.xserver = {
    enable = true;

    desktopManager = {
      xterm.enable = false;
    };

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu #application launcher most people use
        i3status # gives you the default i3 status bar
        i3lock #default i3 screen locker
        i3blocks #if you are planning on using i3blocks over i3status
     ];
    };
    xkb = {
      variant = "";
      layout = "us";
    };

    serverFlagsSection = ''
        Option "StandbyTime" "60"
        Option "SuspendTime" "60"
        Option "OffTime"     "60"
        Option "BlankTime"   "60"
    '';
  };

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = [ pkgs.gutenprintBin pkgs.canon-cups-ufr2 ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    # low latency maybe fixes crackling audio in games?
    extraConfig.pipewire-pulse."92-low-latency" = {
      context.modules = [
        {
          name = "libpipewire-module-protocol-pulse";
          args = {
            pulse.min.req = "32/48000";
            pulse.default.req = "32/48000";
            pulse.max.req = "32/48000";
            pulse.min.quantum = "32/48000";
            pulse.max.quantum = "32/48000";
          };
        }
      ];
      stream.properties = {
        node.latency = "32/48000";
        resample.quality = 1;
      };
    };

    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
    };
  };

  programs.fish.enable = true;

  xdg.portal = {
    config.common.default = "*";
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    xdgOpenUsePortal = true;
  };

  home-manager.users.jeff = { pkgs, ... }: {
    nixpkgs.config.allowUnfree = true;
    home.packages = with pkgs; [
      kdePackages.kate
      discord # REMINDER: Make sure to disable hardware acceleration because it makes discord fail to open after reboot
      thunderbird
      any-nix-shell
      git
      restic
      # bambu-studio # bambu-studio is broken, so I installed it with flatpack :shrug: (flatpak run com.bambulab.BambuStudio)
      unzip
      vlc
      freecad
      scrot
      tuxguitar
      prismlauncher
      godot_4
      python3
      kubectl
      runelite
      flatpak
      gnome-software # Required for graphical flatpaks
      bolt-launcher
      openutau
      audacity

      ardour
      reaper
      # vst's and ardour plugins:
      #distrho
      ladspaPlugins
      calf
      neural-amp-modeler-lv2

      podman-compose
    ];

    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        function fish_prompt
          set -l namecol  white
          set -l dircol green
          set -l branchcol purple
          set -l proxycol red
          set -l timecol blue
          # Print username:
          set_color $namecol -b normal
          echo -n (whoami)":"

          # Print time
          set_color $timecol -b normal
          echo -n "["(date +%H:%M:%S)"]"
          set_color $namecol -b normal
          echo -n ":"

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
        fish_add_path /home/jeff/.local/bin
      '';
      shellInit = ''
        any-nix-shell fish --info-right | source
        set -x EDITOR vim
      '';
    };

    programs.kitty = {
      enable = true;
      settings = {
        # Fixes slow startup after suspend
        # https://github.com/kovidgoyal/kitty/issues/8251
        sync_to_monitor = false;
      };
    };

    programs.neovim = {
      plugins = [
        pkgs.vimPlugins.lazy-nvim
      ];
      extraLuaConfig = builtins.readFile ./nvim/init.lua;
      enable = true;
      viAlias = true;
      vimAlias = true;
    };

    # Install firefox.
    programs.firefox.enable = true;

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "24.05";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jeff = {
    isNormalUser = true;
    description = "Jeff Smith";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIniX9/ja773MHs/7Y5VcJGwbqrr0ToV8vSgQ4GuTCGu"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCkgq/hZpjGZSeUR6knI1MVDQwz/BLMVmrONtoK0n81aN2hvHqwRXM0CLEDoDBGHeFhyR1m4FnlI5or1MM9S4KNCojQu7wwLM5gIjtK6PyIFhWmgMNrjY+RdgLbWLqaP86tVdpFkqzgSe/xY7lwj/sVBNeRLhG2KnDQe0lSlD8dVpf1Gs3MFSxmaIKoQvyy1HQu8CdGUVoa1JEBnkmbP8NH7rd89i+AcDsLE8BohyK2ch5ZC8YaT4qse7yNVP4wRPoptnQfJFYacveS6EI5Da+pE3+RUyHfIHh4M1kYndG2ndRqcvmTpkWbYxh6Lv0VJSwNN6yjDJWYnDbYg3pVI7CuEfAOJUF0wiUV0R5qtAm97qPJuE8Ejyb7spSE7kRdv3CaQOSGgFv1l/F9NrY5i0wwyxHpT6LINHXjP3k/EIV+DVk42BunkT09Ib8a/VbsuVD69P7YtAc/8cX0lpYn5bjPcjAcrjRykRGrN3V+v/JpOcGrPmEhTO9F058OuBfMO0s="
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICEKeehduYbblNR/+ylIh83qC0JUbawjJU6hU5kF8EGl"
    ];
  };

  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      stable = import stableTarball {
        config = config.nixpkgs.config;
      };
    };
  };


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    canon-cups-ufr2
    ntfs3g
    qemu-user
  #  wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    # require public key authentication for better security
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    #settings.PermitRootLogin = "yes";
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  networking.firewall.allowedTCPPorts = [ 5001 5173 ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
