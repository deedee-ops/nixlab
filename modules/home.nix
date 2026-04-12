{
  self,
  inputs,
  ...
}:
let
  primaryUser = "ajgon";
  homeModules = [
    self.homeModules.features-home-bat

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
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs { inherit system; };
          modules = [
            inputs.stylix.homeModules.stylix

            {
              home = {
                username = primaryUser;
                homeDirectory = "/home/${primaryUser}";
                stateVersion = "25.11";
              };
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
