#!/usr/bin/env bash

# https://wiki.nixos.org/wiki/Incus#Custom_Images
incus image import --alias nixos/base/vm \
      "$(nix build .#nixosVMs.base.config.system.build.metadata --print-out-paths)/tarball/nixos-system-x86_64-linux.tar.xz" \
      "$(nix build .#nixosVMs.base.config.system.build.qemuImage --print-out-paths)/nixos.qcow2"

incus image list nixos/base/vm
