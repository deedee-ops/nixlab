_: {
  flake.nixosModules.features-nixos-plymouth = _: {
    config = {
      stylix.targets.plymouth.enable = false;

      boot = {
        kernelParams = [
          "quiet"
          "loglevel=3"
          "systemd.show_status=auto"
          "rd.udev.log_level=3"
        ];
        consoleLogLevel = 0;
        initrd.verbose = false;
        loader.timeout = 2;

        plymouth.enable = true;
      };
    };
  };
}
