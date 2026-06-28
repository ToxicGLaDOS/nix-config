# This file creates the simplest image possible while
# adding a user with our ssh key so we can boot
# and configure the machine remotely
# You can build the image with this command:
# env NIX_PATH="nixos-config=<path/to/this/file>:nixpkgs=channel:nixos-26.05" nixos-rebuild build-image --image-variant sd-card
{ config, pkgs, ... }:

{
  # Recommended by warning message
  # What this actually does... :shrug:
  boot.zfs.forceImportRoot = false;

  # Not having this results in building an image
  # for the platform of machine which is making the sd-image
  # probably x86_64.
  # We want a raspberry pi image, so we need this
  nixpkgs = {
    hostPlatform = "aarch64-linux";
  };

  # == This is the meat of what we're trying to do here ==

  # We need this to run nixos-rebuild with the local machine as the build host
  # With this you can run
  # nixos-rebuild switch -I nixos-config=configuration.nix --target-host jeff@raspberry0
  # If you try this without being a trusted-user you'll get this error:
  # error: cannot add path '/nix/store/09w0mk3fqcwblx2px3b8qzh4r6r6cna0-users-groups.json' because it lacks a signature by a trusted key
  # Without this you can run this instead:
  # nixos-rebuild switch -I nixos-config=configuration.nix --target-host jeff@raspberry0 --build-host jeff@raspberry0
  # https://mynixos.com/nixpkgs/option/nix.settings.trusted-users
  nix.settings.trusted-users = [
    "jeff"
  ];

  # Create our user
  users.users.jeff = {
    openssh.authorizedKeys.keys = [
      # Replace this with your key
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICEKeehduYbblNR/+ylIh83qC0JUbawjJU6hU5kF8EGl jeff@nixos"
    ];
    isNormalUser = true;
    # Add ourselves to wheel because we give wheel
    # password-less sudo access
    extraGroups = [ "wheel" ];
  };

  # Allow our user access without a password
  security.sudo.wheelNeedsPassword = false;
  
  # Enable ssh so we can do the real configuration remotely
  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
