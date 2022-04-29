#!/bin/bash
# Bash Native Messaging host, guest271314 2022
# Echo's simple JSON string that does not include (escaped) double quotes
# How do I use a shell-script as Chrome Native Messaging host application
# https://stackoverflow.com/a/24777120
sendMessage() {
  message=\"$1\"
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
  messagelen1=$((($messagelen) & 0xFF))
  messagelen2=$((($messagelen >> 8) & 0xFF))
  messagelen3=$((($messagelen >> 16) & 0xFF))
  messagelen4=$((($messagelen >> 24) & 0xFF))
  # Print the message byte length followed by the actual message.
  printf "$(printf '\\x%x\\x%x\\x%x\\x%x' \
    $messagelen1 $messagelen2 $messagelen3 $messagelen4)%s" "$message"
}

getMessage() {
  input=""
  datacount=0
  doublequotecount=0
  
  # Loop forever, to deal with chrome.runtime.connectNative
  while true; do
    IFS= read -res -n1 data
    # TODO: Process length of JSON (1st $data read).
    if ((datacount++)); then
      if [ "$data" == "\"" ]; then
        if ((doublequotecount++)); then
          input+="\\n$args "
          sendMessage "$input"
          # Disconnect host from connectNative client.
          # break
        fi
        continue
      fi
      # Do not write double quotation marks.
      if [ "$data" != "\"" ]; then
        # Read the first message
        # Assuming that the message ALWAYS ends with a },
        # with no }s in the string. Adopt this piece of code if needed.
        input+="$data"
      fi
    fi
  done
}

getNativeMessagingHostArguments() {
  # https://wiki.bash-hackers.org/commands/builtin/caller
  local frame=0
  while caller $frame; do
    ((++frame));
  done
  return "$@"
}

args=`getNativeMessagingHostArguments`
args+="\\n$@"
getMessage
