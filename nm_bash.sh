#!/bin/bash
# https://stackoverflow.com/a/24777120
# Loop forever, to deal with chrome.runtime.connectNative
getMessage() {
  read -N 1 uint32
  # https://unix.stackexchange.com/a/13141
  header=0x$(printf "%s" "$uint32" |
  od -t x8 -An |
  tr -dc '[:alnum:]')
  messageLength=$(printf "%d" "$header")
  array=()
  read -N "$messageLength" json
  array+=("$json")
  sendMessage "${array[@]}"
}
sendMessage() {
  message="$*"
  # Calculate the byte size of the string.
  # NOTE: This assumes that byte length is identical to the string length!
  # Do not use multibyte (unicode) characters, escape them instead, e.g.
  # message='"Some unicode character:\u1234"'
  messagelen=${#message}
  # Convert to an integer in native byte order.
  # If you see an error message in Chrome's stdout with
  # "Native Messaging host tried sending a message that is ... bytes long.",
  # then just swap the order, i.e. messagelen1 <-> messagelen4 and
  # messagelen2 <-> messagelen3
  messagelen1=$(((messagelen) & 0xFF))
  messagelen2=$(((messagelen >> 8) & 0xFF))
  messagelen3=$(((messagelen >> 16) & 0xFF))
  messagelen4=$(((messagelen >> 24) & 0xFF))
  # Print the message byte length followed by the actual message.
  printf "$(printf '\\x%x\\x%x\\x%x\\x%x' \
    $messagelen1 $messagelen2 $messagelen3 $messagelen4)%s" "$message"
}
while true; do
  getMessage
done
