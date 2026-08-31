{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "mindwtr";
  version = "1.2.6";

  src = fetchurl {
    url = "https://github.com/dongdongbh/Mindwtr/releases/download/v${version}/Mindwtr-${version}-x86_64.AppImage";
    hash = "sha256-CwK8RzXek7ImA21kwgIsWxcC+vZo+5liDlc3ymeEqpE=";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    # Exec=mindwtr / Icon=mindwtr already match pname, no rewriting needed.
    install -Dm444 ${appimageContents}/Mindwtr.desktop \
      $out/share/applications/${pname}.desktop
    install -Dm444 ${appimageContents}/usr/share/metainfo/tech.dongdongbh.mindwtr.metainfo.xml \
      -t $out/share/metainfo
    cp -r ${appimageContents}/usr/share/icons $out/share/
  '';

  meta = {
    description = "Getting Things Done (GTD) productivity app";
    longDescription = ''
      Mindwtr is a to-do app built on the Getting Things Done (GTD) method:
      capture tasks and ideas, sort them with a short guided pass, and see only
      what you can act on right now. No account required; data stays local.
    '';
    homepage = "https://mindwtr.app";
    downloadPage = "https://github.com/dongdongbh/Mindwtr/releases";
    license = lib.licenses.agpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
    mainProgram = "mindwtr";
  };
}
