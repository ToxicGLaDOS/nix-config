# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "cherry";

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jeff = {
    isNormalUser = true;
    description = "jeff";
    extraGroups = [ "wheel" ]; # Sudo access
    shell = pkgs.bash;
    home = "/home/jeff";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIniX9/ja773MHs/7Y5VcJGwbqrr0ToV8vSgQ4GuTCGu"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCkgq/hZpjGZSeUR6knI1MVDQwz/BLMVmrONtoK0n81aN2hvHqwRXM0CLEDoDBGHeFhyR1m4FnlI5or1MM9S4KNCojQu7wwLM5gIjtK6PyIFhWmgMNrjY+RdgLbWLqaP86tVdpFkqzgSe/xY7lwj/sVBNeRLhG2KnDQe0lSlD8dVpf1Gs3MFSxmaIKoQvyy1HQu8CdGUVoa1JEBnkmbP8NH7rd89i+AcDsLE8BohyK2ch5ZC8YaT4qse7yNVP4wRPoptnQfJFYacveS6EI5Da+pE3+RUyHfIHh4M1kYndG2ndRqcvmTpkWbYxh6Lv0VJSwNN6yjDJWYnDbYg3pVI7CuEfAOJUF0wiUV0R5qtAm97qPJuE8Ejyb7spSE7kRdv3CaQOSGgFv1l/F9NrY5i0wwyxHpT6LINHXjP3k/EIV+DVk42BunkT09Ib8a/VbsuVD69P7YtAc/8cX0lpYn5bjPcjAcrjRykRGrN3V+v/JpOcGrPmEhTO9F058OuBfMO0s="
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICEKeehduYbblNR/+ylIh83qC0JUbawjJU6hU5kF8EGl"
    ]; 
  };

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [ 
    neovim
  ];

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # List services that you want to enable:
  services = {
    openssh = {
      enable = true;
      # require public key authentication for better security
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.11"; # Did you read the comment?

}
