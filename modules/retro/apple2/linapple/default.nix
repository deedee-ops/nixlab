{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.myRetro) core;

  cfg = config.myRetro.apple2;
in
{
  config = lib.mkIf (cfg.enable && cfg.package.pname == "linapple") {
    home.packages = [
      (pkgs.writeShellScriptBin "linapple" ''
        PATH="${
          lib.makeBinPath [
            pkgs.coreutils-full
            pkgs.gnused
          ]
        }"

        conffile="$(mktemp)"
        savepath="${cfg.saveStatePath}/$(basename "$1" | sed 's@\.[^.]*$@@g')"
        mkdir -p "$savepath"
        touch "$savepath/state0.sav"
        touch "$savepath/state1.sav"
        touch "$savepath/state2.sav"
        touch "$savepath/state3.sav"
        touch "$savepath/state4.sav"

        echo $confgile
        echo $savepath

        cat "${config.xdg.configHome}/retro/linapple.conf" > "$conffile"
        sed -i"" "s@Save State Directory =@Save State Directory = $savepath@g" "$conffile"

        export HOME="$(dirname "$1")"
        ${lib.getExe cfg.package} --conf "$conffile" --d1 "$@"

        rm -rf "$conffile"
      '')
    ];

    xdg.configFile."retro/linapple.conf".text = ''
      # LINAPPLE CONFIGURATION FILE
        Computer Emulation = 3
        Keyboard Type = 0
        Keyboard Rocker Switch = 0
        Sound Emulation = 1
        Soundcard Type = 2
        Joystick 0 = 2
        Joystick 1 = 0
        Joy0Index   = 0
        Joy1Index   = 1
        Joy0Button1	= 0
        Joy0Button2	= 1
        Joy1Button1	= 0
        Joy0Axis0   = 0
        Joy0Axis1   = 1
        Joy1Axis0   = 0
        Joy1Axis1   = 1
        JoyExitEnable   = 0
        JoyExitButton0  = 8
        JoyExitButton1  = 9
        Serial Port	= 0
        Emulation Speed = 10
        Enhance Disk Speed = 1
        Video Emulation = 1
        Monochrome Color = #C0C0C0
        Singlethreaded = 0
        Mouse in slot 4 = 0
        Parallel Printer Filename =
        Printer idle limit = 10
        Append to printer file = 1
        Harddisk Enable = 0
        Clock Enable = 4
        HDV Starting Directory =
        Harddisk Image 1 =
        Harddisk Image 2 =
        Slot 6 Directory =
        Disk Image 1 =
        Disk Image 2 =
        Slot 6 Autoload = 0
        Save State Filename = state.sav
        Save State Directory =
        Save State On Exit = 0
        Fullscreen = 0
        Boot at Startup = 1
        Show Leds = 1
      # FTP Server    = ftp://ftp.apple.asimov.net/pub/apple_II/images/games/
      # FTP ServerHDD = ftp://ftp.apple.asimov.net/pub/apple_II/images/
      # FTP UserPass  = anonymous:my-mail@mail.com
      # FTP Local Dir =
        Screen factor = ${
          builtins.toString (
            if core.screenWidth / 560 > core.screenHeight / 384 then
              core.screenHeight / 384
            else
              core.screenWidth / 560
          )
        }
      #	Screen Width  = 560
      #	Screen Height = 384
    '';
  };
}
