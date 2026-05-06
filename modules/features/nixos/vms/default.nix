_: {
  flake.nixosModules.features-nixos-vms =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.features.nixos.vms;
    in
    {
      options.features.nixos.vms = {
        username = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          description = "User to be added to vms groups";
        };
        dataFS = lib.mkOption {
          type = lib.types.attrs;
          description = "'fileSystems' matching definition of VMs storage device";
        };
      };

      config = {
        boot.kernelModules = [ "kvm-intel" ];

        virtualisation = {
          libvirtd.enable = true;
          spiceUSBRedirection.enable = true;
        };

        fileSystems."/srv/vms/data" = cfg.dataFS;

        programs.virt-manager.enable = true;

        users.users."${cfg.username}".extraGroups = [
          "libvirtd"
          "kvm"
          "disk"
        ];

        services.samba = {
          enable = true;
          settings = {
            global = {
              workgroup = "WORKGROUP";
              security = "user";
              "map to guest" = "bad user";
              "guest account" = "nobody";
              "hosts allow" = "192.168.122. 127.";
              "hosts deny" = "0.0.0.0/0";
            };
            vmshare = {
              path = "/srv/vms/share";
              "read only" = "no";
              "guest ok" = "yes";
              "force user" = "nobody";
              comment = "VM Shared Folder";
            };
          };
          openFirewall = false;
        };

        networking.firewall.trustedInterfaces = [ "virbr0" ];

        environment = {
          systemPackages = [ pkgs.virt-manager ];
          sessionVariables = {
            LIBVIRT_DEFAULT_URI = "qemu:///system";
          };
        };

        system.activationScripts = {
          prepare-vms.text = ''
            mkdir -p /srv/vms/share /srv/vms/isos
            chmod -R 777 /srv/vms
            if ! ${lib.getExe' pkgs.libvirt "virsh"} net-list --all | grep -q default; then
              cat ${./vm-network.xml} | ${lib.getExe' pkgs.libvirt "virsh"} net-define /dev/stdin
              ${lib.getExe' pkgs.libvirt "virsh"} net-autostart default
              ${lib.getExe' pkgs.libvirt "virsh"} net-start default
            fi
            if ! ${lib.getExe' pkgs.libvirt "virsh"} list --all | grep -q windows10; then
              ${lib.getExe' pkgs.libvirt "virsh"} define ${./windows10.xml}
            fi
            if [ ! -f /srv/vms/data/windows10.qcow2 ]; then
              ${lib.getExe' pkgs.qemu "qemu-img"} create -f qcow2 /srv/vms/data/windows10.qcow2 200G
            fi
          '';
        };
      };
    };
}
