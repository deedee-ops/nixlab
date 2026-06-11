{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

{
  env = {
    SOPS_AGE_KEY = config.secretspec.secrets.SOPS_AGE_KEY;
  };

  packages = [
    inputs.deploy-rs.packages."${pkgs.stdenv.system}".default
    inputs.nixos-anywhere.packages."${pkgs.stdenv.system}".default

    pkgs.nh
    pkgs.nix-inspect
    pkgs.nix-output-monitor
    pkgs.sops
    pkgs.yq-go
  ];

  languages = {
    nix = {
      enable = true;
      lsp.enable = true;
    };
    lua = {
      enable = true;
      lsp.enable = true;
    };
    shell = {
      enable = true;
      lsp.enable = true;
    };
  };

  git-hooks = {
    excludes = [
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

      commitizen.enable = true;

      # custom hooks
      gitleaks = {
        enable = true;
        name = "gitleaks";
        package = pkgs.gitleaks;
        entry = "${lib.getExe pkgs.gitleaks} protect --verbose --redact --staged";
      };
    };
  };

  enterShell = ''
    ${lib.getExe pkgs.git} fetch --all
  '';
}
