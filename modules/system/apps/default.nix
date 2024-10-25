_: {
  imports = [
    ./core.nix

    ./adguardhome
    ./docker
    ./letsencrypt
    ./nginx
    ./postgresql
    ./redis
    ./squid
  ];
}
