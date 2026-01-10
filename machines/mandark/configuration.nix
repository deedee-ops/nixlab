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
    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
    };
    nameservers = lib.mkForce [
      "9.9.9.9"
      "149.112.112.112"
    ];
    extraHosts = ''
      192.168.42.10 s3.ajgon.casa nix.ajgon.casa
      192.168.42.30 id.ajgon.casa
    '';
  };

  mySystem = {
    purpose = "External gateway";
    filesystem = "ext4";
    primaryUser = "ajgon";
    primaryUserPasswordSopsSecret = "credentials/system/ajgon";
    rootDomain = "rzegocki.dev";
    notificationEmail = "mandark@${mySystem.rootDomain}";
    trustedRootCertificates = [
      (builtins.readFile ../../assets/ca-ec384.crt)
      (builtins.readFile ../../assets/ca-rsa4096.crt)
    ];

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
    headscale = {
      enable = true;
      backup = false;
      enableApiKeyLogin = true;
      oidc = {
        enable = true;
        clientId = "8b45ae3e-0b3b-4b9c-a55b-90c89b1a25a4";
        issuer = "id.ajgon.casa";
      };
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

  mySystemApps = {
    tailscale = {
      enable = true;
      backup = false;
      autoProvision = true; # see option description in tailscale.nix
      customServer = "headscale.rzegocki.dev";
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
