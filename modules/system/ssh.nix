{ config, lib, ... }:
let
  cfg = config.mySystem.ssh;
in
{
  options.mySystem.ssh = {
    enable = lib.mkEnableOption "ssh";
    permitRootLogin = lib.mkOption {
      type = lib.types.enum [
        "yes"
        "without-password"
        "prohibit-password"
        "forced-commands-only"
        "no"
      ];
      default = "prohibit-password";
      description = "Whether the root user can login using ssh.";
    };
    authorizedKeys = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = { };
      description = "Per user list of authorized keys";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      startWhenNeeded = false;
      openFirewall = true;
      settings = {
        PermitRootLogin = cfg.permitRootLogin;
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;

        # Automatically remove stale sockets
        StreamLocalBindUnlink = "yes";
        # Allow forwarding ports to everywhere
        GatewayPorts = "clientspecified";
      };

      hostKeys = lib.optionals config.mySystem.impermanence.enable [
        {
          type = "ed25519";
          path = "${config.mySystem.impermanence.persistPath}/etc/ssh/ssh_host_ed25519_key";
        }
        {
          type = "rsa";
          bits = 4096;
          path = "${config.mySystem.impermanence.persistPath}/etc/ssh/ssh_host_rsa_key";
        }
      ];
    };

    sops.age.sshKeyPaths = lib.optionals config.mySystem.impermanence.enable [
      "${config.mySystem.impermanence.persistPath}/etc/ssh/ssh_host_ed25519_key"
    ];

    programs.ssh.startAgent = true;

    # pass ssh-agent socket when using sudo
    security.sudo = {
      execWheelOnly = true;
      extraConfig = lib.mkAfter ''
        Defaults:root,%wheel env_keep+=SSH_AUTH_SOCK
        Defaults lecture="never"
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
}
