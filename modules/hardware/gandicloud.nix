_: {
  flake.nixosModules.hardware-gandicloud =
    { modulesPath, lib, ... }:
    {
      imports = [ (modulesPath + "/virtualisation/openstack-config.nix") ];
      config = {
        boot = {
          initrd.kernelModules = [
            "xen-blkfront"
            "xen-tpmfront"
            "xen-kbdfront"
            "xen-fbfront"
            "xen-netfront"
            "xen-pcifront"
            "xen-scsifront"
          ];

          # Show debug kernel message on boot then reduce loglevel once booted
          consoleLogLevel = 7;
          kernel.sysctl."kernel.printk" = "4 4 1 7";

          # For "openstack console log show"
          kernelParams = [ "console=ttyS0" ];
        };

        systemd = {
          services."serial-getty@ttyS0" = {
            enable = true;
            wantedBy = [ "multi-user.target" ];
            serviceConfig.Restart = "always";
          };
          # This is to get a prompt via the "openstack console url show" command
          services."getty@tty1" = {
            enable = lib.mkForce true;
            wantedBy = [ "multi-user.target" ];
            serviceConfig.Restart = "always";
          };
        };

        # The device exposed by Xen
        boot.loader.grub.device = lib.mkForce "/dev/xvda";

        # This is headless server, DBUS user sessions shouldn't be fired
        security.pam.services.sshd.startSession = lib.mkForce false;

        # This is required to get an IPv6 address on our infrastructure
        networking.tempAddresses = "disabled";

        nixpkgs.hostPlatform = "x86_64-linux";
      };
    };
}
