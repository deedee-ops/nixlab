_: {
  flake.nixosModules.hardware-lxc-container =
    { lib, modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/virtualisation/lxc-container.nix")
      ];

      config = {
        # default "0 2147483647" can't be mapped in the container user namespace and is silently rejected,
        # leaving unprivileged ICMP (ping) disabled
        boot.kernel.sysctl."net.ipv4.ping_group_range" = lib.mkForce "0 65535";

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      };
    };
}
