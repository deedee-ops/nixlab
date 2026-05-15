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

        home-manager.users."${cfg.username}".features.home = {
          freerdp.windowsHosts.w10vm = {
            inherit (cfg) username;

            displayName = "Windows 10 VM";
            host = "192.168.122.100";
            preRunScript = lib.getExe (
              pkgs.writeShellScriptBin "ensure-windows10-vm.sh" ''
                VM_NAME="windows10"
                VM_IP="192.168.122.100"
                RDP_PORT=3389
                CHECK_INTERVAL=5
                MAX_WAIT=120

                die() {
                    ${lib.getExe' pkgs.libnotify "notify-send"} -u critical -a "VM Launcher" "Windows 10 Error" "$1"
                    exit 1
                }

                rdp_up() {
                    timeout 2 bash -c "</dev/tcp/$VM_IP/$RDP_PORT" 2>/dev/null
                }

                if ! ${lib.getExe' pkgs.libvirt "virsh"} domstate "$VM_NAME" 2>/dev/null | grep -q "^running$"; then
                    ${lib.getExe' pkgs.libvirt "virsh"} start "$VM_NAME" 2>&1 || die "Failed to start VM '$VM_NAME'."
                    ${lib.getExe' pkgs.libnotify "notify-send"} -a "VM Launcher" "Windows 10 Booting" "VM will be available at $VM_IP:$RDP_PORT"
                fi

                elapsed=0
                until rdp_up; do
                    if [ "$elapsed" -ge "$MAX_WAIT" ]; then
                        die "Timed out after ""$MAX_WAIT""s waiting for RDP on $VM_IP:$RDP_PORT."
                    fi
                    sleep "$CHECK_INTERVAL"
                    elapsed=$(( elapsed + CHECK_INTERVAL ))
                done
              ''
            );
          };
        };

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
