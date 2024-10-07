{ modulesPath, pkgs, ... }:
let
  serialDevice = if pkgs.stdenv.hostPlatform.isx86 then "ttyS0" else "ttyAMA0";
in
{
  imports = [
    "${modulesPath}/virtualisation/lxc-instance-common.nix"
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  boot = {
    growPartition = true;
    loader.systemd-boot.enable = true;
    kernelParams = [
      "console=tty1"
      "console=${serialDevice}"
    ];
  };

  # CPU hotplug
  services.udev.extraRules = ''
    SUBSYSTEM=="cpu", CONST{arch}=="x86-64", TEST=="online", ATTR{online}=="0", ATTR{online}="1"
  '';

  virtualisation.incus.agent.enable = true;
}
