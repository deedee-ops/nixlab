{ self, ... }:
{
  flake.nixosModules = {
    hosts-common =
      { config, lib, ... }:
      let
        user = config.features.nixos.user.name;
      in
      {
        imports = [
          self.nixosModules.features-nixos-core

          self.nixosModules.theme
        ];

        sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

        features.nixos = {
          docker.username = user;

          home-manager = {
            username = user;
            modules = [
              self.homeModules.features-home

              self.homeModules.theme
            ];
          };

          ssh.authorizedKeys.${user} = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrBLT88ZZ+lO8hHcj+4jqtor79OLhQZcDWF98kkWkfn personal"
          ];

          system.trustedRootCertificates = [
            (builtins.readFile ../../assets/ca-ec384.crt)
            (builtins.readFile ../../assets/ca-rsa4096.crt)
          ];

          user.name = lib.mkDefault "ajgon";
        };
      };

    hosts-common-desktop =
      { config, pkgs, ... }:
      let
        user = config.features.nixos.user.name;
        qrcpPort = 55555;
      in
      {
        imports = [
          self.nixosModules.features-nixos-audio
          self.nixosModules.features-nixos-desktop
        ];

        networking.firewall.allowedTCPPorts = [ qrcpPort ];

        features.nixos = {
          home-manager.modules = [
            self.homeModules.features-home-console
            self.homeModules.features-home-gui

            self.homeModules.features-home-dosbox
            self.homeModules.features-home-frpc
          ];

          system.trustedRootCertificates = [ (builtins.readFile ../../assets/ca-work.crt) ];

          user.extraDirectories = [ "/mnt" ];
        };

        home-manager.users.${user} = {
          features.home = {
            claude = {
              defaultContext = builtins.readFile ./claude-context-desktop.md;
              extraMounts = [
                "/home/${user}/Projects/home-ops:/home/ubuntu/home-ops"
                # sensitive information
                "/etc/NIXOS:/home/ubuntu/home-ops/opentofu/terraform.tfvars:ro"
              ];
              includeDesktop = true;
            };

            dosbox.savePath = "/home/${user}/Sync/retrosaves/dosbox-x";

            # .stignore isn't synced, every device needs its own copy
            syncthing.ignores.workspace = [
              "(?d).DS_Store"
              "*.tfvars"
              "*.tfvars.*"
            ];

            gnupg.pinentryPackage = pkgs.pinentry-qt;

            niri = {
              launcher = "vicinae";
              terminal = "kitty";
            };

            zsh.qrcp.port = qrcpPort;
          };

          programs.ssh.settings = {
            # private
            "git.ajgon.casa" = {
              ForwardAgent = false;
              HostName = "git.ajgon.casa";
              IdentitiesOnly = true;
              Port = 22;
              User = "git";
            };
            mandark = {
              ForwardAgent = true;
              HostName = "relay.ajgon.casa";
              IdentitiesOnly = true;
              Port = 22;
              User = "ajgon";
            };
            nas = {
              ForwardAgent = false;
              HostName = "nas.internal";
              IdentitiesOnly = true;
              Port = 22;
              User = "ajgon";
            };
            work = {
              ForwardAgent = false;
              HostName = "192.168.2.210";
              IdentitiesOnly = true;
              Port = 22;
              User = "ajgon";
              StrictHostKeyChecking = false;
              UserKnownHostsFile = "/dev/null";
            };

            # public
            "github.com" = {
              ForwardAgent = false;
              HostName = "github.com";
              IdentitiesOnly = true;
              Port = 22;
              User = "git";
            };
          };
        };
      };
  };
}
