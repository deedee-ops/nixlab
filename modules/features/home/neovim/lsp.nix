{ self, ... }:
{
  flake.modules.neovim = {
    bash =
      { pkgs, ... }:
      {
        runtimePkgs = [
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
        runtimePkgs = [
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
        runtimePkgs = [
          pkgs.go
          pkgs.gofumpt
          pkgs.golangci-lint
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
        runtimePkgs = [
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
        runtimePkgs = [
          pkgs.prettierd
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
        runtimePkgs = [
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
        runtimePkgs = [
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
        runtimePkgs = [
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
        runtimePkgs = [
          pkgs.deadnix
          pkgs.nil
          pkgs.nixfmt
          pkgs.statix
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
        runtimePkgs = [
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
        runtimePkgs = [
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
        runtimePkgs = [
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
