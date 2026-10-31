{ self, inputs, ... }:
{
  flake.nixosModules.hosts-work-configuration =
    {
      config,
      pkgs,
      ...
    }:
    let
      primaryUser = config.features.nixos.user.name;
    in
    {
      imports = [
        self.nixosModules.hardware-lxc-container

        self.nixosModules.features-nixos-networking
        self.nixosModules.features-nixos-openconnect
        self.nixosModules.features-nixos-squid
        self.nixosModules.features-nixos-tailscale
      ];

      sops.secrets."features/home/zsh/extraConfig" = {
        inherit (config.users.users."${primaryUser}") group;
        owner = config.users.users."${primaryUser}".name;
        mode = "0400";
      };

      features = {
        nixos = {
          home-manager.modules = [
            self.homeModules.features-home-console

            self.homeModules.features-home-zellij
          ];

          networking = {
            firewall.enable = false;
            hostname = "work";
            mainInterface.name = "eth0";
          };

          openconnect = {
            keepaliveHost = "http://10.3.71.36";
            sopsSecretsFile = ./secrets.sops.yaml;
          };

          system = {
            trustedRootCertificates = [ (builtins.readFile ../../../assets/ca-work.crt) ];

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

          # joined by hand (`tailscale up`, then disable key expiry in the console);
          # don't let tailnet DNS interfere with the corporate VPN. No accepted routes:
          # this box sits in 192.168.2.0/24 itself, the NAS routes would hijack its own LAN.
          tailscale.acceptDNS = false;
        };
      };

      # pinned, so the shifted ownership of the bind-mounted Projects dataset on TrueNAS (2147001001:2147000101) stays valid
      users.users."${primaryUser}".uid = 1000;

      # the Projects mount point is created before the user exists, which may leave home owned by root
      systemd.tmpfiles.rules = [
        "z /home/${primaryUser} 0700 ${primaryUser} users -"
      ];

      home-manager.users."${primaryUser}" = {
        features.home = {
          claude = {
            defaultContext = builtins.readFile ./claude-context.md;
            extraArgs = "--dns=10.82.8.42";
            extraMounts = [ "/home/${primaryUser}/Projects/k8s-gitops:/home/ubuntu/k8s-gitops" ];
            sopsSecretsFile = ./secrets.sops.yaml;
          };

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

          ssh.sopsSecretsFile = ./secrets.sops.yaml;

          zsh = {
            promptColor = "blue";
            extraConfig = ''
              source ${config.sops.secrets."features/home/zsh/extraConfig".path}
            '';
          };
        };

        programs.ssh.settings."Host *" = {
          ForwardAgent = false;
          IdentitiesOnly = true;
          Port = 22;
          StrictHostKeyChecking = "accept-new";
          SetEnv = {
            TERM = "xterm-256color";
          };
          HostkeyAlgorithms = "+ssh-rsa";
          PubkeyAcceptedAlgorithms = "+ssh-rsa";
        };
      };

      system.stateVersion = "25.11";
    };
}
