{ lib, ... }:
rec {
  sops = {
    defaultSopsFile = ./secrets.sops.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      "credentials/system/ajgon" = { };
    };
  };

  networking = {
    hostName = "mandark";
    firewall.enable = true;
    nameservers = lib.mkForce [
      "9.9.9.9"
      "149.112.112.112"
    ];
  };

  mySystem = {
    purpose = "External gateway";
    filesystem = "ext4";
    primaryUser = "ajgon";
    primaryUserPasswordSopsSecret = "credentials/system/ajgon";
    rootDomain = "rzegocki.dev";
    notificationEmail = "mandark@${mySystem.rootDomain}";

    networking.enable = false;

    ssh = {
      enable = true;
      authorizedKeys = {
        "${mySystem.primaryUser}" = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrBLT88ZZ+lO8hHcj+4jqtor79OLhQZcDWF98kkWkfn personal"
        ];
      };
    };
  };

  mySystemApps = {
    ddclient = {
      enable = true;
      subdomains = [
        "headscale"
        "relay"
      ];
    };

    headscale = {
      enable = true;
      backup = false;
      nameservers = [
        "192.168.42.1"
      ];
    };

    letsencrypt = {
      enable = true;
      useProduction = true;
      domains = [
        mySystem.rootDomain
        "*.${mySystem.rootDomain}"
      ];
    };

    nginx = {
      inherit (mySystem) rootDomain;

      enable = true;
    };

    rustdesk = {
      enable = true;
      backup = false;
      relayHost = "relay.${mySystem.rootDomain}";
    };
  };

  myHomeApps = {
    gnupg.enable = false;
    ssh.enable = false;
    wakatime.enable = false;
    zellij.enable = true;

    zsh.promptColor = "yellow";
  };

  system.stateVersion = "25.11";
}
