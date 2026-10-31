_: {
  flake.nixosModules.hosts-liadtop-devices =
    { lib, ... }:
    let
      lidAction = "suspend"; # suspend or suspend-then-hibernate
    in
    {
      hardware = {
        graphics.enable = true;
        i2c.enable = true;
        wirelessRegulatoryDatabase = true;
      };

      networking = {
        networkmanager = {
          enable = true;
          wifi.powersave = false; # MT7922 drops connections with powersave on
        };
        hostName = "liadtop";
      };

      boot = {
        # MT7922 stability: explicit regdomain (world domain limits txpower) and no ASPM
        extraModprobeConfig = ''
          options cfg80211 ieee80211_regdom=PL
          options mt7921e disable_aspm=1
        '';
      };

      features.nixos.audio = {
        defaultSink = "alsa_output.pci-0000_04_00.6.HiFi__Speaker__sink";
        defaultSource = "alsa_input.pci-0000_04_00.6.HiFi__Mic1__source";
      };

      systemd.sleep.settings.Sleep = lib.optionalAttrs (lidAction == "suspend-then-hibernate") {
        AllowSuspendThenHibernate = "yes";
        HibernateDelaySec = "30min";
      };

      services = {
        logind.settings.Login = {
          HandleLidSwitch = lidAction;
          HandleLidSwitchDocked = "ignore";
          HandleLidSwitchExternalPower = lidAction;
          HandlePowerKey = lidAction;
          HandlePowerKeyLongPress = "poweroff";
          InhibitDelayMaxSec = 10;
        };

        upower.enable = true;
      };
    };
}
