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
      192.168.42.10 s3.ajgon.casa
      192.168.42.30 id.ajgon.casa
      192.168.42.10 pocket-id.security.svc.cluster.local
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
      ''
        -----BEGIN CERTIFICATE-----
        MIIClDCCAhqgAwIBAgIUOfIRdHEUj5dZX1nj+QCHnTSx/pMwCgYIKoZIzj0EAwIw
        eTELMAkGA1UEBhMCUEwxFDASBgNVBAgMC21hbG9wb2xza2llMQ8wDQYDVQQHDAZL
        cmFrb3cxEDAOBgNVBAoMB2hvbWVsYWIxEDAOBgNVBAMMB1Jvb3QgQ0ExHzAdBgkq
        hkiG9w0BCQEWEGlnb3JAcnplZ29ja2kucGwwHhcNMjUxMTE3MjAyNDMxWhcNMzUx
        MTE1MjAyNDMxWjB5MQswCQYDVQQGEwJQTDEUMBIGA1UECAwLbWFsb3BvbHNraWUx
        DzANBgNVBAcMBktyYWtvdzEQMA4GA1UECgwHaG9tZWxhYjEQMA4GA1UEAwwHUm9v
        dCBDQTEfMB0GCSqGSIb3DQEJARYQaWdvckByemVnb2NraS5wbDB2MBAGByqGSM49
        AgEGBSuBBAAiA2IABP8xPh+ljvtqRZqdCegByaeqYe3gAc6kNxo3vEtp+dcwwZz6
        w+liyGQUfDlResruYE2YZZfWVMjZv+GG1afM3jOFIhPYPBZo2bbBshBcXflfASQ8
        d4EJSNMqUwC8OxuzsKNjMGEwHQYDVR0OBBYEFO+sxaxJd7J/Dohxd0y/Z6lWYE43
        MB8GA1UdIwQYMBaAFO+sxaxJd7J/Dohxd0y/Z6lWYE43MA8GA1UdEwEB/wQFMAMB
        Af8wDgYDVR0PAQH/BAQDAgEGMAoGCCqGSM49BAMCA2gAMGUCMQCetLE7ep2PmTix
        WsTVZdp4hOxK0ewV+fHBQcV6Ra9rdPW/AAp4kNML1AdKjG+Kh3sCMGW7Oy8yuX4J
        UiFH8cVR77uVAAP0OfMsKezfDUSIadbDZCJfzkkKwDYrZMQFw1BjqA==
        -----END CERTIFICATE-----
      ''
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
