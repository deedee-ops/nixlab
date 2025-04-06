{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myHomeApps.scripts.backupverify;
in
{
  options.myHomeApps.scripts.backupverify = {
    enable = lib.mkEnableOption "Verify homelab restic backups";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "backupverify" ''
        PATH="${
          lib.makeBinPath [
            pkgs.coreutils-full
            pkgs.curl
            pkgs.gnugrep
            pkgs.gnused
            pkgs.jq
            pkgs.restic
            pkgs.sops
          ]
        }:$PATH"
        machine="$1"
        region="$2"

        function usage() {
          echo "Usage: $0 <machine> <region>";
          exit 1
        }

        function verify() {
          if [[ $res == 10 ]]; then
            printf "\e[33mWARNING: Repository %s does not exist\e[0m\n" "$repo"
          elif [[ $res == 11 ]]; then
            printf "\e[31mERROR: Repository %s is locked\e[0m\n" "$repo"
            exit 11
          elif [[ $res == 12 ]]; then
            printf "\e[31mERROR: Incorrect password for repository %s\e[0m\n" "$repo"
            exit 12
          elif [[ $res == 1 ]]; then
            printf "\e[31mERROR: Verification/restore error of repository %s\e[0m\n" "$repo"
            exit 1
          fi
        }

        if [ "$machine" = "deedee" ]; then
          if [ "$region" = "eu" ]; then
            BASE_RESTIC_REPO="rest:https://pyif3th7.repo.borgbase.com/"
          elif [ "$region" = "us" ]; then
            BASE_RESTIC_REPO="rest:https://p51to40o.repo.borgbase.com/"
          elif [ "$region" = "local" ]; then
            BASE_RESTIC_REPO="/mnt/local/deedee/"
          else
            usage
          fi
        elif [ "$machine" = "meemee" ]; then
          if [ "$region" = "eu" ]; then
            BASE_RESTIC_REPO="rest:https://x49pyrz3.repo.borgbase.com/"
          elif [ "$region" = "us" ]; then
            BASE_RESTIC_REPO="rest:https://rr742mx3.repo.borgbase.com/"
          elif [ "$region" = "local" ]; then
            BASE_RESTIC_REPO="/mnt/local/meemee/"
          else
            usage
          fi
        else
          usage
        fi

        export SOPS_AGE_KEY_FILE="/persist/etc/age/keys.txt"

        restic_extra_opts=""

        if [ "$region" = "eu" ] || [ "$region" = "us" ]; then
          export RESTIC_PASSWORD="$(sops --input-type yaml --output-type json -d <(curl -Ls "https://raw.githubusercontent.com/deedee-ops/nixlab/refs/heads/master/machines/$machine/secrets.sops.yaml") | jq -r ".backups.restic.\"repo-borgbase-$region\".password")"
          eval "$(sops --input-type yaml --output-type json -d <(curl -Ls "https://raw.githubusercontent.com/deedee-ops/nixlab/refs/heads/master/machines/$machine/secrets.sops.yaml") | jq -r ".backups.restic.\"repo-borgbase-$region\".env")"
          export RESTIC_REST_USERNAME
          export RESTIC_REST_PASSWORD
        fi

        if [ "$region" = "local" ]; then
          export RESTIC_PASSWORD="$(sops --input-type yaml --output-type json -d <(curl -Ls "https://raw.githubusercontent.com/deedee-ops/nixlab/refs/heads/master/machines/$machine/secrets.sops.yaml") | jq -r ".backups.restic.local.password")"
          restic_extra_opts="--no-lock"
        fi

        repos="$(jq -r --argjson repos "$(nix eval --json "github:deedee-ops/nixlab#nixosConfigurations.$machine.config.services.restic.backups" --apply builtins.attrNames)" -n '$repos | join("\n")' | grep remote | sed 's@-remote.*@@g' | sort | uniq)"

        for repo in $repos; do
          export RESTIC_REPOSITORY="$BASE_RESTIC_REPO$repo"

          if [ "$region" = "eu" ] || [ "$region" = "us" ]; then
            restic $restic_extra_opts unlock --remove-all
          fi

          printf "\n\e[36mVeryfying %s\e[0m\n" "$repo"
          last_snapshot_date="$(restic $restic_extra_opts snapshots --latest 1 --json | jq -r '.[0].time' | sed 's@T.*@@g')"
          if [ "$last_snapshot_date" != "$(date +%F)" ]; then
            printf "\e[31mERROR: Repository %s is missing snapshots! Last snapshot date: %s\e[0m\n" "$repo" "$last_snapshot_date"
            exit 1
          fi

          restic $restic_extra_opts check
          res=$?
          verify

          [ -d "$repo" ] && continue

          printf "\n\e[35mRestoring %s\e[0m\n" "$repo"
          restic $restic_extra_opts restore latest --target "$repo"
        done
      '')
    ];
  };
}
