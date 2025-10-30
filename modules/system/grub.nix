{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystem.grub;
  grubTheme = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "grub";
    rev = "v1.0.0";
    sha256 = "sha256-/bSolCta8GCZ4lP0u5NVqYQ9Y3ZooYCNdTwORNvR7M0=";
  };
in
{
  options.mySystem.grub = {
    enable = lib.mkEnableOption "grub bootloader";
    efiInstallAsRemovable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "If you have issues with grub not being detected by EFI, set this to true.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.loader = {
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = lib.mkForce (!cfg.efiInstallAsRemovable);
      grub = {
        inherit (cfg) efiInstallAsRemovable;
        enable = true;
        efiSupport = true;
        device = "nodev";
        useOSProber = true;
        theme = "${grubTheme}/src/catppuccin-mocha-grub-theme";
      };
    };
  };
}
