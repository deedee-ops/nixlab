# mandark

## Provision

- Use <https://www.gandi.net/> VPS hosting
- Create a NixOS machine
- Use smallest (V-R1) machine

- Adjust `/etc/ssh/ssh_host_ed25519_key` and `/etc/ssh/ssh_host_ed25519_key.pub`
  files from `modules/hosts/mandark/secrets.sops.yaml`
- Adjust in `modules/hosts/mandark/deploy.nix` the `flake.deploy.nodes.mandark.hostname`
  for the new machine IP
- For initial provisioning, change `initialDeploy = true` in `deploy.nix`
  - `deploy -s .#mandark`
  - It will throw error, but deploy will be fine
  - Change `initialDeploy = false`
  - `deploy -s .#mandark` - again to get into success state
