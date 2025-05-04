{
  config,
  lib,
  svc,
  pkgs,
  ...
}:
let
  cfg = config.mySystemApps.tftpd;
in
{
  options.mySystemApps.tftpd = {
    enable = lib.mkEnableOption "tftpd container";
    backup = lib.mkEnableOption "data backup" // {
      default = true;
    };
    ipxe = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "iPXE";
          additionalOptions = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Extra options to be enabled in iPXE build.";
            example = [
              "NSLOOKUP_CMD"
              "TIME_CMD"
            ];
            default = [ ];
          };
          signingKeysSopsSecret = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            description = "Sops secret containing signing keys for ipxe. If null, ipxe won't be signed.";
            default = null;
          };
        };
      };
      default = {
        enable = false;
      };
      description = "If enabled, it will build custom iPXE firmware and include in in root TFTP folder, as `ipxe.efi`.";
    };
    useHostNetwork = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Sometimes docker adds too much overhead, and network stack gets crazy. Using host networking may help.";
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing files.";
      default = "/var/lib/tftpd";
    };
  };

  config =
    let
      ipxe =
        if cfg.ipxe.enable then
          pkgs.ipxe.override {
            inherit (cfg.ipxe) additionalOptions;
            embedScript = pkgs.writeText "embed.ipxe" ''
              #!ipxe

              dhcp
              chain boot.ipxe
            '';
          }
        else
          null;
    in
    lib.mkIf cfg.enable {
      virtualisation.oci-containers.containers.tftpd = svc.mkContainer {
        cfg = {
          image = "registry.gitlab.com/kalaksi-containers/tftpd:1.6@sha256:41f614ba418aaba5efe1a6a3a166f66c4414f9dfcbc0b579f9dce91d667f5e0d";
          environment = {
            TFTPD_BIND_ADDRESS = "0.0.0.0:" + (lib.optionalString (!cfg.useHostNetwork) "10") + "69";
          };
          ports = lib.optionals (!cfg.useHostNetwork) [ "69:1069/udp" ];
          volumes = [
            "${cfg.dataDir}:/tftpboot"
          ];
          extraOptions = [
            "--cap-add=CAP_SETGID"
            "--cap-add=CAP_SETUID"
            "--cap-add=CAP_SYS_CHROOT"
          ] ++ lib.optionals cfg.useHostNetwork [ "--cap-add=CAP_NET_BIND_SERVICE" ];
        };
        opts = {
          inherit (cfg) useHostNetwork;
          # expose port
          allowPublic = true;
        };
      };

      services = {
        restic.backups = lib.mkIf cfg.backup (
          svc.mkRestic {
            name = "tftpd";
            paths = [ cfg.dataDir ];
          }
        );
      };

      systemd.services.docker-tftpd = lib.mkIf cfg.ipxe.enable {
        preStart = lib.mkAfter (
          (
            if cfg.ipxe.signingKeysSopsSecret != null then
              ''
                ${lib.getExe' pkgs.sbsigntool "sbsign"} --key ${
                  config.sops.secrets."${cfg.ipxe.signingKeysSopsSecret}/uki-signing-key.pem".path
                } --cert ${
                  config.sops.secrets."${cfg.ipxe.signingKeysSopsSecret}/uki-signing-cert.pem".path
                } "${ipxe}/ipxe.efi" --output "${cfg.dataDir}/ipxe.efi"
              ''
            else
              ''
                cp "${ipxe}/ipxe.efi" "${cfg.dataDir}/ipxe.efi"
              ''
          )
          + ''
            chown 65000:65000 "${cfg.dataDir}/ipxe.efi"
          ''
        );
      };

      networking.firewall.allowedUDPPorts = [ 69 ];

      environment.persistence."${config.mySystem.impermanence.persistPath}" =
        lib.mkIf config.mySystem.impermanence.enable
          {
            directories = [
              {
                user = config.users.users.abc.name;
                group = config.users.groups.abc.name;
                directory = cfg.dataDir;
                mode = "755";
              }
            ];
          };
    };
}
