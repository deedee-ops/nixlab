# Windows 10 VM

## Prerequisites

Place your Windows 10 ISO (with VirtIO drivers merged) at `/srv/iso/en-us_windows_10_iot_enterprise_ltsc_2021_x64_dvd_257ad90f_virtio.iso`.

## Installing Windows

Start the VM and open the display:

```bash
virsh start windows10
virt-manager
```

In virt-manager, double-click `windows10` to open the console. Proceed through the
Windows installer normally. The disk will be detected automatically (VirtIO drivers
are already in the image).

Once installation is complete, shut down the VM and detach the ISO so it doesn't
boot from it again:

```bash
virsh change-media windows10 sda --eject --config
```

## Connecting the shared folder

### Required: enable guest SMB access on Windows

Windows 10 (1709 and later) blocks insecure guest SMB access by default. **Without
this step the share will not connect** — you will get "Windows cannot access
\\192.168.122.1\vmshare" even though networking is working correctly.

Run the following in an **Administrator** Command Prompt inside the VM:

```cmd
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v AllowInsecureGuestAuth /t REG_DWORD /d 1 /f
```

Reboot the VM (or restart the Workstation service) for the change to take effect.

### Map the network drive

The host machine is always reachable from the VM at `192.168.122.1`.

In Windows Explorer, map a network drive to:

```
\\192.168.122.1\vmshare
```

Tick **Reconnect at sign-in** to make it permanent.

Anything dropped into `/srv/vms/share` on the host appears in that drive instantly,
and vice versa.

## Snapshots

Always shut down the VM before taking a snapshot to ensure consistency.

**Create a snapshot:**

```bash
virsh snapshot-create-as windows10 "snapshot-name" "Optional description"
```

**List snapshots:**

```bash
virsh snapshot-list windows10
```

**Revert to a snapshot:**

```bash
virsh snapshot-revert windows10 "snapshot-name"
```

**Delete a snapshot:**

```bash
virsh snapshot-delete windows10 "snapshot-name"
```

## Daily usage

**Start the VM:**

```bash
virsh start windows10
virt-manager
```

**Shut down the VM** — do it from inside Windows (Start → Shut down) for a clean
shutdown. Alternatively, from the host:

```bash
virsh shutdown windows10   # graceful ACPI shutdown
```

**Force-off if hung:**

```bash
virsh destroy windows10
```

## USB pendrive passthrough

1. Plug the pendrive into the host.
2. In virt-manager, with the VM console open, go to **Virtual Machine → Redirect USB Device**.
3. Tick the pendrive in the list and click **OK** — it disconnects from the host and
   appears in Windows.
4. To return it to the host, safely eject it inside Windows first, then uncheck it
  in the same menu (or simply unplug it).

Up to 4 USB devices can be redirected simultaneously.
