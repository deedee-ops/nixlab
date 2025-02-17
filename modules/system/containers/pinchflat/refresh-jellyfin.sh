#!/bin/bash

EVENT_TYPE=$1
# EVENT_DATA=$2

if [ "$EVENT_TYPE" = "media_downloaded" ]; then
  curl -X POST "${JELLYFIN_URL}/library/refresh?api_key=$(cat /secrets/JELLYFIN_API_KEY)"
fi
