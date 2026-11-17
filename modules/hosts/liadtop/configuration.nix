{ self, ... }:
{
  flake.nixosModules.hosts-liadtop-configuration =
    {
      config,
      lib,
      ...
    }:
    let
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

      # zenbook only does s2idle, so the panel stays lit unless niri powers it off first. sleep.target exists only
      # in the system manager, hence a system unit running as the user. Locking is left to noctalia
      # (lockscreen.lock_before_suspend, a logind delay inhibitor that completes before sleep.target starts).
      systemd.services.niri-pre-sleep = {
        description = "Turn off niri displays before sleep";
        before = [ "sleep.target" ];
        wantedBy = [ "sleep.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = primaryUser;
          TimeoutStartSec = 5;
        };
        script = ''
          for sock in /run/user/"$(id -u)"/niri.*.sock; do
            [ -S "$sock" ] || continue
            NIRI_SOCKET="$sock" ${lib.getExe config.programs.niri.package} msg action power-off-monitors || true
          done
        '';
      };

      home-manager.users."${primaryUser}" = {
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
