_: {
  flake.homeModules.features-home-aichat = _: {
    config = {
      programs = {
        aichat = {
          enable = true;
          settings = {
            model = "vllm:vllm/openai/gpt-oss-120b";
            clients = [
              {
                type = "openai-compatible";
                name = "vllm";
                api_base = "https://bifrost.ajgon.casa/v1";
                models = [
                  {
                    name = "vllm/Qwen/Qwen3.6-27B";
                    # disable reasoning, takes too long, and usually is not needed on
                    # simple queries which this will be used for
                    patch.body.chat_template_kwargs.enable_thinking = false;
                  }
                  {
                    name = "vllm/openai/gpt-oss-120b";
                  }
                ];
              }
            ];
          };
        };
        zsh = {
          plugins = [
            {
              name = "aichat";
              src = ./zsh;
            }
          ];
        };
      };

      xdg.configFile."aichat/roles/shell.md".text = ''
        ---
        model: vllm:vllm/Qwen/Qwen3.6-27B
        ---
        Provide only {{shell}} commands for {{os_distro}} without any description. Ensure the output is a valid {{shell}} command. If there is a lack of details, provide most logical solution. If multiple steps are required, try to combine them using '&&' (For PowerShell, use ';' instead). Output only plain text without any markdown formatting.
      '';
    };
  };
}
