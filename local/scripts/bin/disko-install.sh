#!/usr/bin/env bash

if (( $# != 3 )); then
    >&2 echo "Usage: $0 <machine name> <disk name> <disk device>"
    exit 1
fi

nix run --extra-experimental-features 'nix-command flakes' 'github:nix-community/disko/latest#disko-install' -- \
    --flake "github:deedee-ops/nixlab#$1" \
    --option substituters 'https://s3.rzegocki.dev/nix?priority=30 https://cache.nixos.org' \
    --option trusted-public-keys 'homelab:mM9UlYU+WDQSnxRfnV0gNcE+gLD/F9nkGIz97E22VeU= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=' \
    --option extra-substituters 'https://cache.garnix.io https://deploy-rs.cachix.org https://nix-community.cachix.org' \
    --option extra-trusted-public-keys 'cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g= deploy-rs.cachix.org-1:xfNobmiwF/vzvK1gpfediPwpdIP0rpDV2rYqx40zdSI= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=' --disk "$2" "$3"
