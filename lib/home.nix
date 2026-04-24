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
    }:
    {
      "${package.pname}" = {
        Unit = {
          Description = package.meta.description or "${package.pname}";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          # missing `bin/${package.meta.mainProgram}` is expected here, using only `${package}` for prefix matching
          ExecCondition = ''${pkgs.bash}/bin/sh -c 'for f in /proc/*/exe; do p=$(readlink "$f" 2>/dev/null); case "$p" in "$0"*) exit 1;; esac; done; exit 0' ${package}'';
          ExecStartPre = "-${pkgs.glib}/bin/gdbus wait --session --timeout 30 org.kde.StatusNotifierWatcher";
          ExecStart = if command == null then "${package}/bin/${package.meta.mainProgram}" else command;
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
