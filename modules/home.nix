{
  self,
  inputs,
  ...
}:
let
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
    self.homeModules.features-home-ssh
    self.homeModules.features-home-zsh

    self.homeModules.themes-catppuccin
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

            {
              home = {
                username = primaryUser;
                homeDirectory = "/home/${primaryUser}";
                stateVersion = "25.11";
              };

              # TODO:
              sops.age.sshKeyPaths = [ "/run/secrets/credentials/ssh/private_key" ];
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
