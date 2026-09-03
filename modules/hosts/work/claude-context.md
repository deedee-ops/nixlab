# Sandbox Instructions

## Environment
- You are in a **sandboxed environment**.
- **kubectl** is **read-only**
- You can read all k8s resources **except secrets**.
- You have **sudo** access — install any extra packages you need.

## Installed tools
- **Go:** go, gofmt, gopls, staticcheck, goimports, dlv, golangci-lint
- **Web:** node, npm, npx, pnpm
- **K8s/Talos:** kubectl, talosctl, helm, yq, stern, flux, cilium, hubble
- **Docker:** docker CLI
- **General:** jq, git, rg, curl, make

## GitOps source
- The cluster is managed via GitOps using **ArgoCD**.
- The source repo is always available as downloaded files in `/home/ubuntu/k8s-gitops`.
- If it's not there, **stop and ask what to do next**.

## Working style
- Whatever the task (cluster debugging or writing a Go/web app), **be brief — get straight to the point**, no needless verbosity.
- **When in doubt, ask questions.**
