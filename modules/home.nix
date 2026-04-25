{
  self,
  inputs,
  ...
}:
let
  trustedRootCertificates = [
    (builtins.readFile ../assets/ca-ec384.crt)
    (builtins.readFile ../assets/ca-rsa4096.crt)
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
    self.homeModules.features-home-neovim
    self.homeModules.features-home-kubernetes
    self.homeModules.features-home-ssh
    self.homeModules.features-home-wakatime
    self.homeModules.features-home-yazi
    self.homeModules.features-home-zsh

    self.homeModules.features-home-discord
    self.homeModules.features-home-firefox
    self.homeModules.features-home-keepassxc
    self.homeModules.features-home-kitty
    self.homeModules.features-home-noctalia-shell
    self.homeModules.features-home-obsidian
    self.homeModules.features-home-rustdesk
    self.homeModules.features-home-supersonic
    self.homeModules.features-home-syncthing
    self.homeModules.features-home-teams
    self.homeModules.features-home-telegram
    self.homeModules.features-home-thunderbird
    self.homeModules.features-home-vicinae
    self.homeModules.features-home-zathura

    self.homeModules.theme
  ];
in
rec {
  imports = [
    inputs.home-manager.flakeModules.home-manager
  ];

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  # to apply on non-nixos
  # home-manager switch --flake .#"ajgon@$(nix eval --impure --raw --expr builtins.currentSystem)"

  flake.homeConfigurations =
    let
      mkHome =
        system:
        let
          pkgs = import inputs.nixpkgs { inherit system; };
        in
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          lib = inputs.nixpkgs.lib.extend (
            _: _: inputs.home-manager.lib // (import ../lib/home.nix { inherit pkgs; })
          );
          modules = [
            inputs.krewfile.homeManagerModules.krewfile
            inputs.sops-nix.homeManagerModules.sops
            inputs.stylix.homeModules.stylix
            inputs.vicinae.homeManagerModules.default

            {
              home = {
                username = primaryUser;
                homeDirectory = "/home/${primaryUser}";
                stateVersion = "25.11";
              };

              nixpkgs.config.allowUnfree = true;

              features = {
                home = {
                  firefox = {
                    inherit trustedRootCertificates;

                    features = [
                      "doh"
                    ];
                  };

                  thunderbird = {
                    inherit trustedRootCertificates;
                  };
                };
              };

              sops.age.sshKeyPaths = [
                "/home/${primaryUser}/.config/sops-nix/secrets/features/home/ssh/privateKey"
              ];
            }
          ]
          ++ homeModules;
        };
    in
    builtins.listToAttrs (
      map (system: {
        name = "ajgon@${system}";
        value = mkHome system;
      }) systems
    );
}
