{ self, ... }:
{
  flake.nixosModules.hosts-mandark-configuration =
    { lib, ... }:
    let
      trustedRootCertificates = [
        (builtins.readFile ../../../assets/ca-ec384.crt)
        (builtins.readFile ../../../assets/ca-rsa4096.crt)
      ];

      primaryUser = "ajgon";
      homeModules = [
        self.homeModules.features-home

        self.homeModules.features-home-bat
        self.homeModules.features-home-btop
        self.homeModules.features-home-xdg
        self.homeModules.features-home-yazi
        self.homeModules.features-home-zsh

        self.homeModules.theme
      ];
    in
    {
      imports = [
        self.nixosModules.hardware-gandicloud

        self.nixosModules.features-nixos-home-manager
        self.nixosModules.features-nixos-locales
        self.nixosModules.features-nixos-ssh
        self.nixosModules.features-nixos-system
        self.nixosModules.features-nixos-time
        self.nixosModules.features-nixos-user

        self.nixosModules.features-nixos-headscale
        self.nixosModules.features-nixos-rustdesk
        self.nixosModules.features-nixos-tailscale

        self.nixosModules.theme
      ];

      sops = {
        defaultSopsFile = ./secrets.sops.yaml;
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      };

      networking = {
        hostName = "mandark";
        firewall.enable = true;
        nameservers = lib.mkForce [
          "9.9.9.9"
          "149.112.112.112"
        ];
        extraHosts = ''
          192.168.42.10 s3.ajgon.casa nix.ajgon.casa
          192.168.42.30 id.ajgon.casa
        '';
      };

      features = {
        nixos = {
          headscale = {
            nameservers = [
              "192.168.42.1"
            ];
            oidc = {
              enable = true;
              clientId = "8b45ae3e-0b3b-4b9c-a55b-90c89b1a25a4";
              issuer = "id.ajgon.casa";
            };
            serverHost = "headscale.rzegocki.dev";
            sopsSecretsFile = ./secrets.sops.yaml;
          };

          home-manager = {
            username = primaryUser;
            modules = homeModules;
          };

          rustdesk = {
            relayHost = "relay.rzegocki.dev";
            sopsSecretsFile = ./secrets.sops.yaml;
          };

          ssh = {
            authorizedKeys = {
              "${primaryUser}" = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrBLT88ZZ+lO8hHcj+4jqtor79OLhQZcDWF98kkWkfn personal"
              ];
            };
          };

          system = {
            inherit trustedRootCertificates;
          };

          user = {
            name = primaryUser;
          };
        };
      };

      home-manager.users."${primaryUser}" = {
        features.home = {
          zsh.promptColor = "yellow";
        };
      };

      system.stateVersion = "25.11";
    };
}
