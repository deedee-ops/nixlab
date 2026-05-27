_: {
  flake.homeModules.features-home-opencode = _: {
    config = {
      programs.opencode = {
        enable = true;
        settings = {
          disabled_providers = [ "opencode" ];
          provider.vllm = {
            npm = "@ai-sdk/openai-compatible";
            name = "DeeDee vLLM";
            options.baseURL = "https://bifrost.ajgon.casa/v1";
            models = {
              "vllm/Qwen/Qwen3.6-27B".name = "Qwen3.6-27B";
              "vllm/openai/gpt-oss-120b".name = "gpt-oss-120b";
            };
          };
          model = "vllm/vllm/Qwen/Qwen3.6-27B";
        };
      };
    };
  };
}
