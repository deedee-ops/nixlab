_: {
  flake.homeModules.features-home-opencode =
    { config, lib, ... }:
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
          "features/home/opencode/agents/chat.md" = {
            sopsFile = cfg.sopsSecretsFile;
            path = "${config.xdg.configHome}/opencode/agents/chat.md";
          };
          "features/home/opencode/agents/hermes.md" = {
            sopsFile = cfg.sopsSecretsFile;
            path = "${config.xdg.configHome}/opencode/agents/hermes.md";
          };
        };
        programs.opencode = {
          enable = true;
          settings = {
            disabled_providers = [ "opencode" ];
            default_agent = "chat";
            provider.vllm = {
              npm = "@ai-sdk/openai-compatible";
              name = "DeeDee vLLM";
              options.baseURL = "https://bifrost.ajgon.casa/v1";
              models = {
                "vllm/Qwen/Qwen3.6-27B".name = "Qwen3.6-27B";
                "vllm/openai/gpt-oss-120b".name = "gpt-oss-120b";
                "vllm/hermes-agent".name = "hermes";
              };
            };
            model = "vllm/vllm/Qwen/Qwen3.6-27B";
          };
        };

        home.shellAliases.oc = lib.getExe config.programs.opencode.package;
      };
    };
}
