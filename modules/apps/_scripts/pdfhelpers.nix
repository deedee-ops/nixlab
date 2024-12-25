{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.scripts.pdfhelpers;
in
{
  options.myHomeApps.scripts.pdfhelpers = {
    enable = lib.mkEnableOption "PDF helper scripts";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "rasterizePDF" ''
        PATH="${
          lib.makeBinPath [
            pkgs.ghostscript_headless
            pkgs.imagemagick
          ]
        }"
        echo "Usage: rasterizePDF fromfile.pdf : this makes a 300dpi raster version. And optimizes it with ghostscript. Output is \"$1-scanned.pdf\""
        tmpfile=$(mktemp).pdf
        echo "Creating raster version... (in $tmpfile)"
        magick -render -density 300 "$1" "$tmpfile"
        echo "Optimizing to shrink pdf file..."
        gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$1-scanned.pdf" "$tmpfile"
      '')
      (pkgs.writeShellScriptBin "convertImagesToPDF" ''
        PATH="${
          lib.makeBinPath [
            pkgs.ghostscript_headless
            pkgs.imagemagick
          ]
        }"
        echo "Usage: convertImagesToPDF file1.jpg file2.jpg ... : this will make optimized PDF, named output.pdf"
        tmpfile=$(mktemp).pdf
        echo "Creating merged version... (in $tmpfile)"
        # shellcheck disable=SC2068
        magick -resize 1200 -render -density 300 $@ "$tmpfile"
        echo "Optimizing to shrink pdf file..."
        gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET -dBATCH -sOutputFile="output.pdf" "$tmpfile"
      '')
    ];
  };
}
