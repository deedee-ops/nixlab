_: {
  imports = [
    ./core.nix

    ./docker.nix
    ./letsencrypt.nix
    ./nginx.nix
    ./postgresql.nix
    ./redis.nix
    ./squid.nix
  ];
}
