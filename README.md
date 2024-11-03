# nixlab

## Prepare base incus VM

```bash
nix run .#build-base-vm

# or if you don't want to clone repo
nix run github:deedee-ops/nixlab#build-base-vm
```

This will build and import `nixos/base/vm` image to incus.

## Launch the VM

```bash
# trusted is profile name
incus launch --vm nixos/base/vm <machine name> -c volatile.eth0.hwaddr=<mac address> -p trusted
```

## Bootstrap machine to the VM

```bash
nix run .#bootstrap <machine name> [machine IP]
```

- `machine name` is a machine identificator, one from the `./machines`
- `machine ip` is optional, if not provided, it will be picked up from `./machines/<machine>/default.nix`

## Deploy machine

```bash
deploy .#<machine name>
```
