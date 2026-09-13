#!/bin/bash

set -u

CONFIG="/etc/default/nginx-report"
STATE="/var/lib/nginx-report.state"
LOCK="/run/nginx-report.lock"

if [[ ! -f "$CONFIG" ]]; then
    echo "Config $CONFIG does not exist" >&2
    exit 1
fi

source "$CONFIG"

exec 9>"$LOCK"

if ! flock -n 9; then
    logger -t nginx-report "Another instance is already running"
    exit 0
fi


if [[ "${1:-}" == "--init" ]]; then
    ACCESS_LINES=$(wc -l < "$ACCESS_LOG")
    ERROR_LINES=$(wc -l < "$ERROR_LOG")
    LAST_RUN=$(date +%s)

    cat > "$STATE" <<EOF
LAST_RUN=$LAST_RUN
ACCESS_LINES=$ACCESS_LINES
ERROR_LINES=$ERROR_LINES
EOF

    logger -t nginx-report "State initialized"
    exit 0
fi


if [[ ! -f "$STATE" ]]; then
    echo "State file does not exist. Run $0 --init first." >&2
    exit 1
fi

source "$STATE"

CURRENT_TIME=$(date +%s)
CURRENT_ACCESS_LINES=$(wc -l < "$ACCESS_LOG")
CURRENT_ERROR_LINES=$(wc -l < "$ERROR_LOG")

if (( CURRENT_ACCESS_LINES < ACCESS_LINES )); then
    ACCESS_LINES=0
fi

if (( CURRENT_ERROR_LINES < ERROR_LINES )); then
    ERROR_LINES=0
fi

TMP_ACCESS=$(mktemp)
TMP_ERROR=$(mktemp)
REPORT=$(mktemp)

trap 'rm -f "$TMP_ACCESS" "$TMP_ERROR" "$REPORT"' EXIT

sed -n "$((ACCESS_LINES + 1)),${CURRENT_ACCESS_LINES}p" \
    "$ACCESS_LOG" > "$TMP_ACCESS"

sed -n "$((ERROR_LINES + 1)),${CURRENT_ERROR_LINES}p" \
    "$ERROR_LOG" > "$TMP_ERROR"

FROM=$(date -d "@$LAST_RUN" '+%Y-%m-%d %H:%M:%S %Z')
TO=$(date -d "@$CURRENT_TIME" '+%Y-%m-%d %H:%M:%S %Z')


{
    echo "Nginx hourly report"
    echo
    echo "Time range:"
    echo "$FROM - $TO"
    echo

    echo "========================================"
    echo "TOP IP ADDRESSES"
    echo "========================================"

    if [[ -s "$TMP_ACCESS" ]]; then
        awk '{print $1}' "$TMP_ACCESS" \
            | sort \
            | uniq -c \
            | sort -nr \
            | head -n "$TOP_N"
    else
        echo "No requests"
    fi

    echo
    echo "========================================"
    echo "TOP REQUESTED URLs"
    echo "========================================"

    if [[ -s "$TMP_ACCESS" ]]; then
        awk '{print $7}' "$TMP_ACCESS" \
            | sort \
            | uniq -c \
            | sort -nr \
            | head -n "$TOP_N"
    else
        echo "No requests"
    fi

    echo
    echo "========================================"
    echo "HTTP STATUS CODES"
    echo "========================================"

    if [[ -s "$TMP_ACCESS" ]]; then
        awk '{print $9}' "$TMP_ACCESS" \
            | sort \
            | uniq -c \
            | sort -nr
    else
        echo "No requests"
    fi

    echo
    echo "========================================"
    echo "WEB SERVER / APPLICATION ERRORS"
    echo "========================================"

    if [[ -s "$TMP_ERROR" ]]; then
        cat "$TMP_ERROR"
    else
        echo "No errors"
    fi

} > "$REPORT"


mail \
    -a "From: giveupermusic@yandex.ru" \
    -s "Nginx report: $FROM - $TO" \
    "$MAIL_TO" < "$REPORT"

MAIL_STATUS=$?

if (( MAIL_STATUS != 0 )); then
    logger -t nginx-report "Failed to send report"
    exit "$MAIL_STATUS"
fi


cat > "$STATE" <<EOF
LAST_RUN=$CURRENT_TIME
ACCESS_LINES=$CURRENT_ACCESS_LINES
ERROR_LINES=$CURRENT_ERROR_LINES
EOF

logger -t nginx-report \
    "Report sent to $MAIL_TO for range $FROM - $TO"
