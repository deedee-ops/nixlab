{
  config,
  lib,
  svc,
  ...
}:
let
  cfg = config.mySystemApps.kms;
  # https://learn.microsoft.com/en-us/openspecs/office_standards/ms-oe376/6c085406-a698-4e12-9d4d-c3b0ee3dbc4a
  locale = {
    en-US = "1033";
    pl-PL = "1045";
  };
in
{
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.kms-server = svc.mkContainer {
      cfg = {
        image = "11notes/kms:stable@sha256:8a21b00a9f1a7622c3e2961cd3b4804eb6dac4c481d5adcf80bd7eb07c78bfab";
        user = "65000:65000";
        environment = {
          KMS_LOCALE = locale."${cfg.locale}";
          KMS_PORT = "1688";
        };
        ports = [ "1688:1688" ];
        volumes = [ "${cfg.dataDir}:/kms/var" ];

        extraOptions = [
          "--mount"
          "type=tmpfs,destination=/tmp,tmpfs-mode=1777"
        ];
      };
      opts = {
        # exposing port
        allowPublic = true;
      };
    };

    networking.firewall.allowedTCPPorts = [ 1688 ];
  };
}
