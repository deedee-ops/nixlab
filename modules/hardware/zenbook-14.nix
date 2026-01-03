{
  lib,
  pkgs,
  pkgs-master,
  config,
  ...
}:
let
  soundDriverIncludedInKernel =
    lib.strings.toInt (lib.versions.major config.boot.kernelPackages.kernel.version) >= 6
    && lib.strings.toInt (lib.versions.minor config.boot.kernelPackages.kernel.version) >= 8;
in
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
    kernelModules = [
      "amdgpu"
      "kvm-amd"
    ];
    kernelParams = lib.optionals config.mySystem.vmPassthrough [
      "amd_iommu=on"
      "iommu=pt"
    ];
    extraModulePackages = [ ];
    # https://discourse.nixos.org/t/asus-zenbook-no-sound-output/29326
    # https://github.com/farfaaa/asus_zenbook_UM3402YA
    loader.grub.extraConfig = lib.mkIf (!soundDriverIncludedInKernel) ''
      acpi /ssdt_csc3551.aml
    '';
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware = {
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
    # https://github.com/NixOS/nixpkgs/issues/475392
    # usb-modeswitch.enable = true;
  };

  services.udev.packages = [ pkgs-master.usb-modeswitch-data ];
  systemd.packages = [ pkgs-master.usb-modeswitch ];
  environment.etc."usb_modeswitch.d".source =
    "${pkgs-master.usb-modeswitch-data}/share/usb_modeswitch";

  # power
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
  };

  # sound
  environment.systemPackages = [
    pkgs.acpi
  ];

  system.activationScripts = lib.mkIf (!soundDriverIncludedInKernel) {
    add-sound-profile = {
      text = ''
        cp ${./zenbook-14/ssdt_csc3551.aml} /boot/ssdt_csc3551.aml
      '';
    };
  };
}
