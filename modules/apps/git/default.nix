{
  config,
  lib,
  ...
}:
let
  cfg = config.myHomeApps.git;
in
{
  options.myHomeApps.git = {
    enable = lib.mkEnableOption "git" // {
      default = true;
    };
    appendOptions = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra custom options which will be merged with programs.git.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = lib.attrsets.recursiveUpdate {
      enable = true;
      aliases = {
        pf = "push --force-with-lease --force-if-includes";
        tags = "tag -l";
        branches = "branch -a";
        remotes = "remote -v";
        reb = "!r() { git rebase -i HEAD~$1; }; r";
        ci = "commit";
        cins = "commit --no-gpg-sign";
        co = "checkout";
        st = "status";
        br = "branch";
        sh = "show --stat --oneline";
        lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        ls = "log --show-signature";
        lf = "log --pretty=fuller";
        sign-rebase = "!GIT_SEQUENCE_EDITOR='sed -i -re s/^pick/e/' sh -c 'git rebase -i $1 && while test -f .git/rebase-merge/interactive; do git commit --amend -S --no-edit && git rebase --continue; done' -";
        wip = "!git add -A && git commit -m \"WIP\" -an --no-gpg-sign";
        amend = "commit --amend -a --no-edit";
      };

      delta = with config.lib.stylix.colors.withHashtag; {
        enable = true;
        options = {
          side-by-side = true;
          line-numbers = true;
          features = "catppuccin-mocha";
          catppuccin-mocha = {
            blame-palette = "${base00-hex} ${base01-hex} #${base00-hex} ${base02-hex} ${base03-hex}";
            commit-decoration-style = "box ul";
            dark = true;
            file-decoration-style = "${base05-hex}";
            file-style = "${base05-hex}";
            hunk-header-decoration-style = "box ul";
            hunk-header-file-style = "bold";
            hunk-header-line-number-style = "bold ${base07-hex}";
            hunk-header-style = "file line-number syntax";
            line-numbers = true;
            line-numbers-left-style = "${base04-hex}";
            line-numbers-minus-style = "bold ${base08-hex}";
            line-numbers-plus-style = "bold ${base0B-hex}";
            line-numbers-right-style = "${base04-hex}";
            line-numbers-zero-style = "${base04-hex}";
            minus-emph-style = "bold syntax ${base08-hex}";
            minus-style = "syntax ${base08-hex}";
            plus-emph-style = "bold syntax ${base0B-hex}";
            plus-style = "syntax ${base0B-hex}";
            syntax-theme = "catppuccin-mocha";
          };
        };
      };

      ignores = [
        "*.pyc"
        "*.sublime-workspace"
        "*.swo"
        "*.swp"
        "*~"
        ".DS_Store"
        ".Spotlight-V100"
        ".Trashes"
        "._*"
        ".idea"
        "Desktop.ini"
        "Thumbs.db"
        "gems.tags"
        "tags"
      ];

      extraConfig = {
        color = {
          ui = "auto";
          branch = {
            current = "yellow reverse";
            local = "yellow";
            remote = "green";
          };
          diff = {
            meta = "yellow bold";
            frag = "magenta bold";
            old = "red bold";
            new = "green bold";
          };
          status = {
            added = "yellow";
            changed = "green";
            untracked = "cyan";
          };
        };
        core = {
          editor = "vim";
        };
        init = {
          defaultBranch = "master";
        };
        pull = {
          rebase = true;
        };
        push = {
          default = "simple";
          followTags = true;
        };
        rerere = {
          enabled = true;
        };
        transfer = {
          fsckobjects = true;
        };
      };
    } cfg.appendOptions;
  };
}
