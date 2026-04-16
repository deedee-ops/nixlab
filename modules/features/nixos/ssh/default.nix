_: {
  flake.nixosModules.features-nixos-ssh =
    { config, lib, ... }:
    let
      cfg = config.features.nixos.ssh;
    in
    {
      options.features.nixos.ssh = {
        authorizedKeys = lib.mkOption {
          type = lib.types.attrsOf (lib.types.listOf lib.types.str);
          default = { };
          example = {
            "user1" = [ "ssh-ed25519 abcdef laptop" ];
          };
          description = "Per user list of authorized keys";
        };
      };

      config = {
        services.openssh = {
          enable = true;
          startWhenNeeded = false;
          openFirewall = true;
          settings = {
            PermitRootLogin = "no";
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;

            # Automatically remove stale sockets
            StreamLocalBindUnlink = "yes";
            # Allow forwarding ports to everywhere
            GatewayPorts = "clientspecified";
          };
        };

        # programs.ssh.startAgent = true;

        # pass ssh-agent socket when using sudo
        security.sudo = {
          execWheelOnly = true;
          extraConfig = lib.mkAfter ''
            Defaults:root,%wheel env_keep+=SSH_AUTH_SOCK
          '';
        };

        users.users = builtins.mapAttrs (_: value: {
          openssh = {
            authorizedKeys = {
              keys = value;
            };
          };
        }) cfg.authorizedKeys;
      };
    };
}
