#!/usr/bin/env sh

# Load dependencies
. ./src/ipify.sh
. ./src/namedotcom.sh

updateRecordByHostWithExternalIp () {
  local nameuser="$1"
  if [ -z "$nameuser" ]; then >&2 echo "nameuser is not set"; return 1; fi
  local token="$2"
  if [ -z "$token" ]; then >&2 echo "token is not set"; return 1; fi
  local domainName="$3"
  if [ -z "$domainName" ]; then >&2 echo "domainName is not set"; return 1; fi
  local host="$4"
  if [ -z "$host" ]; then >&2 echo "host is not set"; return 1; fi
  local type="$5"
  if [ -z "$type" ]; then >&2 echo "type is not set"; return 1; fi

  local ip="$( getExternalIp )"
  if [ -z "$ip" ]; then
    >&2 echo "failed to fetch ip"
    return 1
  fi

  local ip6="$( getExternalIp6 )"
  if [ -z "$ip6" ]; then
    >&2 echo "failed to fetch ip6"
    return 1
  fi

  #if ! updateRecordByHost "$nameuser" "$token" "$domainName" "$host" "A" "$ip"; then
  #  >&2 echo "failed to update record"
  #  return 1
  #fi

  if ! updateRecordByHost "$nameuser" "$token" "$domainName" "$host" "AAAA" "$ip6"; then
    >&2 echo "failed to update ipv6 record"
    return 1
  fi

  return 0
}
