{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  bitwarden-cli,
  salt ? "changeme",
}:

buildGoModule rec {
  pname = "portwarden";
  version = "unstable-2023-09-18";

  src = fetchFromGitHub {
    owner = "vwxyzjn";
    repo = "portwarden";
    rev = "69a0337bbf844078eed3b8ce82fd2d0d0cd7afdb";
    hash = "sha256-c7duPFRRSk6DHJSfA851TBEh+qnDfKBWlWIqUjY7m+w=";
  };

  proxyVendor = true;
  vendorHash = "sha256-DfgPTsB976Th+9wpBRRQBQNNMU4IuT8bB8RzDZSugos=";

  nativeBuildInputs = [ makeWrapper ];
  ldflags = [
    "-s"
    "-w"
    "-X=main.version=${src.rev}"
  ];
  subPackages = [ "cmd/portwarden" ];

  preBuild = ''
    Salt="${salt}" go run utils/generate_salt_file.go
  '';

  postFixup = ''
    wrapProgram "$out/bin/portwarden" \
      --prefix PATH : "${lib.makeBinPath [ bitwarden-cli ]}"
  '';

  meta = with lib; {
    description = "Create Encrypted Backups of Your Bitwarden Vault with Attachments ";
    homepage = "https://github.com/vwxyzjn/portwarden";
    license = licenses.mit;
    maintainers = with maintainers; [ ajgon ];
    mainProgram = "portwarden";
  };
}
