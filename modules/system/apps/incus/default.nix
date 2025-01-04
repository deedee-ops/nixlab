{
  config,
  lib,
  pkgs,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.incus;
in
{
  options.mySystemApps.incus = {
    enable = lib.mkEnableOption "incus app";
    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Path to directory containing data.";
      default = "/var/lib/incus";
    };
    defaultStoragePool = lib.mkOption {
      type = lib.types.attrs;
      description = "Default storage pool configuration for incus.";
      default = {
        config = {
          source = "${cfg.dataDir}/disks/default.img";
          size = "500GiB";
        };
        driver = "btrfs";
        name = "default";
      };
    };
    defaultNIC = lib.mkOption {
      type = lib.types.attrs;
      description = "Default NIC for the VM.";
      default = {
        network = "incusbr0";
        type = "nic";
      };
      example = {
        nictype = "bridged";
        parent = "br0";
        type = "nic";
        vlan = 100;
      };
    };
    enableUI = lib.mkOption {
      type = lib.types.bool;
      description = "Enable incus UI";
      default = false;
    };
    incusUICrtSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = ''
        Sops secret name containing Incus UI certificate.
        Don't use incus UI to generate it, as it generates faulty certificates, not accepted by nginx.
        Instead do:
        openssl req -newkey rsa:4096 -nodes -keyout incus-ui.key -x509 -days 36500 -out incus-ui.crt
      '';
      default = "system/apps/incus/incus-ui.crt";
    };
    incusUIKeySopsSecret = lib.mkOption {
      type = lib.types.str;
      description = ''
        Sops secret name containing Incus UI certificate.
        Don't use incus UI to generate it, as it generates faulty certificates, not accepted by nginx.
        Instead do:
        openssl req -newkey rsa:4096 -nodes -keyout incus-ui.key -x509 -days 36500 -out incus-ui.crt
      '';
      default = "system/apps/incus/incus-ui.key";
    };
    initializeBaseNixOSVM = lib.mkOption {
      type = lib.types.bool;
      description = "If set to true, it will install base image, compatible with nixos-anywhere.";
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = (!cfg.enableUI) || config.mySystemApps.authelia.enable;
        message = "To use incus UI, authelia container needs to be enabled.";
      }
    ];

    sops.secrets = {
      "${cfg.incusUICrtSopsSecret}" = {
        owner = "nginx";
        group = "nginx";
        restartUnits = [ "nginx.service" ];
      };
      "${cfg.incusUIKeySopsSecret}" = {
        owner = "nginx";
        group = "nginx";
        restartUnits = [ "nginx.service" ];
      };
    };

    virtualisation.incus = {
      enable = true;
      ui.enable = cfg.enableUI;

      preseed = {
        profiles = [
          {
            name = "default";
            description = "Default profile";
            devices = {
              eth0 = lib.recursiveUpdate cfg.defaultNIC { name = "eth0"; };
              root = {
                path = "/";
                pool = "default";
                size = "200GiB";
                type = "disk";
              };
            };
            config = {
              "boot.autostart" = false;
              "limits.cpu" = 4;
              "limits.memory" = "8GiB";
              "security.secureboot" = false;
              "snapshots.schedule" = "@hourly";
            };
          }
        ];
        storage_pools = [ (lib.recursiveUpdate cfg.defaultStoragePool { name = "default"; }) ];
      };
    };

    users.users."${config.mySystem.primaryUser}".extraGroups = [ "incus-admin" ];
    networking.firewall.trustedInterfaces =
      lib.optionals (builtins.hasAttr "network" cfg.defaultNIC) [ cfg.defaultNIC.network ]
      ++ lib.optionals (builtins.hasAttr "parent" cfg.defaultNIC) [ cfg.defaultNIC.parent ];

    environment.persistence."${config.mySystem.impermanence.persistPath}" =
      lib.mkIf config.mySystem.impermanence.enable
        { directories = [ cfg.dataDir ]; };

    systemd.services.incus = {
      postStart = lib.mkAfter (
        (lib.optionalString cfg.enableUI ''
          ${lib.getExe config.virtualisation.incus.package} config set core.https_address 127.0.0.1:8443
          ${lib.getExe config.virtualisation.incus.package} config trust add-certificate ${
            config.sops.secrets."${cfg.incusUICrtSopsSecret}".path
          } || true
        '')
        + (lib.optionalString cfg.initializeBaseNixOSVM ''
          export PATH="${
            lib.makeBinPath [
              pkgs.incus
              pkgs.nix
            ]
          }:$PATH"
          if ! incus image show nixos/base/vm; then
            nix run github:deedee-ops/nixlab#build-base-vm
          fi
        '')
      );
    };

    services.nginx.virtualHosts.incus = lib.mkIf cfg.enableUI (
      svc.mkNginxVHost {
        host = "incus";
        proxyPass = "https://127.0.0.1:8443";
        extraConfig = ''
          proxy_ssl_certificate     ${config.sops.secrets."${cfg.incusUICrtSopsSecret}".path};
          proxy_ssl_certificate_key ${config.sops.secrets."${cfg.incusUIKeySopsSecret}".path};
        '';
      }
    );

    mySystemApps.homepage = lib.mkIf cfg.enableUI {
      services.Apps.Incus = svc.mkHomepage "incus" // {
        icon = "https://cdn.jsdelivr.net/gh/ajgon/dashboard-icons@add-incus/svg/incus.svg";
        container = null;
        description = "Virtual machines manager";
      };
    };
  };
}
