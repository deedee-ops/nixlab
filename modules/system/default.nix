_: {
  imports = [
    ./core.nix
    ./lib.nix

    ./backup.nix
    ./disks.nix
    ./home-manager.nix
    ./impermanence.nix
    ./locales.nix
    ./networking.nix
    ./ssh.nix
    ./user.nix

    ./apps
    ./containers
  ];
}
