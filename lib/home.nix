{ pkgs, ... }:
{
  mkHomeActivationAfterSops =
    {
      name,
      script,
      envs ? [ ],
    }:
    {
      Unit = {
        After = [ "sops-nix.service" ];
        Requires = [ "sops-nix.service" ];
      };

      Install.WantedBy = [ "default.target" ];

      Service = {
        Type = "oneshot";
        Environment = [
          "PATH=${pkgs.coreutils}/bin:${pkgs.findutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin"
        ]
        ++ envs;
        ExecStart = "${(pkgs.writeShellScriptBin "${name}.sh" ''
          set -e

          ${script}
        '')}/bin/${name}.sh";
        Restart = "on-failure";
        RestartSec = 3;
      };
    };

  mkGuiStartupService =
    {
      package,
      command ? null,
      delay ? 0,
    }:
    {
      "${package.pname}" = {
        Unit = {
          Description = package.meta.description or "${package.pname}";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = if command == null then "${package}/bin/${package.meta.mainProgram}" else command;
        }
        // (
          if delay > 0 then
            {
              ExecStartPre = "${pkgs.coreutils}/bin/sleep ${toString delay}";
            }
          else
            { }
        );
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
