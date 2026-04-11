{ self, inputs, ... }:
{
  flake = {
    packageBuilders.neovim =
      { pkgs, theme, ... }:
      (inputs.nvf.lib.neovimConfiguration {
        inherit pkgs;
        modules = [
          ./neovim/autopairs.nix
          ./neovim/comment.nix
          ./neovim/lualine.nix
          ./neovim/treesitter.nix

          {
            config = {
              vim.theme = {
                enable = true;
              }
              // theme;
            };
          }
        ];
      }).neovim;

    nixosModules.packages-neovim =
      { pkgs, config, ... }:
      {
        environment.systemPackages = [
          (self.packageBuilders.neovim {
            inherit pkgs;
            inherit (config.features.nixos.globals) theme;
          })
        ];
      };
  };

  perSystem =
    { pkgs, ... }:
    {
      packages.neovim = self.packageBuilders.neovim {
        inherit pkgs;
        theme = {
          name = "catppuccin";
          style = "mocha";
        };
      };
    };
}
