_: {
  flake.homeModules.features-home-git =
    { config, ... }:
    {
      config = {
        programs = {
          git = {
            enable = true;
            lfs.enable = true;
            signing = {
              format = null;
              key = "igor@rzegocki.pl";
              signByDefault = true;
            };

            settings = {
              alias = {
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
                sign-rebase = "!GIT_SEQUENCE_EDITOR='sed -i -re s/^pick/e/' sh -c 'git rebase -i HEAD~$1 && while test -f .git/rebase-merge/interactive; do git commit --amend -S --no-edit -n && git rebase --continue; done' -";
                wip = "!git add -A && git commit -m \"WIP\" -an --no-gpg-sign";
                amend = "commit --amend -a --no-edit";
              };
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
              user = {
                name = "Igor Rzegocki";
                email = "igor@rzegocki.pl";
              };
              transfer = {
                fsckobjects = true;
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
          };

          delta = with config.lib.stylix.colors.withHashtag; {
            enable = true;
            enableGitIntegration = true;
            options = {
              side-by-side = true;
              line-numbers = true;
              features = "catppuccin-mocha";
              catppuccin-mocha = {
                blame-palette = "${base00-hex} ${base01-hex} ${base00-hex} ${base02-hex} ${base03-hex}";
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
                minus-emph-style = "bold syntax #53394c";
                minus-style = "syntax #35293b";
                plus-emph-style = "bold syntax #40504b";
                plus-style = "syntax #2c333a";
                syntax-theme = "base16-stylix";
              };
            };
          };

          lazygit = {
            enable = true;
          };
          zsh = {
            plugins = [
              {
                name = "git";
                src = ./zsh;
              }
            ];
          };
        };

        stylix.targets.lazygit.enable = true;
      };
    };
}
