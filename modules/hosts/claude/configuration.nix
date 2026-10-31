{ self, ... }:
{
  flake.nixosModules.hosts-claude-configuration =
    { config, ... }:
    {
      imports = [
        self.nixosModules.hardware-nuc-8i3beh

        self.nixosModules.features-nixos-networking
      ];

      features = {
        nixos = {
          disks = {
            enable = true;
            filesystem = "ext4";
            legacyThinPool = true; # TODO: drop on reinstall
            swapSize = "8G";
            systemDiskDevs = [ "/dev/nvme0n1" ];
          };

          # modules using secrets must read them from this host's sopsfile - the box is fully controlled by an agent,
          # so it must never receive the shared home-manager age key
          home-manager.modules = [
            self.homeModules.features-home-bat
            self.homeModules.features-home-btop
            self.homeModules.features-home-direnv
            self.homeModules.features-home-git
            self.homeModules.features-home-kubernetes
            self.homeModules.features-home-shell
            self.homeModules.features-home-ssh
            self.homeModules.features-home-yazi
            self.homeModules.features-home-zellij
            self.homeModules.features-home-zsh
          ];

          networking = {
            hostname = "claude";
            mainInterface.name = "eno1";
          };
        };
      };

      hardware.bluetooth.enable = true;

      home-manager.users.${config.features.nixos.user.name} = {
        features.home = {
          git.sopsSecretsFile = ./secrets.sops.yaml;
          kubernetes.sopsSecretsFile = ./secrets.sops.yaml;
          nix.sopsSecretsFile = ./secrets.sops.yaml;
          # own key (not the personal one), granted per-repo access on forgejo
          ssh.sopsSecretsFile = ./secrets.sops.yaml;

          zsh.promptColor = "red";
        };
      };

      system.stateVersion = "26.11";
    };
}
