# shellcheck shell=bash

## Author : Aditya Shakya (adi1090x)
## Github : @adi1090x
#
## Rofi   : Power Menu
#

ROFI_CMD="${rofi_cmd:-rofi}"
CONVERT_CMD="${convert_cmd:-convert}"
SCROT_CMD="${scrot_cmd:-scrot}"
SED_CMD="${sed_cmd:-sed}"
UPTIME_CMD="${uptime_cmd:-uptime}"

# CMDs
uptime="$("${UPTIME_CMD}" | "${SED_CMD}" -E 's/.*up *(.*), *[0-9]+ *user.*/\1/')"

# Options
shutdown=''
reboot=''
lock=''
suspend=''
logout=''
yes=''
no=''

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:=${HOME}/.config}"

rm -rf /tmp/powermenu.jpg
${SCROT_CMD} -M 0 /tmp/powermenu.jpg
${CONVERT_CMD} -scale 10% -blur 0x2.5 -modulate 50 -resize 1000% /tmp/powermenu.jpg /tmp/powermenu.jpg

# Rofi CMD
rofi_run() {
	${ROFI_CMD} -dmenu \
    -m 1 \
		-p "Goodbye ${USER}" \
		-mesg "Uptime: $uptime" \
		-theme "${XDG_CONFIG_HOME}/rofi/powermenu/config.rasi"
}

# Confirmation CMD
confirm_cmd() {
	${ROFI_CMD} -dmenu \
    -m 1 \
		-p 'Confirmation' \
		-mesg 'Are you Sure?' \
		-theme "${XDG_CONFIG_HOME}/rofi/powermenu/confirm.rasi"
}

# Ask for confirmation
confirm_exit() {
	echo -e "$yes\n$no" | confirm_cmd
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_run
}

# Execute Command
run_cmd() {
	selected="$(confirm_exit)"
	if [[ "$selected" == "$yes" ]]; then
		if [[ $1 == '--shutdown' ]]; then
			systemctl poweroff
		elif [[ $1 == '--reboot' ]]; then
			systemctl reboot
		elif [[ $1 == '--suspend' ]]; then
			systemctl suspend
		elif [[ $1 == '--logout' ]]; then
			if [[ "$DESKTOP_SESSION" == *'openbox' ]]; then
				openbox --exit
			elif [[ "$DESKTOP_SESSION" == *'bspwm' ]]; then
				bspc quit
			elif [[ "$DESKTOP_SESSION" == *'i3' ]]; then
				i3-msg exit
			elif [[ "$DESKTOP_SESSION" == *'plasma' ]]; then
				qdbus org.kde.ksmserver /KSMServer logout 0 0 0
			elif [[ "$DESKTOP_SESSION" == *'awesome' ]]; then
        echo -E "awesome.quit()" | awesome-client
			fi
		fi
	else
		exit 0
	fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
    "$shutdown")
		run_cmd --shutdown
        ;;
    "$reboot")
		run_cmd --reboot
        ;;
    "$lock")
		if which betterlockscreen; then
			betterlockscreen --lock dimpixel --off 30
		elif which i3lock; then
			i3lock
		fi
        ;;
    "$suspend")
		run_cmd --suspend
        ;;
    "$logout")
		run_cmd --logout
        ;;
esac
