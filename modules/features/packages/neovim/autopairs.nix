_: {
  config = {
    vim = {
      autopairs.nvim-autopairs = {
        enable = true;
      };

      lazy.plugins.nvim-autopairs.after = ''
        local npairs = require("nvim-autopairs")

        npairs.add_rules(require("nvim-autopairs.rules.endwise-lua"))
        npairs.add_rules(require("nvim-autopairs.rules.endwise-ruby"))
      '';
    };
  };
}
