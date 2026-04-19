_: {
  flake.nixosModules.features-nixos-docker =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.features.nixos.docker;
    in
    {
      options.features.nixos.docker = {
        username = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          description = "User to be added to docker group";
          default = null;
        };
      };
      config = {
        virtualisation = {
          oci-containers.backend = "docker";
          docker = {
            enable = true;
            package = pkgs.docker;
            autoPrune = {
              enable = true;
              dates = "daily";
            };
            storageDriver = lib.mkIf (
              config.features.nixos.disks.filesystem == "zfs" || config.features.nixos.disks.filesystem == "btrfs"
            ) config.features.nixos.disks.filesystem;
          };
        };

        networking.firewall = {
          trustedInterfaces = [ "docker0" ];
          interfaces."docker0".allowedUDPPorts = [ 53 ];
        };
        users.users = lib.mkIf (cfg.username != null) { "${cfg.username}".extraGroups = [ "docker" ]; };
      };
    };
}
