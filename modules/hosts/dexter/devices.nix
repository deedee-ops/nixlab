_: {
  flake.nixosModules.hosts-dexter-devices =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.ddcutil ];
      hardware = {
        i2c.enable = true;
        graphics = {
          enable = true;
          extraPackages = [ pkgs.intel-media-driver ];
        };
      };

      # igc defaults to a 256-descriptor RX ring, which overflows on 2.5G bursts (rx_fifo_errors)
      systemd.network.links."40-enp89s0".linkConfig.RxBufferSize = 4096;

      features.nixos.audio.defaultSink = "alsa_output.pci-0000_00_1f.3.analog-stereo";

      services.pipewire.wireplumber.extraConfig."10-disable-hdmi" = {
        "monitor.alsa.rules" = [
          {
            matches = [ { "node.name" = "~alsa_output.*hdmi.*"; } ];
            actions.update-props = {
              "node.disabled" = true;
            };
          }
        ];
      };
    };
}
