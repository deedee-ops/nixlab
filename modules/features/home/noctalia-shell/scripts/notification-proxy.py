import dbus
import dbus.mainloop.glib
import dbus.lowlevel
from gi.repository import GLib
import sys

FORCE_CRITICAL_APPS = {"teams-for-linux", "telegram desktop", "org.telegram.desktop"}

pending = {}
our_ids = set()

def renotify(original_id, args, iface):
    try:
        iface.CloseNotification(dbus.UInt32(original_id))
        hints = dict(args[6])
        hints["urgency"] = dbus.Byte(2)
        new_id = int(iface.Notify(
            args[0], dbus.UInt32(0), args[2], args[3],
            args[4], args[5], hints, args[7]
        ))
        our_ids.add(new_id)
    except Exception:
        pass
    return False

def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

    send_bus = dbus.SessionBus()
    send_iface = dbus.Interface(
        send_bus.get_object("org.freedesktop.Notifications", "/org/freedesktop/Notifications"),
        "org.freedesktop.Notifications"
    )

    monitor_bus = dbus.SessionBus(private=True)

    def message_filter(conn, msg):
        t = msg.get_type()

        if t == 1:  # METHOD_CALL
            if (msg.get_interface() == "org.freedesktop.Notifications"
                    and msg.get_member() == "Notify"):
                args = msg.get_args_list()
                if str(args[0]).lower() in FORCE_CRITICAL_APPS:
                    hints = dict(args[6])
                    if int(hints.get("urgency", dbus.Byte(1))) < 2:
                        pending[msg.get_serial()] = args

        elif t == 2:  # METHOD_RETURN
            serial = msg.get_reply_serial()
            if serial in pending:
                args = pending.pop(serial)
                ret = msg.get_args_list()
                if ret:
                    notif_id = int(ret[0])
                    if notif_id not in our_ids:
                        captured_id, captured_args = notif_id, args
                        GLib.timeout_add(50, lambda: renotify(captured_id, captured_args, send_iface))

        return dbus.lowlevel.HANDLER_RESULT_HANDLED

    monitor_bus.add_message_filter(message_filter)

    try:
        dbus.Interface(
            monitor_bus.get_object("org.freedesktop.DBus", "/org/freedesktop/DBus"),
            "org.freedesktop.DBus.Monitoring"
        ).BecomeMonitor(
            dbus.Array([
                "type='method_call',interface='org.freedesktop.Notifications',member='Notify'",
                "type='method_return'",
            ], signature='s'),
            dbus.UInt32(0)
        )
    except dbus.exceptions.DBusException:
        try:
            monitor_bus.add_match_string(
                "eavesdrop='true',type='method_call',"
                "interface='org.freedesktop.Notifications',member='Notify'"
            )
            monitor_bus.add_match_string(
                "eavesdrop='true',type='method_return'"
            )
        except dbus.exceptions.DBusException as e:
            print(f"error: all monitoring methods failed: {e}", file=sys.stderr)
            sys.exit(1)

    GLib.MainLoop().run()

main()
