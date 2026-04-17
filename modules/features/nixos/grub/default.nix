_: {
  flake.nixosModules.features-nixos-grub =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.features.nixos.grub;
    in
    {
      options.features.nixos.grub = {
        mode = lib.mkOption {
          type = lib.types.enum [
            "legacy"
            "uefi"
          ];
          default = "uefi";
          description = "Install GRUB in legacy BIOS mode, or modern UEFI one.";
        };
        efiInstallAsRemovable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "If you have issues with grub not being detected by EFI, set this to true.";
        };
      };

      config = {
        warnings = [
          (lib.mkIf (
            cfg.mode == "legacy" && cfg.efiInstallAsRemovable
          ) "features.nixos.grub.efiInstallAsRemovable is ignored in legacy mode")
        ];

        stylix.targets.grub.enable = false;

        boot.loader = {
          systemd-boot.enable = lib.mkForce false;
          grub = {
            enable = true;
            device = "nodev";
            useOSProber = true;
          }
          // lib.optionalAttrs (cfg.mode == "uefi") {
            inherit (cfg) efiInstallAsRemovable;
            efiSupport = true;
          };
        }
        // lib.optionalAttrs (cfg.mode == "uefi") {
          efi.canTouchEfiVariables = lib.mkForce (!cfg.efiInstallAsRemovable);
        };
      };
    };
}
