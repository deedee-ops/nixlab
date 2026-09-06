_: {
  flake.nixosModules.features-nixos-kdeconnect = _: {
    config = {
      # actual package is installed per user via home-manager,
      # this only opens TCP/UDP 1714-1764 required for device discovery and pairing
      programs.kdeconnect = {
        enable = true;
        package = null;
      };
    };
  };
}
