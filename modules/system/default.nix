_: {
  imports = [
    ./core.nix
    ./lib.nix

    ./alerts.nix
    ./auto-upgrade.nix
    ./backup.nix
    ./btrfs.nix
    ./disks.nix
    ./grub.nix
    ./healthcheck.nix
    ./home-manager.nix
    ./impermanence.nix
    ./locales.nix
    ./motd.nix
    ./mounts.nix
    ./networking.nix
    ./nix.nix
    ./ssh.nix
    ./time.nix
    ./user.nix
    ./zfs.nix

    ./apps
    ./containers
    ./hardware
  ];
}
