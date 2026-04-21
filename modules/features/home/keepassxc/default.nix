{ self, ... }:
{
  flake.homeModules.features-home-keepassxc =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      config =
        let
          secretsDbPath = "${config.home.homeDirectory}/Sync/sync/keepass/Passwords.kdbx";
        in
        {
          programs.keepassxc.enable = true;

          home.activation.init-keepassxc = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            if [ ! -f "${config.xdg.configHome}/keepassxc/keepassxc.ini" ]; then
              mkdir -p "${config.xdg.configHome}/keepassxc"
              cat > "${config.xdg.configHome}/keepassxc/keepassxc.ini" << 'EOF'
            [General]
            AutoOpenLastDatabases=true
            LastDatabases=${secretsDbPath}

            [Browser]
            AlwaysAllowAccess=true
            AlwaysAllowUpdate=true
            Enabled=true

            [FdoSecrets]
            ConfirmAccessItem=false
            Enabled=true

            [GUI]
            ApplicationTheme=${self.theme.polarity}
            MinimizeToTray=true
            ShowTrayIcon=true
            MinimizeOnStartup=true
            MinimizeOnClose=true
            QuietSuccess=true

            [Security]
            IconDownloadFallback=true
            LockDatabaseIdle=false
            LockDatabaseScreenLock=false

            EOF
            fi
          '';

          systemd.user.services = lib.mkGuiStartupService {
            package = pkgs.keepassxc;
            command = "${lib.getExe pkgs.keepassxc} --minimized ${secretsDbPath}";
          };

          xdg = {
            dataFile."dbus-1/services/org.freedesktop.secrets.service".text = ''
              [D-BUS Service]
              Name=org.freedesktop.secrets
              Exec=${lib.getExe pkgs.keepassxc}
            '';

            portal = {
              enable = true;
              extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
              config.common.default = [ "gtk" ];
            };
          };
        };
    };
}
