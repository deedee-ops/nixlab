{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.mySystem.usb;
in
{
  options.mySystem.usb = {
    autoMountDisks = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            target = lib.mkOption {
              type = lib.types.str;
              description = "Mount destination dir.";
              example = "/mnt/mydisk";
            };
            autoUmount = lib.mkOption {
              type = lib.types.bool;
              description = "Autoumount disk after some idle time.";
              default = true;
            };
          };
        }
      );
      description = ''
        List of short serial IDs of disks to be automounted. The key is the ID, the value is destination.
        You can get serial ID via `udevadm info --query=all --name=/dev/<your_device> | grep ID_SERIAL_SHORT`
      '';
      default = { };
      example = {
        G0M024766 = {
          target = "/mnt/mydisk";
        };
      };
    };
  };
  config = {
    services.udev.extraRules = lib.concatStringsSep "\n" (
      builtins.map (
        diskid:
        ''ACTION=="add", SUBSYSTEMS=="usb", SUBSYSTEM=="block", ENV{ID_FS_USAGE}=="filesystem", ENV{ID_SERIAL_SHORT}=="${diskid}", ''
        + ''RUN{program}+="${lib.getExe' pkgs.systemd "systemd-mount"} ''
        + (lib.optionalString (
          !(builtins.getAttr diskid cfg.autoMountDisks).autoUmount
        ) "--timeout-idle-sec=0 ")
        + "--no-block --automount=yes --collect $devnode ${(builtins.getAttr diskid cfg.autoMountDisks).target}\""
      ) (builtins.attrNames cfg.autoMountDisks)
    );
  };
}
