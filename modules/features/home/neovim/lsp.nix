{ self, ... }:
{
  flake.modules.neovim = {
    bash =
      { pkgs, ... }:
      {
        extraPackages = [
          pkgs.bash-language-server
        ];

        specs.bash = {
          data = [
            pkgs.vimPlugins.nvim-lspconfig
          ];
          config = ''vim.lsp.enable("bashls")'';
        };
      };
    docker =
      { pkgs, ... }:
      {
        extraPackages = [
          pkgs.docker-language-server
        ];

        specs.docker = {
          data = [
            pkgs.vimPlugins.nvim-lspconfig
          ];
          config = ''vim.lsp.enable("docker_language_server")'';
        };
      };
    go =
      { pkgs, ... }:
      {
        extraPackages = [
          pkgs.gofumpt
          pkgs.golangci-lint-langserver
          pkgs.golines
          pkgs.gopls
          pkgs.gotools
        ];

        specs.go = {
          data = [
            pkgs.vimPlugins.nvim-lspconfig
          ];
          config =
            #lua
            ''
              vim.lsp.enable("golangci_lint_ls")
              vim.lsp.enable("gopls")
            '';
        };
      };
    helm =
      { pkgs, ... }:
      {
        extraPackages = [
          pkgs.helm-ls
        ];

        specs.helm = {
          data = [
            pkgs.vimPlugins.nvim-lspconfig
          ];
          config = ''vim.lsp.enable("helm_ls")'';
        };
      };
    json =
      { pkgs, ... }:
      {
        extraPackages = [
          pkgs.vscode-json-languageserver
        ];

        specs.json = {
          data = [
            pkgs.vimPlugins.nvim-lspconfig
          ];
          config = ''vim.lsp.enable("jsonls")'';
        };
      };
    jsonnet =
      { pkgs, ... }:
      {
        extraPackages = [
          pkgs.jsonnet-language-server
          pkgs.go-jsonnet
        ];

        specs.jsonnet = {
          data = [
            pkgs.vimPlugins.nvim-lspconfig
          ];
          config = ''vim.lsp.enable("jsonnet_ls")'';
        };
      };
    lua =
      { pkgs, ... }:
      {
        extraPackages = [
          pkgs.lua-language-server
          pkgs.stylua
        ];

        specs.lua = {
          data = [
            pkgs.vimPlugins.nvim-lspconfig
            pkgs.vimPlugins.blink-cmp
          ];
          config =
            #lua
            ''
              vim.lsp.enable("lua_ls")
              vim.lsp.enable("stylua")
            '';
        };
      };
    markdown =
      { pkgs, ... }:
      {
        extraPackages = [
          pkgs.markdownlint-cli2
          pkgs.marksman
        ];

        specs.markdown = {
          data = [
            pkgs.vimPlugins.nvim-lspconfig
          ];
          config = ''vim.lsp.enable("marksman")'';
        };
      };
    nix =
      { pkgs, ... }:
      {
        extraPackages = [
          pkgs.nil
          pkgs.nixfmt
        ];

        specs.nix = {
          data = [
            pkgs.vimPlugins.nvim-lspconfig
          ];
          config =
            #lua
            ''
              vim.lsp.config("nil_ls", {
                settings = {
                  ["nil"] = {
                    formatting = {
                      command = { "nixfmt" },
                    },
                  },
                },
              })
              vim.lsp.enable("nil_ls")
            '';
        };
      };
    opentofu =
      { pkgs, ... }:
      {
        extraPackages = [
          pkgs.tofu-ls
        ];

        specs.opentofu = {
          data = [
            pkgs.vimPlugins.nvim-lspconfig
          ];
          config = ''vim.lsp.enable("tofu_ls")'';
        };
      };
    ruby =
      { pkgs, ... }:
      {
        extraPackages = [
          pkgs.rubocop
          pkgs.rubyPackages.solargraph
        ];

        specs.ruby = {
          data = [
            pkgs.vimPlugins.nvim-lspconfig
          ];
          config =
            #lua
            ''
              vim.lsp.enable("rubocop")
              vim.lsp.enable("solargraph")
            '';
        };
      };
    yaml =
      { pkgs, ... }:
      {
        extraPackages = [
          pkgs.yaml-language-server
          pkgs.yamlfmt
          pkgs.yamllint
        ];

        specs.yaml = {
          data = [
            pkgs.vimPlugins.nvim-lspconfig
          ];
          config = ''vim.lsp.enable("yamlls")'';
        };
      };

    lsp = {
      imports = [
        self.modules.neovim.bash
        self.modules.neovim.docker
        self.modules.neovim.go
        self.modules.neovim.helm
        self.modules.neovim.json
        self.modules.neovim.jsonnet
        self.modules.neovim.lua
        self.modules.neovim.markdown
        self.modules.neovim.nix
        self.modules.neovim.opentofu
        self.modules.neovim.ruby
        self.modules.neovim.yaml
      ];
    };
  };
}
