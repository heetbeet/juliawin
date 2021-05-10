#!/bin/bash
FILE="$(readlink -f "$0")"

beginpayload="---""BEGIN""-""PAYLOAD""---"
payloadstart="$(gawk -v s="$beginpayload" '{print index($0, s);exit;}' RS='^$' "$FILE")"

dd bs=4096 skip=$payloadstart iflag=skip_bytes if="$FILE" of="$FILE-output"
exit 0
1
2
3
4








thisisarealylonglineoftexttothinkabout
exit 0
---BEGIN-PAYLOAD---