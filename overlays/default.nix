_: {
  nixpkgs-overlays = _final: prev: {
    gdome2 = prev.gdome2.overrideAttrs (oldAttrs: {
      patches = oldAttrs.patches ++ [
        ./patches/gdome2__configure.patch
      ];
    });
  };
}
