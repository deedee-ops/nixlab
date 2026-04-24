_: {
  flake.nixosModules.features-nixos-squid = _: {
    config = {
      services.squid = {
        enable = true;
        extraConfig = ''
          hosts_file /etc/hosts
          shutdown_lifetime 5 seconds
        '';
      };
    };
  };
}
