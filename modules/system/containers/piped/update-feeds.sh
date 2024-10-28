# shellcheck shell=bash

mode=$1
backend=$2
PGPASSWORD="$(cat "$3")"

if [[ ! $mode =~ videos|streams ]]; then
    echo "Unrecognized operation mode $mode" >&2
    exit 1
fi

if [ -z "$backend" ]; then
    echo "Backend URL is missing" >&2
    exit 1
fi

if [ -z "$PGPASSWORD" ]; then
    echo "Postgres password file configured incorrectly" >&2
    exit 1
fi

if ! subscriptions=$(PGPASSWORD="$(cat "$3")" psql -h 127.0.0.1 -U piped -d piped -qtAX -c 'select id from public.pubsub;')
then
    echo "Failed to get subscriptions from DB" >&2
    exit 3
fi

i=1
failures=0
total_subs=$(wc -l <<<"$subscriptions")

while IFS= read -r channel; do

    printf '[+] %4d/%d %s %s\n' $i "$total_subs" "$mode" "$channel"

    if ! (
        set -e

        if [ "$mode" = videos ]; then
            url="$backend/channel/$channel"
        else
            url=$(jq -nr --arg channel "$channel" --arg backend "$backend" '
            {
                originalUrl: "https://www.youtube.com/\($channel)/streams",
                url: "https://www.youtube.com/\($channel)/streams",
                id: $channel,
                contentFilters: ["livestreams"],
                sortFilter: "",
                baseUrl: "https://www.youtube.com"
            }
            | tojson | @uri | $backend + "/channels/tabs?data=" + .')
        fi

        curl -sSk "$url" >/dev/null
    )
    then
        ((failures++))
    fi

    if [ $i -ne "$total_subs" ]; then
        sleep 0.5
        ((i++))
    fi

done <<<"$subscriptions"

if [ $failures -ne 0 ]; then
    echo "[!] Failed $failures time(s)" >&2
    exit 4
fi
