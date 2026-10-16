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
        pkgs.gnumake
        pkgs.go
        pkgs.nodejs
        pkgs.pkg-config
        pkgs.pnpm
        pkgs.rustc
        pkgs.uv

        # general cli
        pkgs.fd
        pkgs.file
        pkgs.gh
        pkgs.git
        pkgs.htop
        pkgs.lsof
        pkgs.p7zip
        pkgs.rsync
        pkgs.shellcheck
        pkgs.sqlite
        pkgs.strace
        pkgs.tree
        pkgs.unzip
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
        pkgs.nmap
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
        pkgs.kubernetes-helm
        pkgs.talosctl
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
              # updates come from the flake input
              DISABLE_AUTOUPDATER = "1";
              TALOSCONFIG = config.sops.secrets."features/home/claude/configs/talosconfig".path;
            };

            shellAliases.claude = "claude --dangerously-skip-permissions";
          };

          # One-time setup, over SSH in ${workspace}: run `claude` to log in, trust the directory and accept
          # the bypass permissions warning, then `claude remote-control` to accept the Remote Control prompt.
          systemd.user.services.claude-remote-control = {
            Unit = {
              Description = "Claude Code Remote Control server";
              StartLimitIntervalSec = 0;
            };
            Service = {
              WorkingDirectory = workspace;
              # login shell, so sessions get the full system PATH (incl. sudo wrapper) and session variables
              ExecStart = "${lib.getExe pkgs.zsh} -lc 'exec claude remote-control --name claude --permission-mode bypassPermissions'";
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
}
