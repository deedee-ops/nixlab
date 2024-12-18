# shellcheck shell=bash
#
# taken from: https://github.com/UnkwUsr/ticktask
#
ACCESS_TOKEN_FILE="${access_token_file:-"$XDG_DATA_HOME/ticktask/token"}"
FOLDER_ERROR_TASKS="$XDG_DATA_HOME/ticktask/error_tasks/"

CURL_CMD="${curl_cmd:-curl}"
DATE_CMD="${date_cmd:-date}"
SED_CMD="${sed_cmd:-sed}"
XDG_OPEN_CMD="${xdg_open_cmd:-"xdg-open"}"

if [ -z "$1" ]; then
    echo "Usage: $0 your task title"

    exit 1
fi

# escape \ and " symbols
task_title=$(echo "$@" | $SED_CMD 's/\\/\\\\/g; s/"/\\"/g')

if [ -f "$ACCESS_TOKEN_FILE" ]; then
    access_token=$(<"$ACCESS_TOKEN_FILE")
else
    # authorization
    echo "No access_token cached. Receiving new one"

    REDIRECT_URL="http://127.0.0.1"

    # docs says "comma separated", but comma not work. So we use space there
    SCOPE="tasks:write%20tasks:read"

    auth_url="https://ticktick.com/oauth/authorize?scope=$SCOPE&client_id=$CLIENT_ID&state=state&redirect_uri=$REDIRECT_URL&response_type=code"

    echo "Opening browser"
    user_auth_url=$($CURL_CMD -ILsS -w "%{url_effective}\n" "$auth_url" | tail -n1)
    $XDG_OPEN_CMD "$user_auth_url" 2> /dev/null

    read -erp "Paste the code from url you've been redirected: " code
    echo "Code: $code"

    payload_get_acces_token="grant_type=authorization_code&code=$code&redirect_uri=$REDIRECT_URL"
    resp_get_access_token=$($CURL_CMD -s --header "Content-Type: application/x-www-form-urlencoded" \
        -u "$CLIENT_ID:$CLIENT_SECRET" \
        --request POST \
        --data "$payload_get_acces_token" \
        https://ticktick.com/oauth/token)

    if [[ $resp_get_access_token =~ (access_token\":\")([^\"]*) ]]; then
        access_token=${BASH_REMATCH[2]}
        echo "access_token received. You can find it in $ACCESS_TOKEN_FILE"

        mkdir -p "$(dirname "$ACCESS_TOKEN_FILE")"
        echo -n "$access_token" > "$ACCESS_TOKEN_FILE"
    else
        echo "Bad response for getting access_token: $resp_get_access_token"

        exit 2
    fi
fi

# getting task description
if [ "$(declare -F cmd_get_description)" ]; then
    # escape \ and " and newline symbols
    desc=$(cmd_get_description | $SED_CMD 's/\\/\\\\/g; s/"/\\"/g' \
        | awk '{printf "%s\\n", $0}')
    field_content=', "content": "'$desc'"'
fi

# parse date
if [[ $task_title =~ (^| )\*(today|tomorrow)( |$).* ]]; then
    title_date=${BASH_REMATCH[2]}
    # date must be 1 day ago than real
    title_date=$($DATE_CMD --date="$title_date 1 day ago" -Iseconds)
    field_duedate=', "dueDate": "'$title_date'"'

    # remove date entries from title text
    task_title="$(echo "$task_title" | $SED_CMD -E 's/(^| )\*today( |$)/ /g; s/(^| )\*tomorrow( |$)/ /g; s/(^ | $)//g')"
fi
# parse tags
if [[ $task_title =~ (^| )#([a-zA-Z0-9_]+)( |$) ]]; then
    tags=$(echo "$task_title" | grep -Eo "(^| )#\w+" | tr -d "\n")

    # HACK. desc is not actual description (for real description use field
    # 'content'). This field is not even displayed (at least in web version),
    # but ticktick parses tags from this field
    field_desc=', "desc": "'$tags'"'

    # remove tags from title text
    task_title="$(echo "$task_title" | $SED_CMD -E 's/(^| )(#\w+( |$))+/ /g; s/(^ | $)//g')"
fi

json_task='{ "title": "'$task_title'"'$field_content$field_duedate$field_desc' }'

# finally send request to create task
resp_create_task=$($CURL_CMD -s \
    --fail-with-body \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $access_token" \
    --request POST \
    --data "$json_task" \
    https://api.ticktick.com/open/v1/task)

# shellcheck disable=SC2181
if (( $? != 0 )); then
    echo "Error on creating task. Server response:"
    echo "$resp_create_task"

    mkdir -p "$FOLDER_ERROR_TASKS"
    error_task_file=$($DATE_CMD +%s)
    echo "$@" > "$FOLDER_ERROR_TASKS/$error_task_file"
    echo "Task saved to $FOLDER_ERROR_TASKS"

    exit 2
fi
