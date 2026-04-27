{ self, ... }:
{
  flake.nixosModules = {
    features-nixos-system =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        cfg = config.features.nixos.system;
      in
      {
        options = {
          features.nixos.system = {
            extraPackages = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              description = "Extra packages to be installed globally on the system.";
              default = [ ];
            };
            trustedRootCertificates = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "A list of trusted root certificates in PEM format.";
              default = [ ];
            };
          };
        };

        config = {
          environment = {
            enableAllTerminfo = true;
            systemPackages = cfg.extraPackages;
          };

          fonts.packages = [
            pkgs.corefonts
            pkgs.vista-fonts
          ];

          nix = {
            channel.enable = false; # don't use old nix channels

            gc = {
              automatic = true;
              dates = "daily";
              options = "--delete-older-than 30d";
            };

            settings = {
              experimental-features = [
                "nix-command"
                "flakes"
              ];

              use-xdg-base-directories = true;
            };
          };

          nixpkgs.config.allowUnfree = true;

          programs.nix-index-database.comma.enable = true;

          security = {
            # more file descriptors
            pam.loginLimits = [
              {
                domain = "*";
                item = "nofile";
                type = "-";
                value = "4096";
              }
            ];
            pki.certificates = cfg.trustedRootCertificates;
            sudo = {
              execWheelOnly = true;
              extraConfig = lib.mkAfter ''
                Defaults lecture="never"
              '';
            };
          };

          system = {
            activationScripts = {
              # qemu-local VMs hosted on machines need that
              readable-ssh-host-keys-for-wheel.text = ''
                ${lib.getExe' pkgs.coreutils "chgrp"} wheel /etc/ssh/ssh_host_ed25519_key
                ${lib.getExe' pkgs.coreutils "chmod"} 640 /etc/ssh/ssh_host_ed25519_key
              '';

              symlink-bin-bash.text = ''
                ln -s /run/current-system/sw/bin/bash /bin/bash || true
              '';
            };

            autoUpgrade = {
              enable = true;
              flake = "github:deedee-ops/nixlab";
              runGarbageCollection = true;
            };
          };
        };
      };
    features-nixos-core = {
      imports = [
        self.nixosModules.features-nixos-disks
        self.nixosModules.features-nixos-docker
        self.nixosModules.features-nixos-grub
        self.nixosModules.features-nixos-home-manager
        self.nixosModules.features-nixos-locales
        self.nixosModules.features-nixos-ssh
        self.nixosModules.features-nixos-system
        self.nixosModules.features-nixos-time
        self.nixosModules.features-nixos-user
      ];
    };
    features-nixos-desktop = {
      imports = [
        self.nixosModules.features-nixos-plymouth
        self.nixosModules.features-nixos-sddm
        self.nixosModules.features-nixos-wayland
      ];
    };
  };
}
