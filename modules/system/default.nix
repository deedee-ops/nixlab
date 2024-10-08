_: {
  imports = [
    ./core.nix

    ./disks.nix
    ./home-manager.nix
    ./impermanence.nix
    ./locales.nix
    ./networking.nix
    ./ssh.nix
    ./user.nix

    ./apps
    ./services
  ];
}
