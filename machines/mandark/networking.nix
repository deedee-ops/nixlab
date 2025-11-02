{ lib, ... }:
{
  networking = {
    defaultGateway = "164.92.192.1";
    defaultGateway6 = {
      address = "";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          {
            address = "164.92.204.134";
            prefixLength = 20;
          }
          {
            address = "10.19.0.5";
            prefixLength = 16;
          }
        ];
        ipv6.addresses = [
          {
            address = "fe80::6c59:17ff:febb:ca48";
            prefixLength = 64;
          }
        ];
        ipv4.routes = [
          {
            address = "164.92.192.1";
            prefixLength = 32;
          }
        ];
      };
      eth1 = {
        ipv4.addresses = [
          {
            address = "10.135.0.4";
            prefixLength = 16;
          }
        ];
        ipv6.addresses = [
          {
            address = "fe80::3cfd:9cff:fecc:a1d3";
            prefixLength = 64;
          }
        ];
      };
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="6e:59:17:bb:ca:48", NAME="eth0"
    ATTR{address}=="3e:fd:9c:cc:a1:d3", NAME="eth1"
  '';
}
