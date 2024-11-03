_: {
  imports = [
    ./core.nix

    ./adguardhome
    ./docker
    ./letsencrypt
    ./nginx
    ./openconnect
    ./postgresql
    ./redis
    ./rustdesk
    ./squid
  ];
}
