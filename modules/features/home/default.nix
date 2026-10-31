{ self, ... }:
{
  flake.homeModules = {
    features-home =
      {
        osConfig ? null,
        pkgs,
        lib,
        ...
      }:
      {
        options.features.home.gpu = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.enum [
              "iHD"
              "nvidia"
              "radeon"
            ]
          );
          description = "VA-API driver family of the GPU, enables hardware video acceleration in apps that support it.";
          default = if osConfig == null then null else osConfig.features.nixos.system.gpu;
          defaultText = lib.literalExpression "osConfig.features.nixos.system.gpu";
        };

        config = {
          xdg.enable = true;
          programs.noctalia.settings.theme.templates.community_ids = [ "fastfetch" ];

          home = {
            preferXdgDirectories = true;

            packages = [
              pkgs.fastfetch
              pkgs.jq
              pkgs.openssl
              pkgs.p7zip
              pkgs.pwgen
              pkgs.ripgrep
              pkgs.unrar
              pkgs.unzip
              pkgs.wget
              pkgs.xterm
            ];

            shellAliases = {
              ".." = "cd ..";
              "..." = "cd ../..";
              "...." = "cd ../../..";
              "....." = "cd ../../../..";
              "......" = "cd ../../../../..";
              "......." = "cd ../../../../../..";
              "........" = "cd ../../../../../../..";

              grep = "grep --color";
              ls = "ls --color";

              ag = "rg"; # old habits die hard

              w = "ssh work";
            }
            // lib.optionalAttrs pkgs.stdenv.isLinux {
              # check sync process (usually when unmounting USBs)
              syncstatus = "watch -d grep -e Dirty: -e Writeback: /proc/meminfo";
            };
          };
        };
      };

    features-home-console = _: {
      imports = [
        self.homeModules.features-home-aichat
        self.homeModules.features-home-atuin
        self.homeModules.features-home-bat
        self.homeModules.features-home-btop
        self.homeModules.features-home-claude
        self.homeModules.features-home-direnv
        self.homeModules.features-home-git
        self.homeModules.features-home-gnupg
        self.homeModules.features-home-kubernetes
        self.homeModules.features-home-rclone
        self.homeModules.features-home-neovim
        self.homeModules.features-home-shell
        self.homeModules.features-home-ssh
        self.homeModules.features-home-wakatime
        self.homeModules.features-home-yazi
        self.homeModules.features-home-zsh
      ];
    };

    features-home-gui = { pkgs, ... }: {
      imports = [
        self.homeModules.features-home-discord
        self.homeModules.features-home-firefox
        self.homeModules.features-home-freerdp
        self.homeModules.features-home-kdeconnect
        self.homeModules.features-home-keepassxc
        self.homeModules.features-home-kitty
        self.homeModules.features-home-niri
        self.homeModules.features-home-noctalia-shell
        self.homeModules.features-home-obsidian
        self.homeModules.features-home-rustdesk
        self.homeModules.features-home-supersonic
        self.homeModules.features-home-syncthing
        self.homeModules.features-home-teams
        self.homeModules.features-home-telegram
        self.homeModules.features-home-thunderbird
        self.homeModules.features-home-vicinae
        self.homeModules.features-home-wayland
        self.homeModules.features-home-zathura
      ];

      config = {
        programs.noctalia.settings.theme.templates.community_ids = [
          "gimp"
          "libreoffice"
        ];

        home.packages = [
          pkgs.gimp
          pkgs.libreoffice
        ];
      };
    };
  };
}
