{
  lib,
  pkgs,
  config,
  ...
}:
{
  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
    # https://discourse.nixos.org/t/asus-zenbook-no-sound-output/29326
    # https://github.com/farfaaa/asus_zenbook_UM3402YA
    # zfs enforces old (< 6.8) kernel
    loader.grub.extraConfig = lib.mkIf (config.mySystem.filesystem == "zfs") ''
      acpi /ssdt_csc3551.aml
    '';
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware = {
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
    usb-modeswitch.enable = true;
  };

  # power
  services.logind = {
    lidSwitch = "suspend";
    powerKey = "suspend";
    powerKeyLongPress = "poweroff";
  };

  # sound
  environment.systemPackages = [
    pkgs.acpi
  ];

  system.activationScripts = lib.mkIf (config.mySystem.filesystem == "zfs") {
    add-sound-profile = {
      text = ''
        cp ${./zenbook-14/ssdt_csc3551.aml} /boot/ssdt_csc3551.aml
      '';
    };
  };
}
