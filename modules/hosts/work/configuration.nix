{ self, inputs, ... }:
{
  flake.nixosModules.hosts-work-configuration =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      trustedRootCertificates = [
        (builtins.readFile ../../../assets/ca-ec384.crt)
        (builtins.readFile ../../../assets/ca-rsa4096.crt)
        (builtins.readFile ../../../assets/ca-work.crt)
      ];

      primaryUser = "ajgon";
      homeModules = [
        self.homeModules.features-home
        self.homeModules.features-home-console

        self.homeModules.features-home-syncthing
        self.homeModules.features-home-zellij

        self.homeModules.theme
      ];
    in
    {
      imports = [
        self.nixosModules.hardware-qemu-guest
        self.nixosModules.hardware-qemu-local

        self.nixosModules.features-nixos-core
        self.nixosModules.features-nixos-mounts
        self.nixosModules.features-nixos-networking
        self.nixosModules.features-nixos-openconnect
        self.nixosModules.features-nixos-squid

        self.nixosModules.theme
      ];

      sops = {
        defaultSopsFile = ./secrets.sops.yaml;
        age.sshKeyPaths = [ "/secrets/ssh_host_ed25519_key" ];

        secrets."features/home/zsh/extraConfig" = {
          inherit (config.users.users."${primaryUser}") group;
          owner = config.users.users."${primaryUser}".name;
          mode = "0400";
        };
      };
      boot.loader = {
        systemd-boot.enable = lib.mkForce false;
        grub.enable = false;
      };

      features = {
        nixos = {
          qemu-local = {
            portMappings = [
              {
                host = 2222;
                guest = 22;
              }
              {
                host = 3128;
                guest = 3128;
              }
              {
                host = 18384;
                guest = 18384;
              }
              {
                host = 44391;
                guest = 44391;
              }
            ];
            userMapping = {
              host = primaryUser;
              guest = primaryUser;
            };
          };

          disks = {
            enable = true;
            filesystem = "ext4";
            systemDiskDevs = [ "/dev/vda" ];
          };

          docker.username = primaryUser;

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

          openconnect = {
            keepaliveHost = "http://10.3.71.36";
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

            extraPackages = [
              pkgs.sshpass
              (inputs.nixpkgs-legacy.legacyPackages."${pkgs.stdenv.hostPlatform.system}".python311.withPackages
                (python-pkgs: [
                  python-pkgs.ansible
                  python-pkgs.ansible-core
                  python-pkgs.github3-py
                  python-pkgs.jmespath
                  python-pkgs.passlib
                  python-pkgs.pycryptodome
                  python-pkgs.pymysql
                  python-pkgs.pyvmomi
                ])
              )
            ];
          };

          user = {
            name = primaryUser;
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

          ssh = {
            sopsSecretsFile = ./secrets.sops.yaml;

            appendOptions = {
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
          };

          syncthing = {
            guiAddress = "0.0.0.0:18384";
            skipTray = true;
          };

          zsh = {
            promptColor = "blue";
            extraConfig = ''
              source ${config.sops.secrets."features/home/zsh/extraConfig".path}
            '';
          };
        };
      };

      system.stateVersion = "25.11";
    };
}
