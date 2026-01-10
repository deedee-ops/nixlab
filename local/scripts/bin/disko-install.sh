#!/usr/bin/env bash

if (( $# != 3 )); then
    >&2 echo "Usage: $0 <machine name> <disk name> <disk device>"
    exit 1
fi

export ASSETS_DIR="@@ASSETS_DIR@@"

cp "${NIX_SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}" /tmp/bundle.crt
export NIX_SSL_CERT_FILE=/tmp/bundle.crt

cat "${ASSETS_DIR}/ca-ec384.crt" >> "${NIX_SSL_CERT_FILE}"
cat "${ASSETS_DIR}/ca-rsa4096.crt" >> "${NIX_SSL_CERT_FILE}"

nix run --extra-experimental-features 'nix-command flakes' 'github:nix-community/disko/latest#disko-install' -- \
    --flake "github:deedee-ops/nixlab#$1" \
    --option substituters 'https://nix.ajgon.casa/?priority=30 https://cache.nixos.org' \
    --option trusted-public-keys 'homelab:mM9UlYU+WDQSnxRfnV0gNcE+gLD/F9nkGIz97E22VeU= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=' \
    --option extra-substituters 'https://cache.garnix.io https://deploy-rs.cachix.org https://nix-community.cachix.org' \
    --option extra-trusted-public-keys 'cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g= deploy-rs.cachix.org-1:xfNobmiwF/vzvK1gpfediPwpdIP0rpDV2rYqx40zdSI= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=' --disk "$2" "$3"
