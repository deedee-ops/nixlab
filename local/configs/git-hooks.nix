{ inputs, ... }:
{
  # https://flake.parts/options/pre-commit-hooks-nix
  imports = [ inputs.git-hooks.flakeModule ];

  perSystem = _: {
    pre-commit = {
      check.enable = true;

      settings = {
        excludes = [ ".direnv" ];

        hooks = {
          check-case-conflicts.enable = true;
          check-shebang-scripts-are-executable.enable = true;
          mixed-line-endings.enable = true;

          deadnix.enable = true;
          flake-checker.enable = true;
          statix.enable = true;
          nixfmt-rfc-style.enable = true;

          lua-ls.enable = true;
          shellcheck = {
            enable = true;
            excludes = [ ".*\.zsh" ];
          };
          stylua.enable = true;

          actionlint.enable = true;
          commitizen.enable = true;
        };
      };
    };
  };
}
