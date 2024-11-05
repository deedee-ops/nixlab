{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.xdg-ninja;
in
{
  options.myHomeApps.xdg-ninja = {
    enable = lib.mkEnableOption "xdg-ninja" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      activation = {
        xdg_python = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run touch "${config.xdg.stateHome}/python_history";
        '';
        xdg_ruby = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p "${config.xdg.dataHome}/irb" || true
        '';
      };

      packages = [ pkgs.xdg-ninja ];

      shellAliases = {
        wget = "${pkgs.wget}/bin/wget --hsts-file=\"${config.xdg.dataHome}/wget-hsts\"";
      };

      sessionVariables = {
        XDG_CONFIG_HOME = "${config.xdg.configHome}";
        XDG_CACHE_HOME = "${config.xdg.cacheHome}";
        XDG_DATA_HOME = "${config.xdg.dataHome}";
        XDG_STATE_HOME = "${config.xdg.stateHome}";

        # Ansible
        ANSIBLE_HOME = "${config.xdg.configHome}/ansible";
        ANSIBLE_CONFIG = "${config.xdg.configHome}/ansible.cfg";
        ANSIBLE_GALAXY_CACHE_DIR = "${config.xdg.cacheHome}/ansible/galaxy_cache";

        # AWS
        AWS_SHARED_CREDENTIALS_FILE = "${config.xdg.configHome}/aws/credentials";
        AWS_CONFIG_FILE = "${config.xdg.configHome}/aws/config";

        # nvidia
        CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";

        # Docker
        DOCKER_CONFIG = "${config.xdg.configHome}/docker";

        # Go
        GOPATH = "${config.xdg.dataHome}/go";

        # GTK-2.0
        GTK2_RC_FILES = "${config.xdg.configHome}/gtk-2.0/gtkrc";

        # Less
        LESSHISTFILE = "${config.xdg.stateHome}/less/history";

        # Minio
        MC_CONFIG_DIR = "${config.xdg.configHome}/minio";

        # NPM
        NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";

        # Postgres
        PSQL_HISTORY = "${config.xdg.dataHome}/psql_history";

        # Python
        PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonrc";
        PYTHON_HISTORY = "${config.xdg.stateHome}/python_history";

        # Ruby
        IRBRC = "${config.xdg.configHome}/irb/irbrc";

        # Rust
        CARGO_HOME = "${config.xdg.dataHome}/cargo";

        # Screen
        SCREENRC = "${config.xdg.configHome}/screen/screenrc";

        # Sqlite3
        SQLITE_HISTORY = "${config.xdg.cacheHome}/sqlite_history";
      };
    };

    xdg.configFile = {
      "irb/irbrc".text = ''
        IRB.conf[:HISTORY_FILE] ||= File.join(ENV["XDG_DATA_HOME"], "irb", "history")
      '';

      "npm/npmrc".text = ''
        prefix=${config.xdg.dataHome}/npm
        cache=${config.xdg.cacheHome}/npm
        init-module=${config.xdg.configHome}/npm/config/npm-init.js
        tmp=''${XDG_RUNTIME_DIR}/npm
      '';

      "python/pythonrc".text = ''
        #!/usr/bin/env python3
        # This entire thing is unnecessary post v3.13.0a3
        # https://github.com/python/cpython/issues/73965

        def is_vanilla() -> bool:
          """ :return: whether running "vanilla" Python """
          import sys
          return not hasattr(__builtins__, '__IPYTHON__') and 'bpython' not in sys.argv[0]


        def setup_history():
          """ read and write history from state file """
          import os
          import atexit
          import readline
          from pathlib import Path

          # https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html#variables
          if state_home := os.environ.get('XDG_STATE_HOME'):
            state_home = Path(state_home)
          else:
            state_home = Path.home() / '.local' / 'state'
          if not state_home.is_dir():
            print("Error: XDG_SATE_HOME does not exist at", state_home)

          history: Path = state_home / 'python_history'

          # https://github.com/python/cpython/issues/105694
          if not history.is_file():
            with open(history,"w") as f:
              f.write("_HiStOrY_V2_" + "\n\n") # breaks on macos + python3 without this.

          readline.read_history_file(history)
          atexit.register(readline.write_history_file, history)


        if is_vanilla():
          setup_history()
      '';
    };
  };
}
