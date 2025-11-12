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
        ssh = "nas.home.arpa:22";
        host = "nas.home.arpa";
      };
      deedee = {
        ip = "192.168.2.100";
        ssh = "deedee.home.arpa:22";
        host = "deedee.home.arpa";
      };
      meemee = {
        ip = "192.168.2.10";
        ssh = "meemee.home.arpa:22";
        host = "meemee.home.arpa";
      };
      kvm-deedee = {
        ip = "192.168.2.101";
        ssh = null;
        host = null;
      };
      dexter = {
        ip = "192.168.2.200";
        ssh = "dexter.home.arpa:22";
        host = "dexter.home.arpa";
      };
      work = {
        ip = "192.168.2.210";
        ssh = null;
        host = null;
      };
      windows = {
        ip = "192.168.2.211";
        ssh = null;
        host = "windows.home.arpa";
      };
      azeroth = {
        ip = "192.168.2.212";
        ssh = null;
        host = "azeroth.home.arpa";
      };
    };
  };

}
