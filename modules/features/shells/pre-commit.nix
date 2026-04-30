{ inputs, ... }:
{
  imports = [ inputs.git-hooks.flakeModule ];

  perSystem =
    { pkgs, lib, ... }:
    {
      pre-commit = {
        check.enable = true;

        settings = {
          excludes = [
            ".direnv"
            "\\.glsl$"
            "mpv.*\\.hook$"
            "\\.patch$"
          ];

          hooks = {
            check-case-conflicts.enable = true;
            check-executables-have-shebangs.enable = true;
            check-merge-conflicts.enable = true;
            check-shebang-scripts-are-executable.enable = true;
            end-of-file-fixer.enable = true;
            fix-byte-order-marker.enable = true;
            mixed-line-endings.enable = true;
            pre-commit-hook-ensure-sops = {
              enable = true;
              files = ".+\.sops\..*";
            };
            trim-trailing-whitespace.enable = true;

            deadnix.enable = true;
            flake-checker.enable = true;
            statix.enable = true;
            nixfmt.enable = true;

            check-json.enable = true;
            lua-ls.enable = true;
            shellcheck = {
              enable = true;
              excludes = [
                ".*\.zsh"
                ".envrc"
                ".*/nixos-infect"
              ];
            };
            stylua.enable = true;
            yamllint.enable = true;

            actionlint.enable = true;
            commitizen.enable = true;

            # custom hooks
            gitleaks = {
              enable = true;
              name = "gitleaks";
              package = pkgs.gitleaks;
              entry = "${lib.getExe pkgs.gitleaks} protect --verbose --redact --staged";
            };

            zizmor = {
              enable = true;
              name = "zizmor";
              package = pkgs.zizmor;
              entry = "${lib.getExe pkgs.zizmor}";
              files = ".github/workflows/.+\.yaml";
            };
          };
        };
      };
    };
}
