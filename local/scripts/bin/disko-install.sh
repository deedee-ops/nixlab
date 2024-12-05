#!/usr/bin/env bash

if (( $# != 3 )); then
    >&2 echo "Usage: $0 <machine name> <disk name> <disk device>"
    exit 1
fi

nix run --extra-experimental-features 'nix-command flakes' 'github:nix-community/disko/latest#disko-install' -- \
    --flake "github:deedee-ops/nixlab#$1" \
    --option extra-substituters 'https://cache.garnix.io https://cache.lix.systems https://deploy-rs.cachix.org https://nix-community.cachix.org' \
    --option extra-trusted-public-keys 'cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g= cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o= deploy-rs.cachix.org-1:xfNobmiwF/vzvK1gpfediPwpdIP0rpDV2rYqx40zdSI= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=' --disk "$2" "$3"
