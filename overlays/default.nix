_: {
  nixpkgs-overlays = _final: prev: {
    dmraid = prev.dmraid.overrideAttrs (oldAttrs: {
      patches = oldAttrs.patches ++ [
        ./patches/dmraid__fix-dmevent_tool.patch
      ];
    });

    gdome2 = prev.gdome2.overrideAttrs (oldAttrs: {
      patches = oldAttrs.patches ++ [
        ./patches/gdome2__configure.patch
      ];
    });
  };
}
