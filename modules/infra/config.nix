_: {
  myInfra = rec {
    cidrs = {
      trusted = "10.100.0.0/16";
      untrusted = "10.200.0.0/16";
      iot = "10.210.0.0/16";
      wireguard = "10.250.1.0/24";
    };

    devices = {
      dualsense = {
        mac = "58:10:31:7b:be:7f";
      };
      headphones = {
        mac = "00:1b:66:c7:ba:81";
      };
      ps5 = {
        ip = "10.200.10.11";
      };
      slzb06m-bottom = {
        ip = "10.210.10.10";
      };
    };

    domains = {
      "*.rzegocki.dev" = machines.deedee.ip;
      "adguard-meemee.rzegocki.dev" = machines.meemee.ip;
      "deedee.rzegocki.dev" = machines.deedee.ip;
      "home.rzegocki.dev" = machines.meemee.ip;
      "home-code.rzegocki.dev" = machines.meemee.ip;
      "meemee.rzegocki.dev" = machines.meemee.ip;
      "minio.rzegocki.dev" = machines.meemee.ip;
      "registry.rzegocki.dev" = machines.meemee.ip;
      "s3.rzegocki.dev" = machines.meemee.ip;
      "wg.rzegocki.dev" = machines.meemee.ip;
      "zigbee2mqtt-bottomfloor.rzegocki.dev" = machines.meemee.ip;
      "zigbee2mqtt-topfloor.rzegocki.dev" = machines.meemee.ip;
    };

    machines = {
      gateway = {
        ip = "192.168.100.1";
        ssh = null;
        host = null;
      };
      omada = {
        ip = "10.100.1.1";
        ssh = null;
        host = null;
      };
      nas = {
        ip = "10.100.10.1";
        ssh = "10.100.10.1:51008";
        host = "nas.home.arpa";
      };
      deedee = {
        ip = "10.100.20.1";
        ssh = "10.100.20.1:22";
        host = "deedee.home.arpa";
      };
      meemee = {
        ip = "10.100.20.2";
        ssh = "10.100.20.2:22";
        host = "meemee.home.arpa";
      };
      monkey = {
        ip = "10.200.10.10";
        ssh = "10.200.10.10:22";
        host = "monkey.home.arpa";
      };
    };
  };

}
