_: {
  flake.nixosModules.features-nixos-tailscale =
    { pkgs, lib, ... }:
    {
      config = {
        environment.shellAliases = {
          tailscale-up = ''tailscale up --login-server=https://headscale.rzegocki.dev --authkey "$(${lib.getExe' pkgs.libsecret "secret-store"} lookup name "tailscale-$(hostname)")" --accept-routes --operator="$USER"'';
        };
        services = {
          tailscale = {
            enable = true;
            disableTaildrop = true;
          };
        };
      };
    };
}
