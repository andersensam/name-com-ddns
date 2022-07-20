#!/usr/bin/env sh

getExternalIp6 () {
  local result="$( curl -sSf https://api64.ipify.org?format=text )"
  if [[ $? != 0 ]] || [ -z "$result" ]; then
    >&2 echo "failed to fetch external ip"
    >&2 echo "  result: $result"
    return 1
  fi

  printf "$result"
  return 0
}

getExternalIp () {
  local result="$( curl -sSf https://api.ipify.org?format=text )"
  if [[ $? != 0 ]] || [ -z "$result" ]; then
    >&2 echo "failed to fetch external ip"
    >&2 echo "  result: $result"
    return 1
  fi

  printf "$result"
  return 0
}
