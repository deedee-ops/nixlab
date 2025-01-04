#!/usr/bin/env bash

# https://wiki.nixos.org/wiki/Incus#Custom_Images
incus image import --alias nixos/base/vm \
      "$(nix build github:deedee-ops/nixlab#nixosVMs.base.config.system.build.metadata --print-out-paths)/tarball/"*-x86_64-linux.tar.xz \
      "$(nix build github:deedee-ops/nixlab#nixosVMs.base.config.system.build.qemuImage --print-out-paths)/nixos.qcow2"

incus image list nixos/base/vm
