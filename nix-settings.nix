{
  substituters = [
    "https://nix.ajgon.casa"
  ];
  trusted-public-keys = [
    "nix.ajgon.casa-1:qVYJDXgy/BlE5IDjHvjRKb4ArzZKMqP+hBL3UHAGbb4="
  ];
  connect-timeout = 5;
  warn-dirty = false;
  download-buffer-size = 524288000;
  # always check for non-existing packages in substituters
  narinfo-cache-negative-ttl = 0;
}
