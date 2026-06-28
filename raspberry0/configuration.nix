# Now that we have nixos running on the pi
# we can configure it with a mostly normal configuration.nix
# The main gotchas are importing <nixos-hardware/raspberry-pi/4>
# and setting boot.kernelPackages, but otherwise, you're basically
# free to do normal stuff here.
# Push this config to the target machine by running this on your machine:
# nixos-rebuild switch -I nixos-config=<path/to/this/file> --target-host <user>@<host> --sudo
{ config, pkgs, ... }:

{

  imports = [
    <nixos-hardware/raspberry-pi/4>
    ./hardware-configuration.nix
  ];

  boot = {
    # Required for mounting nfs shares from the NAS
    supportedFilesystems = [ "nfs" ];

    # Not setting this value results in compiling the linux kernel
    # which takes many hours.
    kernelPackages = pkgs.linuxPackages;
  };

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

  security.sudo.wheelNeedsPassword = false;
  users.users.jeff = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICEKeehduYbblNR/+ylIh83qC0JUbawjJU6hU5kF8EGl jeff@papaya"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIniX9/ja773MHs/7Y5VcJGwbqrr0ToV8vSgQ4GuTCGu jeff@laptop"
    ];

    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  environment.systemPackages = with pkgs; [
    neovim
    k3s
  ];

  # k3s uses containerd, but we need docker for
  # docker builds in drone
  virtualisation.docker.enable = true;

  services = {
    openssh.enable = true;
    k3s = {
      enable = true;
      manifests = {
        cert-persistence.source = ./k3s/cert-persistence.yaml;
        traefik-customization.source = ./k3s/traefik-customization.yaml;
      };
    };
  };

  # TODO: There seems to be a bug where k3s thinks that there's two nodes
  # because we change the hostName. See here:
  # >k get nodes
  # NAME         STATUS     ROLES           AGE     VERSION
  # nixos        NotReady   control-plane   5m8s    v1.35.5+k3s1
  # raspberry0   Ready      control-plane   3m23s   v1.35.5+k3s1
  #
  # Notice how we end up with a nixos node (the default hostname) _and_
  # a raspberry0 node (the name we change to)
  #
  # `k delete node nixos` fixes the issue, so :shrug:. Don't know if I care
  # to fix this. You may also have to reboot the node to get the hostname
  # to actually update first (otherwise you'll only see `nixos` an no `raspberry0`
  networking.hostName = "raspberry0";
  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
    # 2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
    # 2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
    80
    443
  ];
  networking.firewall.allowedUDPPorts = [
    8472 # k3s, flannel: required if using multi-node for inter-node networking
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
