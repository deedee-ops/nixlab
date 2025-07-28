{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myGames.wow;
in
{
  options.myGames.wow = {
    enable = lib.mkEnableOption "World of Warcraft";
    installDir = lib.mkOption {
      type = lib.types.str;
      description = "Directory to install.";
    };
    realmHost = lib.mkOption {
      type = lib.types.str;
      description = "Realm Host/IP to connect to.";
    };
    clientURL = lib.mkOption {
      type = lib.types.str;
      description = "URL to download client from.";
      default = "https://btground.tk/chmi/ChromieCraft_3.3.5a.zip";
    };
    HDPackURL = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "HD Pack URL. If null, HD pack won't be installed.";
      default = null;
      example = "https://btground.tk/chmi/additional_patches_for_335a.zip";
    };
    addonURLs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of direct URLs to download addons.";
      default = [ ];
      example = [
        "https://github.com/ErebusAres/ZygorGuidesPlus_3.3.5a-WOTLK/archive/refs/heads/main.zip"
        "https://github.com/NoM0Re/Addons/raw/main/src/Addons/AckisRecipeList.zip"
        "https://github.com/NoM0Re/Addons/raw/main/src/Addons/Cartographer.zip"
        "https://github.com/NoM0Re/Addons/raw/main/src/Addons/EveryQuest.zip"
        "https://github.com/NoM0Re/Addons/raw/main/src/Addons/Overachiever.zip"
        "https://github.com/NoM0Re/Addons/raw/main/src/Addons/Quartz.zip"
        "https://github.com/NoM0Re/Addons/raw/main/src/Addons/QuestHelper.zip"
        "https://github.com/RichSteini/Bagnon-3.3.5/archive/refs/heads/main.zip"
        "https://github.com/bkader/Skada-WoTLK/archive/refs/heads/main.zip"
        "https://github.com/widxwer/Questie/archive/refs/heads/335.zip"
      ];
    };
    refreshAddons = lib.mkEnableOption "fetching add-ons on each game run";
  };

  config =
    let
      bsdtar = lib.getExe' pkgs.libarchive "bsdtar";
      wget = lib.getExe pkgs.wget;
      zenity = lib.getExe pkgs.zenity;
      addonUpdate = builtins.concatStringsSep "\n" (
        builtins.map (addonURL: ''
          ${wget} --no-check-certificate -O "$tmp/addon.zip" ${addonURL}
          ${bsdtar} -xf "$tmp/addon.zip" -C "${cfg.installDir}/Interface/AddOns/"
          rm -rf "$tmp/addon.zip"
        '') cfg.addonURLs
      );
      wowPkg = pkgs.writeShellScriptBin "wow" (
        ''
          mkdir -p "${cfg.installDir}"
          cd "${cfg.installDir}"

          if [ ! -f "${cfg.installDir}/Wow.exe" ]; then
            if [ "$1" != "--install" ]; then
              ${zenity} --error --text "WoW not installed. Run 'wow --install' first."
              exit 1
            fi
            tmp="$(mktemp -d)"
            ${wget} --no-check-certificate -O "$tmp/client.zip" ${cfg.clientURL}
            ${bsdtar} -xf "$tmp/client.zip" -C "${cfg.installDir}/" --strip-components=1
            rm -rf "$tmp/client.zip"
        ''
        + (lib.optionalString (cfg.HDPackURL != null) ''
          ${wget} --no-check-certificate -O "$tmp/hdpack.zip" ${cfg.HDPackURL}
          ${bsdtar} -xf "$tmp/hdpack.zip" -C "${cfg.installDir}/Data/" --strip-components=1
          rm -rf "${cfg.installDir}/Data/Patch-X.MPQ" "$tmp/hdpack.zip"
        '')
        + (lib.optionalString (!cfg.refreshAddons) addonUpdate)
        + ''
            mkdir -p "${cfg.installDir}/WTF"
            echo 'SET gxApi "OpenGL"' > "${cfg.installDir}/WTF/Config.wtf"
            cp ${./icon.png} "${cfg.installDir}/icon.png"
          fi
        ''
        + (lib.optionalString cfg.refreshAddons addonUpdate)
        + ''
          echo 'set realmlist ${cfg.realmHost}' > "${cfg.installDir}/Data/enUS/realmlist.wtf"
          cd "${cfg.installDir}"

          ${lib.getExe pkgs.wineWowPackages.stable} Wow.exe
        ''
      );
    in
    lib.mkIf cfg.enable {
      home.packages = [ wowPkg ];

      xdg = {
        dataFile = {
          "applications/WoW.desktop".text = ''
            [Desktop Entry]
            Name=World of Warcraft
            Exec=${lib.getExe wowPkg} %U
            Icon=${cfg.installDir}/icon.png
            Terminal=false
            Type=Application
            Categories=Games
            Name[en_US]=World of Warcraft
          '';
        };
      };
    };
}
