{ self, ... }:
{
  flake.homeModules.features-home-opencode =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.features.home.opencode;
    in
    {
      options.features.home.opencode = {
        sopsSecretsFile = lib.mkOption {
          type = lib.types.path;
          description = "Path to sopsfile containing secrets";
          default = ./secrets.sops.yaml;
        };
      };
      config = {
        sops.secrets = {
          "features/home/opencode/configs/kubeconfig" = {
            sopsFile = cfg.sopsSecretsFile;
          };
          "features/home/opencode/configs/talosconfig" = {
            sopsFile = cfg.sopsSecretsFile;
          };
          "features/home/opencode/agents/chat.md" = {
            sopsFile = cfg.sopsSecretsFile;
            path = "${config.xdg.configHome}/opencode/agents/chat.md";
          };
          "features/home/opencode/agents/hermes.md" = {
            sopsFile = cfg.sopsSecretsFile;
            path = "${config.xdg.configHome}/opencode/agents/hermes.md";
          };
          "features/home/opencode/agents/homelab-k8s-debugger.md" = {
            sopsFile = cfg.sopsSecretsFile;
            path = "${config.xdg.configHome}/opencode/agents/homelab-k8s-debugger.md";
          };
        };
        programs.opencode = {
          enable = true;
          tui.theme = self.theme.name;
          settings = {
            disabled_providers = [ "opencode" ];
            default_agent = "chat";
            mcp = {
              deedee = {
                type = "remote";
                url = "https://mcp.ajgon.casa";
                enabled = true;
                # timeout = 5000;
              };
              siderolabs = {
                type = "remote";
                url = "https://docs.siderolabs.com/mcp";
                enabled = true;
              };
            };
            model = "vllm/vllm/openai/gpt-oss-120b";
            plugin = [ "superpowers@git+https://github.com/obra/superpowers.git#f2cbfbe" ];
            provider.vllm = {
              npm = "@ai-sdk/openai-compatible";
              name = "DeeDee vLLM";
              options.baseURL = "https://bifrost.ajgon.casa/v1";
              models = {
                "vllm/openai/gpt-oss-120b".name = "gpt-oss-120b";
                "vllm/hermes-agent".name = "hermes";
              };
            };
          };
        };

        home.shellAliases.oc = lib.getExe (
          pkgs.writeShellApplication {
            name = "opencode.sh";
            runtimeInputs = [
              pkgs.fluxcd
              pkgs.kubectl
              pkgs.talosctl
            ];
            text = ''
              export KUBECONFIG="${config.sops.secrets."features/home/opencode/configs/kubeconfig".path}"
              export TALOSCONFIG="${config.sops.secrets."features/home/opencode/configs/talosconfig".path}"
              ${lib.getExe config.programs.opencode.package}
            '';
          }
        );
      };
    };
}
