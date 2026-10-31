{ self, inputs, ... }:
{
  flake.nixosModules.hosts-liadtop-configuration =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      noctaliaPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
      primaryUser = config.features.nixos.user.name;
    in
    {
      imports = [
        self.nixosModules.hardware-zenbook-14

        self.nixosModules.hosts-common-desktop

        self.nixosModules.features-nixos-grub
        self.nixosModules.features-nixos-tailscale
      ];

      features = {
        nixos = {
          disks = {
            enable = true;
            filesystem = "ext4";
            swapSize = "24G";
            systemDiskDevs = [ "/dev/nvme0n1" ];
          };

          grub.mode = "uefi";

          tailscale.acceptRoutes = true;
        };
      };

      home-manager.users."${primaryUser}" = {
        systemd.user.services.niri-pre-sleep = {
          Unit = {
            Description = "Lock screen and turn off displays before sleep";
            Before = "sleep.target";
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.writeShellScript "niri-pre-sleep" ''
              ${lib.getExe noctaliaPkg} msg session lock
              ${lib.getExe config.programs.niri.package} msg action power-off-monitors
            ''}";
          };
          Install = {
            WantedBy = [ "sleep.target" ];
          };
        };

        features.home = {
          freerdp.windowsHosts.w10vm = {
            host = "windows.internal";
            username = primaryUser;
          };

          niri.displays = [ "eDP-1" ];

          noctalia-shell = {
            extraSettings = builtins.fromTOML (builtins.readFile ./noctalia.toml);
            extraPlugins = [ "davemhammer/tailscale" ];
          };
        };
      };

      system.stateVersion = "25.11";
    };
}
