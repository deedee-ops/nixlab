{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.chiaki-ng;

  # hack, to enable touchpad click while streaming.
  # Normally Linux hijacks touchpad, and treats it as a mouse, mapping touchpad click to left-click.
  # However chiaki doesn't support left-click, but lucky for us - interprets right-click as touchpad.
  # So swapping left-click with right-click makes touchpad behaving as expected, while also small portion
  # of touchpad (at the bottom) still behaving like left-click, to ease navigation on chiaki itself.
  padRemapper = pkgs.writeShellScriptBin "input-remapper" ''
    pad_name="Wireless Controller Touchpad"
    while true; do
      sleep 5
      if ${lib.getExe pkgs.xorg.xinput} | grep -q "$pad_name"; then
        pad_id="$(${lib.getExe pkgs.xorg.xinput} | grep 'Wireless Controller Touchpad' | sed -E 's@.*id=([0-9]+).*@\1@g')"

        if [[ "$(${lib.getExe pkgs.xorg.xinput} get-button-map "$pad_id")"] == 1* ]]; then
          ${lib.getExe pkgs.xorg.xinput} set-button-map "$pad_id" 3 2 1 4 5 6 7
        fi
      fi
    done
  '';
  chiakiAutostream = pkgs.writeShellScriptBin "chiaki-autostream" ''
    PATH="${pkgs.fping}/bin:${pkgs.chiaki-ng}/bin:${pkgs.coreutils}/bin:${pkgs.gawk}/bin:${pkgs.iproute2}/bin:$PATH"
    SUBNET="${cfg.autoStream.subnet}"
    TIMEOUT=30

    process_failure()
    {
      chiaki
      exit $?
    }

    # wait for network
    while ! networkctl | grep -q routable; do
      [ $seconds -gt $TIMEOUT ] && process_failure
      sleep 1
    done

    # quickly ping whole subnet to populate ARP table
    fping -q -c 1 -t 100 -g "$SUBNET"

    # find console IP
    ip neigh | grep -vi incomplete >> /tmp/debug
    for mac in $(ip neigh | grep -vi incomplete | awk '{ print $5 }' | awk -F: '{ print $1 ":" $2 ":" $3 }'); do
      echo "MAC: $mac" >> /tmp/debug
      if grep -q "$mac" ${./playstation-oui.txt}; then
        console_ip="$(ip neigh | grep -i "$mac" | awk '{print $1}')"
        break
      fi
    done
    echo "IP: $console_ip"
    [ -z "$console_ip" ] && process_failure

    # get console hostname
    console_hostname="$(chiaki list | grep Host | awk '{print $2}')"
    echo "Host: $console_host"
    [ -z "$console_hostname" ] && process_failure

    # get console registration key
    console_regkey="$(grep regist_key "${config.xdg.configHome}/Chiaki/Chiaki.conf" | cut -d '(' -f2 | cut -d "\\" -f1)"
    echo "RegKey: $console_regkey"
    [ -z "$console_regkey" ] && process_failure

    # wait for console to be in proper status for given time
    seconds=0
    ps_status="$(chiaki discover -h "$console_ip" 2>/dev/null)"
    while ! echo "$ps_status" | grep -q 'ready\|standby'
    do
      [ $seconds -gt $TIMEOUT ] && process_failure
      sleep 1
      ps_status="$(chiaki discover -h "$console_ip" 2>/dev/null)"
    done

    # wake up console from sleep/rest mode if not already awake
    if ! echo "$ps_status" | grep -q ready
    then
        chiaki wakeup -5 -h "$console_ip" -r "$console_regkey" 2>/dev/null
    fi

    # wait for console to be ready
    while ! echo "$ps_status" | grep -q ready
    do
      [ $seconds -gt $TIMEOUT ] && process_failure
      sleep 1
      ps_status="$(chiaki discover -h "$console_ip" 2>/dev/null)"
    done

    # run stream!
    chiaki --fullscreen stream "$console_hostname" "$console_ip"
  '';
in
{
  options.myHomeApps.chiaki-ng = {
    enable = lib.mkEnableOption "chiaki-ng";
    package = lib.mkOption {
      type = lib.types.package;
      description = "Chiaki package to be used";
      default = if cfg.autoStream.enable then chiakiAutostream else pkgs.chiaki-ng;
    };
    configFileSopsSecret = lib.mkOption {
      type = lib.types.str;
      description = "Sops secret name containing chiaki-ng config.";
      default = "home/apps/chiaki-ng/config";
    };
    autoStream = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "chiaki autostream";
          subnet = lib.mkOption {
            type = lib.types.str;
            description = "Subnet to scan for console. Subnets bigger than /24 are considerably slow.";
            example = "192.168.0.0/24";
          };
        };
      };
      description = "If enabled, chiaki will try to detect the console and run streaming directly.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."${cfg.configFileSopsSecret}" = { };

    xsession.initExtra = lib.mkAfter ''
      ${lib.getExe padRemapper} &
    '';

    home = {
      packages = [ cfg.package ];
      activation = {
        chiaki-ng = lib.hm.dag.entryAfter [ "sopsNix" ] ''
          mkdir -p ${config.xdg.configHome}/Chiaki ${config.xdg.dataHome}/Chiaki
          # @todo ugly hack to make binary available for kiosk
          cp ${lib.getExe cfg.package} ${config.xdg.dataHome}/Chiaki/chiaki-start
          cp ${
            config.sops.secrets."${cfg.configFileSopsSecret}".path
          } ${config.xdg.configHome}/Chiaki/Chiaki.conf
          chmod 700 ${config.xdg.dataHome}/Chiaki/chiaki-start
        '';
      };
    };
  };
}
