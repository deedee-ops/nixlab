# shellcheck shell=bash

# Usage: niri-focus-column.sh left|right
DIRECTION=$1

FOCUSED=$(niri msg --json focused-window)
TILE_IDX=$(echo "$FOCUSED" | jq '.layout.pos_in_scrolling_layout[1]')
WORKSPACE_ID=$(echo "$FOCUSED" | jq '.workspace_id')
CUR_COL_IDX=$(echo "$FOCUSED" | jq '.layout.pos_in_scrolling_layout[0]')

# Single query — reused for both total columns and target column size
WORKSPACE_WINDOWS=$(niri msg --json windows | jq --argjson ws "$WORKSPACE_ID" \
  '[.[] | select(.workspace_id == $ws and .is_floating == false)]')

TOTAL_COLS=$(echo "$WORKSPACE_WINDOWS" | jq '[.[].layout.pos_in_scrolling_layout[0]] | max')

if [ "$DIRECTION" = "left" ]; then
    TARGET_COL=$(( CUR_COL_IDX == 1 ? TOTAL_COLS : CUR_COL_IDX - 1 ))
else
    TARGET_COL=$(( CUR_COL_IDX == TOTAL_COLS ? 1 : CUR_COL_IDX + 1 ))
fi

COLUMN_SIZE=$(echo "$WORKSPACE_WINDOWS" | jq --argjson col "$TARGET_COL" \
  '[.[] | select(.layout.pos_in_scrolling_layout[0] == $col)] | length')

TARGET_TILE=$(( TILE_IDX > COLUMN_SIZE ? COLUMN_SIZE : TILE_IDX ))

niri msg action focus-column "$TARGET_COL"
niri msg action focus-window-in-column "$TARGET_TILE"
