_: {
  config = {
    vim.comments.comment-nvim = {
      enable = true;
      setupOpts = {
        mappings = {
          basic = false;
          extra = false;
          toggleCurrentLine = "<Leader>/";
          toggleSelectedLine = "<Leader>/";
        };
      };
    };
  };
}
