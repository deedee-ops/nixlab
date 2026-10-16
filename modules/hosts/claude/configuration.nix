{ self, ... }:
{
  flake.nixosModules.hosts-claude-configuration =
    _:
    let
      trustedRootCertificates = [
        (builtins.readFile ../../../assets/ca-ec384.crt)
        (builtins.readFile ../../../assets/ca-rsa4096.crt)
      ];

      primaryUser = "ajgon";
      # modules using secrets must read them from this host's sopsfile - the box is fully controlled by an agent,
      # so it must never receive the shared home-manager age key
      homeModules = [
        self.homeModules.features-home
        self.homeModules.features-home-bat
        self.homeModules.features-home-btop
        self.homeModules.features-home-direnv
        self.homeModules.features-home-kubernetes
        self.homeModules.features-home-shell
        self.homeModules.features-home-yazi
        self.homeModules.features-home-zellij
        self.homeModules.features-home-zsh

        self.homeModules.theme
      ];
    in
    {
      imports = [
        self.nixosModules.hardware-nuc-8i3beh

        self.nixosModules.features-nixos-core
        self.nixosModules.features-nixos-networking

        self.nixosModules.theme
      ];

      sops = {
        defaultSopsFile = ./secrets.sops.yaml;
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      };

      features = {
        nixos = {
          disks = {
            enable = true;
            filesystem = "ext4";
            swapSize = "8G";
            systemDiskDevs = [ "/dev/nvme0n1" ];
          };

          docker.username = primaryUser;

          home-manager = {
            username = primaryUser;
            modules = homeModules;
          };

          networking = {
            hostname = "claude";
            mainInterface.name = "eno1";
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

      hardware.bluetooth.enable = true;

      home-manager.users."${primaryUser}" = {
        features.home = {
          kubernetes.sopsSecretsFile = ./secrets.sops.yaml;
          nix.sopsSecretsFile = ./secrets.sops.yaml;

          zsh.promptColor = "red";
        };
      };

      system.stateVersion = "26.11";
    };
}
