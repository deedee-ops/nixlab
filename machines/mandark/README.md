# mandark

## Provision

- Create machine with `Ubuntu 22.04 LTS` (newer ones may not work)
- Use at least $6 droplet (25G diskspace)
- Add extra cloud init config when configuring machine:

```yaml
#cloud-config

runcmd:
  - >-
    curl https://raw.githubusercontent.com/deedee-ops/nixlab/refs/heads/master/machines/mandark/nixos-infect
    | PROVIDER=digitalocean NIX_CHANNEL=nixos-25.05 bash 2>&1 | tee /tmp/infect.log
```

- After successful provision, copy (from remote) `/etc/nixos/networking.nix` to
  `machines/mandark/networking.nix`. Remove `nameservers` stanza.
- Adjust in `machines/mandard/default.nix` the `flakePart.deploy.nodes.mandark.target`
  for the new machine IP, and comment out `flakePart.deploy.nodes.mandark.sshUser`
  for initial provisioning.
