{ pkgs, ... }:
{
  mkHomeActivationAfterSops = name: script: {
    Unit = {
      After = [ "sops-nix.service" ];
      Requires = [ "sops-nix.service" ];
    };

    Install.WantedBy = [ "default.target" ];

    Service = {
      Type = "oneshot";
      Environment = [
        "PATH=${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin"
      ];
      ExecStart = "${(pkgs.writeShellScriptBin "${name}.sh" ''
        set -e

        ${script}
      '')}/bin/${name}.sh";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
