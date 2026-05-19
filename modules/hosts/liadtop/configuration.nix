{ self, inputs, ... }:
{
  flake.nixosModules.hosts-liadtop-configuration =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      trustedRootCertificates = [
        (builtins.readFile ../../../assets/ca-work.crt)
        (builtins.readFile ../../../assets/ca-ec384.crt)
        (builtins.readFile ../../../assets/ca-rsa4096.crt)
      ];

      noctaliaShellPkg = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
      primaryUser = "ajgon";
      homeModules = [
        self.homeModules.features-home
        self.homeModules.features-home-console
        self.homeModules.features-home-gui

        self.homeModules.theme
      ];
    in
    {
      imports = [
        self.nixosModules.hardware-zenbook-14

        self.nixosModules.features-nixos-core
        self.nixosModules.features-nixos-desktop
        self.nixosModules.features-nixos-grub
        self.nixosModules.features-nixos-tailscale

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
            swapSize = "24G";
            systemDiskDevs = [ "/dev/nvme0n1" ];
          };

          docker.username = primaryUser;

          grub.mode = "uefi";

          home-manager = {
            username = primaryUser;
            modules = homeModules;
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
            extraDirectories = [ "/mnt" ];
          };
        };
      };

      home-manager.users."${primaryUser}" = {
        systemd.user.services.niri-pre-sleep = {
          Unit = {
            Description = "Lock screen and turn off displays before sleep";
            Before = "sleep.target";
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.writeShellScript "niri-pre-sleep" ''
              ${lib.getExe noctaliaShellPkg} ipc call lockScreen lock
              ${lib.getExe config.programs.niri.package} msg action power-off-monitors
            ''}";
          };
          Install = {
            WantedBy = [ "sleep.target" ];
          };
        };

        features.home = {
          firefox = {
            inherit trustedRootCertificates;

            features = [
              "radeon"
              "doh"
            ];
          };

          freerdp.windowsHosts.w10vm = {
            host = "windows.internal";
            username = primaryUser;
          };

          gnupg.pinentryPackage = pkgs.pinentry-qt;

          niri = {
            displays = [ "eDP-1" ];
            features = [ "radeon" ];
            launcher = "vicinae";
            terminal = "kitty";
          };

          noctalia-shell = {
            extraSettings = {
              bar.widgets = builtins.fromJSON (builtins.readFile ./noctalia-bar-widgets.json);
              desktopWidgets.monitorWidgets = builtins.fromJSON (
                builtins.readFile ./noctalia-monitor-widgets.json
              );
            };
            plugins = {
              tailscale = {
                # query param is a hack, to refresh plugin on version change
                sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins?v1.5.0";
                settings = {
                  refreshInterval = 5000;
                  compactMode = false;
                  showIpAddress = true;
                  showPeerCount = true;
                  hideDisconnected = false;
                  hideMullvadExitNodes = true;
                  terminalCommand = "${lib.getExe pkgs.kitty}";
                  sshUsername = "${primaryUser}";
                  pingCount = 5;
                  defaultPeerAction = "copy-ip";
                  taildropEnabled = false;
                  taildropDownloadDir = "~/Downloads";
                  taildropReceiveMode = "operator";
                  loginServer = "https://headscale.rzegocki.dev";
                };
              };
            };
          };

          ssh.appendOptions = {
            settings = {
              # private
              "Host git.ajgon.casa" = {
                ForwardAgent = false;
                HostName = "git.ajgon.casa";
                IdentitiesOnly = true;
                Port = 22;
                User = "git";
              };
              mandark = {
                ForwardAgent = true;
                HostName = "relay.rzegocki.dev";
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
              "Host github.com" = {
                ForwardAgent = false;
                HostName = "github.com";
                IdentitiesOnly = true;
                Port = 22;
                User = "git";
              };
            };
          };

          thunderbird = {
            inherit trustedRootCertificates;
          };
        };
      };

      system.stateVersion = "25.11";
    };
}
