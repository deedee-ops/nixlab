{
  inputs,
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  configTxt = pkgs.writeText "config.txt" ''
    [pi4]
    kernel=u-boot-rpi4.bin
    enable_gic=1

    # Otherwise the resolution will be weird in most cases, compared to
    # what the pi3 firmware does by default.
    disable_overscan=1

    # Supported in newer board revisions
    arm_boost=1

    [cm4]
    # Enable host mode on the 2711 built-in XHCI USB controller.
    # This line should be removed if the legacy DWC2 controller is required
    # (e.g. for USB device mode) or if USB support is not required.
    otg_mode=1

    [all]
    # Boot in 64-bit mode.
    arm_64bit=1

    # U-Boot needs this to work, regardless of whether UART is actually used or not.
    # Look in arch/arm/mach-bcm283x/Kconfig in the U-Boot tree to see if this is still
    # a requirement in the future.
    enable_uart=1

    # Prevent the firmware from smashing the framebuffer setup done by the mainline kernel
    # when attempting to show low-voltage or overtemperature warnings.
    avoid_warnings=1
  '';
in
{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ];

  sdImage.compressImage = false;

  boot = {
    supportedFilesystems.zfs = lib.mkForce false;

    postBootCommands = ''
      set -euo pipefail
      set -x
      # @todo detect if partition needs resize and resize partition
    '';
  };

  mySystem = {
    filesystem = "ext4";
    disks = {
      systemDiskDevs = [ "/dev/mmcblk0" ];
      bootPartition = {
        name = "firmware";
        size = "30M";
        priority = 1;
        type = "0700";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/firmware";
          postMountHook = toString (
            pkgs.writeScript "postMountHook.sh" ''
              (cd ${pkgs.raspberrypifw}/share/raspberrypi/boot && cp bootcode.bin fixup*.dat start*.elf *.dtb /mnt/firmware/)
              cp ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin /mnt/firmware/u-boot-rpi4.bin
              cp ${configTxt} /mnt/firmware/config.txt
            ''
          );
        };
      };
    };
  };

  disko = {
    memSize = 8192;
    imageBuilder = {
      enableBinfmt = true;
      # pkgs = pkgs.pkgsCross.aarch64-multiplatform;
      kernelPackages = pkgs.linuxPackages_latest;
      qemu =
        (import pkgs.path { system = "x86_64-linux"; }).qemu
        + "/bin/qemu-system-aarch64 -M virt -cpu cortex-a57";
    };

    # for raspberry on sd-card the boot partition as actually a firmware partition
    devices.disk.system = {
      imageName = "nixos-aarch64-linux";
      imageSize = config.mySystem.disks.thinLvsSize;
      postCreateHook = ''
        lsblk
        sgdisk -A 1:set:2 /dev/vda
        sleep 5
      '';
    };
  };

  environment.systemPackages = [
    pkgs.libraspberrypi
    pkgs.raspberrypi-eeprom
  ];

  nixpkgs = {
    hostPlatform = "aarch64-linux";
    overlays = [
      # Workaround: https://github.com/NixOS/nixpkgs/issues/154163
      # modprobe: FATAL: Module sun4i-drm not found in directory
      (_: super: {
        makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
      })
    ];
  };

  fileSystems = lib.optionalAttrs config.mySystem.impermanence.enable {
    "/" = {
      device = lib.mkForce "none";
      fsType = lib.mkForce "tmpfs";
    };
  };

  hardware.enableRedistributableFirmware = true;
}
