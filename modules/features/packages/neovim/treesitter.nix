{ pkgs, ... }:
{
  config = {
    vim = {
      treesitter = {
        enable = true;
        highlight.enable = true;
        indent.enable = true;

        grammars = with pkgs.vimPlugins.nvim-treesitter.grammarPlugins; [
          regex
          vim
        ];
      };

      languages = {
        bash.treesitter.enable = true;
        lua.treesitter.enable = true;
        markdown.treesitter.enable = true;
      };
    };
  };
}
