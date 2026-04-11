_: {
  config = {
    vim.statusline.lualine = {
      enable = true;
      extraActiveSection.a = [
        ''
          {
            "hostname",
            icons_enabled = true,
            separator = { left = '', right = '' }
          }
        ''
      ];
    };
  };
}
