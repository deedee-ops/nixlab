_: {
  imports = [
    ./core.nix

    ./adguardhome
    ./docker
    ./letsencrypt
    ./maddy
    ./nginx
    ./postgresql
    ./redis
    ./squid
  ];
}
