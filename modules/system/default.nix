_: {
  imports = [
    ./core.nix
    ./lib.nix

    ./alerts.nix
    ./auto-upgrade.nix
    ./backup.nix
    ./disks.nix
    ./home-manager.nix
    ./impermanence.nix
    ./locales.nix
    ./networking.nix
    ./nix.nix
    ./ssh.nix
    ./user.nix

    ./apps
    ./containers
  ];
}
