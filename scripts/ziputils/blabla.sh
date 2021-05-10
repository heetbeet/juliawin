#!/bin/bash
FILE="$(readlink -f "$0")"

searchstr="__BEGIN""_PAYLOAD__"
strindex="$(grep -aob "$searchstr" --color=never "$FILE" | \grep -oE '^[0-9]+' )"
payloadindex=`expr $strindex + ${#searchstr}`

dd bs=4096 skip=$payloadindex iflag=skip_bytes if="$FILE" of="$FILE-output"

exit 0
__BEGIN_PAYLOAD__