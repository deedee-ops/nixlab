_: {
  myInfra = rec {
    cidrs = {
      trusted = "192.168.2.0/24";
    };

    devices = {
      dualsense = {
        mac = "58:10:31:7b:be:7f";
      };
      headphones = {
        mac = "00:1b:66:c7:ba:81";
      };
      ps5 = {
        ip = "192.168.4.10";
      };
    };

    machines = {
      gateway = {
        # internet gateway
        ip = "192.168.100.1";
        ssh = null;
        host = null;
      };
      unifi = {
        ip = "192.168.1.1";
        ssh = null;
        host = null;
      };
      nas = {
        ip = "192.168.2.10";
        ssh = "nas.internal:22";
        host = "nas.internal";
      };
      mandark = {
        ip = "164.92.204.134";
        ssh = "relay.rzegocki.dev:22";
        host = "relay.rzegocki.dev";
      };
      kvm = {
        ip = "192.168.2.101";
        ssh = null;
        host = "kvm.internal";
      };
      dexter = {
        ip = "192.168.2.200";
        ssh = "dexter.internal:22";
        host = "dexter.internal";
      };
      work = {
        ip = "192.168.2.210";
        ssh = null;
        host = null;
      };
      windows = {
        ip = "192.168.2.211";
        ssh = null;
        host = "windows.internal";
      };
    };
  };

}
