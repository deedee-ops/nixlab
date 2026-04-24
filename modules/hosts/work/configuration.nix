{ self, inputs, ... }:
{
  flake.nixosModules.hosts-work-configuration =
    { pkgs, ... }:
    let
      trustedRootCertificates = [
        (builtins.readFile ../../../assets/ca-ec384.crt)
        (builtins.readFile ../../../assets/ca-rsa4096.crt)
      ];

      primaryUser = "ajgon";
      homeModules = [
        self.homeModules.features-home
        self.homeModules.features-home-atuin
        self.homeModules.features-home-bat
        self.homeModules.features-home-btop
        self.homeModules.features-home-direnv
        self.homeModules.features-home-git
        self.homeModules.features-home-gnupg
        self.homeModules.features-home-kubernetes
        self.homeModules.features-home-neovim
        self.homeModules.features-home-ssh
        self.homeModules.features-home-wakatime
        self.homeModules.features-home-yazi
        self.homeModules.features-home-zellij
        self.homeModules.features-home-zsh

        self.homeModules.theme
      ];
    in
    {
      imports = [
        self.nixosModules.hardware-qemu-guest
        self.nixosModules.hardware-qemu-local

        self.nixosModules.features-nixos-disks
        self.nixosModules.features-nixos-docker
        self.nixosModules.features-nixos-grub
        self.nixosModules.features-nixos-home-manager
        self.nixosModules.features-nixos-locales
        self.nixosModules.features-nixos-mounts
        self.nixosModules.features-nixos-networking
        self.nixosModules.features-nixos-squid
        self.nixosModules.features-nixos-ssh
        self.nixosModules.features-nixos-system
        self.nixosModules.features-nixos-time
        self.nixosModules.features-nixos-user

        self.nixosModules.theme
      ];

      sops = {
        defaultSopsFile = ./secrets.sops.yaml;
        age.sshKeyPaths = [ "/secrets/ssh_host_ed25519_key" ];
      };

      features = {
        nixos = {
          qemu-local.portMappings = [
            {
              host = 2222;
              guest = 22;
            }
            {
              host = 3128;
              guest = 3128;
            }
          ];

          disks = {
            enable = true;
            filesystem = "ext4";
            systemDiskDevs = [ "/dev/vda" ];
          };

          docker.username = primaryUser;

          grub.mode = "uefi";

          home-manager = {
            username = primaryUser;
            modules = homeModules;
          };

          mounts.mounts = [
            {
              type = "nfs";
              src = "nas.internal:/mnt/cache/backups/work";
              dest = "/mnt/backup";
            }
          ];

          networking = {
            firewallEnable = false;
            hostname = "work";
            mainInterface.name = "eth0";
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

            extraPackages = [
              pkgs.sshpass
              (inputs.nixpkgs-legacy.python311.withPackages (python-pkgs: [
                python-pkgs.ansible
                python-pkgs.ansible-core
                python-pkgs.github3-py
                python-pkgs.jmespath
                python-pkgs.passlib
                python-pkgs.pycryptodome
                python-pkgs.pymysql
                python-pkgs.pyvmomi
              ]))
            ];
          };

          user = {
            name = primaryUser;
            extraDirectories = [ "/mnt" ];
          };
        };
      };

      home-manager.users."${primaryUser}" = {
        features.home = {
          git = {
            sopsSecretsFile = ./secrets.sops.yaml;
          };

          gnupg = {
            sopsSecretsFile = ./secrets.sops.yaml;
            publicKeys = [ ./work.gpg ];
          };

          kubernetes = {
            sopsSecretsFile = ./secrets.sops.yaml;
          };

          ssh.appendOptions = {
            matchBlocks."*" = {
              forwardAgent = false;
            };
            extraConfig = ''
              IdentitiesOnly yes
              Port 22
              StrictHostKeyChecking accept-new
              SetEnv TERM=xterm-256color
              HostkeyAlgorithms +ssh-rsa
              PubkeyAcceptedAlgorithms +ssh-rsa
            '';
          };

          zsh.promptColor = "blue";
        };
      };

      system.stateVersion = "25.11";
    };
}
