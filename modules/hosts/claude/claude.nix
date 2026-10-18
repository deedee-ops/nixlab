{ inputs, ... }:
{
  # Unsandboxed Claude Code box: the agent runs as the primary user with passwordless root.
  # Sessions are served via Remote Control (claude.ai/code, Claude desktop and mobile apps),
  # files attached there are downloaded onto this machine.
  flake.nixosModules.hosts-claude-claude =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      username = config.features.nixos.user.name;
      workspace = "/home/${username}/workspace";
      claudePkg = inputs.claude-code.packages."${pkgs.stdenv.hostPlatform.system}".default;
    in
    {
      security.sudo.wheelNeedsPassword = false;

      # run prebuilt binaries fetched by agents (pip/npm wheels, Claude Desktop SSH engine etc.)
      programs.nix-ld.enable = true;

      # start the remote control server at boot, without a login session
      users.users."${username}".linger = true;

      systemd.tmpfiles.rules = [
        "d ${workspace} 0755 ${username} users -"
      ];

      environment.systemPackages = [
        claudePkg

        # languages and build tooling
        (pkgs.python3.withPackages (
          python-pkgs: with python-pkgs; [
            beautifulsoup4
            httpx
            matplotlib
            numpy
            pandas
            pillow
            pip
            pyyaml
            requests
          ]
        ))
        pkgs.cargo
        pkgs.cmake
        pkgs.gcc
        pkgs.gdb
        pkgs.gnumake
        pkgs.hyperfine
        pkgs.nodejs
        pkgs.pkg-config
        pkgs.pnpm
        pkgs.rustc
        pkgs.uv

        # go - toolchain taken from gopls, so `go` matches the version gopls/golangci-lint/govulncheck are
        # built with (nixpkgs' default `go` lags behind, and these refuse modules newer than their own toolchain)
        pkgs.gopls.go
        pkgs.delve
        pkgs.gofumpt
        pkgs.golangci-lint
        pkgs.gopls
        pkgs.gotestsum
        pkgs.gotools
        pkgs.govulncheck

        # linters and formatters
        pkgs.actionlint
        pkgs.deadnix
        pkgs.hadolint
        pkgs.markdownlint-cli2
        pkgs.nixfmt
        pkgs.shfmt
        pkgs.statix
        pkgs.yamllint

        # general cli
        pkgs.fd
        pkgs.file
        pkgs.gh
        pkgs.git
        pkgs.git-lfs
        pkgs.htop
        pkgs.just
        pkgs.lsof
        pkgs.p7zip
        pkgs.prek
        pkgs.pv
        pkgs.rsync
        pkgs.shellcheck
        pkgs.sqlite
        pkgs.strace
        pkgs.tree
        pkgs.unzip
        pkgs.xxd
        pkgs.yq-go
        pkgs.zip

        # documents and media
        pkgs.chromium
        pkgs.ffmpeg
        pkgs.imagemagick
        pkgs.pandoc
        pkgs.poppler-utils

        # network
        pkgs.dnsutils
        pkgs.ethtool
        pkgs.iw
        pkgs.mtr
        pkgs.iperf3
        pkgs.nmap
        pkgs.socat
        pkgs.tcpdump
        pkgs.wirelesstools

        # hardware
        pkgs.dmidecode
        pkgs.lm_sensors
        pkgs.lshw
        pkgs.nvme-cli
        pkgs.pciutils
        pkgs.smartmontools
        pkgs.usbutils

        # homelab
        pkgs.cilium-cli
        pkgs.fluxcd
        pkgs.hubble
        pkgs.kubeconform
        pkgs.kubernetes-helm
        pkgs.kustomize
        pkgs.talosctl

        # secrets - decrypting this host's sops file with the host ssh key
        pkgs.age
        pkgs.sops
        pkgs.ssh-to-age
      ];

      home-manager.users."${username}" =
        { config, ... }:
        {
          sops.secrets = {
            "features/home/claude/configs/talosconfig" = {
              sopsFile = ./secrets.sops.yaml;
              mode = "0600";
            };
            # read-only key, see claude-context.md
            "features/home/claude/configs/unifiApiKey" = {
              sopsFile = ./secrets.sops.yaml;
              mode = "0600";
              path = "${config.xdg.configHome}/unifi/api-key";
            };
          };

          home = {
            file.".claude/CLAUDE.md".source = ./claude-context.md;

            sessionVariables = {
              # set by features-home-telemetry; tools change behaviour under CI (non-interactive modes, different
              # defaults, skipped steps), which surprises the agent - null drops it from the session entirely
              CI = lib.mkForce null;
              # also from features-home-telemetry, but not a telemetry switch - it blocks all Hugging Face downloads
              HF_HUB_OFFLINE = lib.mkForce null;
              # updates come from the flake input
              DISABLE_AUTOUPDATER = "1";
              TALOSCONFIG = config.sops.secrets."features/home/claude/configs/talosconfig".path;
            };

            shellAliases.claude = "claude --dangerously-skip-permissions";
          };

          # One-time setup, over SSH in ${workspace}: run `claude` to log in, trust the directory and accept
          # the bypass permissions warning, then `claude remote-control` to accept the Remote Control prompt.
          systemd.user =
            let
              # remote control re-registers the environment recorded here on start; sessions are bound to the
              # environment, so losing this file orphans every chat in the claude.ai / desktop UI
              pointer = "${config.home.homeDirectory}/.claude/projects/${
                lib.replaceStrings [ "/" ] [ "-" ] workspace
              }/bridge-pointer.json";
              stateDir = "${config.xdg.stateHome}/claude-remote-control";
              pointerBackup = "${stateDir}/bridge-pointer.json";
              debugLog = "${stateDir}/debug.log";
              preStart = pkgs.writeShellScript "claude-remote-control-pre" ''
                mkdir -p ${lib.escapeShellArg (dirOf pointerBackup)}
                if [ ! -e ${lib.escapeShellArg pointer} ] && [ -e ${lib.escapeShellArg pointerBackup} ]; then
                  mkdir -p ${lib.escapeShellArg (dirOf pointer)}
                  cp ${lib.escapeShellArg pointerBackup} ${lib.escapeShellArg pointer}
                fi
                # keep the previous run's log for post-mortems, the debug log is unbounded otherwise
                if [ -e ${lib.escapeShellArg debugLog} ]; then
                  mv ${lib.escapeShellArg debugLog} ${lib.escapeShellArg "${debugLog}.1"}
                fi
              '';
              postStop = pkgs.writeShellScript "claude-remote-control-post" ''
                if [ -e ${lib.escapeShellArg pointer} ]; then
                  cp ${lib.escapeShellArg pointer} ${lib.escapeShellArg pointerBackup}
                fi
              '';
              # --debug-file is passed on to every spawned session, each writes its own debug-<session>.log
              cleanup = pkgs.writeShellScript "claude-remote-control-cleanup" ''
                ${lib.getExe' pkgs.findutils "find"} ${lib.escapeShellArg stateDir} -maxdepth 1 -type f \
                  -name 'debug-*.log' -mtime +14 -delete
              '';
            in
            {
              services.claude-remote-control-cleanup = {
                Unit.Description = "Remove old Claude Code Remote Control session debug logs";
                Service = {
                  Type = "oneshot";
                  ExecStart = "${cleanup}";
                };
              };
              timers.claude-remote-control-cleanup = {
                Timer = {
                  OnCalendar = "daily";
                  Persistent = true;
                };
                Install.WantedBy = [ "timers.target" ];
              };

              services.claude-remote-control = {
                Unit = {
                  Description = "Claude Code Remote Control server";
                  StartLimitIntervalSec = 0;
                };
                Service = {
                  WorkingDirectory = workspace;
                  ExecStartPre = "${preStart}";
                  ExecStopPost = "${postStop}";
                  # login shell, so sessions get the full system PATH (incl. sudo wrapper) and session variables;
                  # the debug log records why registration failed or got a new environment (stdout is discarded)
                  ExecStart = "${lib.getExe pkgs.zsh} -lc 'exec claude remote-control --name claude --permission-mode bypassPermissions --debug-file ${debugLog}'";
                  Restart = "always";
                  RestartSec = 30;
                  # the status UI redraws every second, which would flood the journal; errors still go to stderr
                  StandardOutput = "null";
                  # stop like Ctrl+C - on SIGTERM only the pre-created session is resumed, sessions started from the UI are lost
                  KillSignal = "SIGINT";
                };
                Install.WantedBy = [ "default.target" ];
              };
            };
        };
    };
}
