# shellcheck shell=bash
MAGICK_CMD="${magick_cmd:-magick}"
GS_CMD="${gs_cmd:-gs}"

rasterizePDF() {
    PATH="$(dirname "$GS_CMD"):$PATH"
    echo "Usage: rasterizePDF fromfile.pdf : this makes a 300dpi raster version. And optimizes it with ghostscript. Output is \"$1-scanned.pdf\""
    tmpfile=$(mktemp).pdf
    echo "Creating raster version... (in $tmpfile)"
    "$MAGICK_CMD" -render -density 300 "$1" "$tmpfile"
    echo "Optimizing to shrink pdf file..."
    "$GS_CMD" -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$1-scanned.pdf" "$tmpfile"
}

convertImagesToPDF() {
    PATH="$(dirname "$GS_CMD"):$PATH"
    echo "Usage: convertImagesToPDF file1.jpg file2.jpg ... : this will make optimized PDF, named output.pdf"
    tmpfile=$(mktemp).pdf
    echo "Creating merged version... (in $tmpfile)"
    # shellcheck disable=SC2068
    "$MAGICK_CMD" -resize 1200 -render -density 300 $@ "$tmpfile"
    echo "Optimizing to shrink pdf file..."
    "$GS_CMD" -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dNOPAUSE -dQUIET -dBATCH -sOutputFile="output.pdf" "$tmpfile"
}
