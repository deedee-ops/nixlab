# shellcheck shell=bash

INOTIFYWAIT_CMD="${inotifywait_cmd:-inotifywait}"
NOTIFYSEND_CMD="${notifysend_cmd:-"notify-send"}"
RCLONE_CMD="${rclone_cmd:-rclone}"
SCP_CMD="${scp_cmd:-scp}"
SSH_CMD="${ssh_cmd:-ssh}"
SWAKS_CMD="${swaks_cmd:-swaks}"

GDRIVE_ENABLE="${GDRIVE_ENABLE:-false}"
MAIL_ENABLE="${MAIL_ENABLE:-false}"
PAPERLESS_ENABLE="${PAPERLESS_ENABLE:-false}"
SSH_ENABLE="${SSH_ENABLE:-false}"

function handle_gdrive() {
  if [ "$GDRIVE_ENABLE" != "true" ]; then
    return
  fi
  if $RCLONE_CMD copy "$1" "gdrive:${GDRIVE_DIR}"; then
    return
  fi

  $NOTIFYSEND_CMD -u critical "Sending \"$(basename "$1")\" to GDrive/${GDRIVE_DIR} failed. Forgot to run 'rclone config'?"
}

function handle_mail() {
  if [ "$MAIL_ENABLE" != "true" ]; then
    return
  fi
  if $SWAKS_CMD --config "${MAIL_SWAKS_CFG_PATH}" --to "${MAIL_TO}" --from "${MAIL_FROM}" --header "Subject: ${MAIL_SUBJECT}" --body "${MAIL_BODY}" --attach "@${pathfile}"; then
    return
  fi

  $NOTIFYSEND_CMD -u critical "Sending \"$(basename "$1")\" to mail ${MAIL_TO} failed."
}

function handle_paperless() {
  if [ "$PAPERLESS_ENABLE" != "true" ]; then
    return
  fi
  cp "$1" "${PAPERLESS_CONSUME_DIR}/"
}

function handle_ssh() {
  if [ "$SSH_ENABLE" != "true" ]; then
    return
  fi
  PARSED_DIR="$(date +"$SSH_TARGET")"
  $SSH_CMD "$SSH_HOST" -C mkdir -p "$PARSED_DIR"
  $SCP_CMD -O "$1" "$SSH_HOST:$PARSED_DIR/"
}

mkdir -p "${WATCH_DIR}"

$INOTIFYWAIT_CMD  --format="%e %f" -m "${WATCH_DIR}" |
while read -r event file; do
  if [ "$event" != "CREATE" ] && [ "$event" != "MOVED_TO" ]; then
    continue
  fi

  pathfile="${WATCH_DIR}/${file}"

  handle_gdrive "$pathfile"
  handle_mail "$pathfile"
  handle_paperless "$pathfile"
  handle_ssh "$pathfile"
  rm -rf "$pathfile"
done
