{
  self,
  inputs,
  config,
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
    self.homeModules.features-home-console
    self.homeModules.features-home-gui

    self.homeModules.theme
  ];
in
{
  imports = [
    inputs.home-manager.flakeModules.home-manager
  ];

  # to apply on non-nixos
  # home-manager switch --flake .#"ajgon@$(nix eval --impure --raw --expr builtins.currentSystem)"

  flake.homeConfigurations =
    let
      mkHome =
        system:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          lib = inputs.nixpkgs.lib.extend (
            _: _: inputs.home-manager.lib // (import ../lib/home.nix { inherit pkgs; })
          );
          modules = [
            inputs.krewfile.homeManagerModules.krewfile
            inputs.noctalia.homeModules.default
            inputs.nsticky.homeModules.default
            inputs.sops-nix.homeManagerModules.sops
            inputs.stylix.homeModules.stylix
            inputs.vicinae.homeManagerModules.default

            {
              home = {
                username = primaryUser;
                homeDirectory =
                  if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${primaryUser}" else "/home/${primaryUser}";
                stateVersion = "26.05";
              };

              nix.package = pkgs.nix;

              features = {
                home = {
                  firefox = {
                    inherit trustedRootCertificates;
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
      }) config.systems
    );
}
