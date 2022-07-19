#!/usr/bin/env sh

# Make sure we are in the root-directory
cd "$(dirname $0)"

# Load dependencies
. ./src/namedotcom.sh
. ./src/namedotcomddns.sh

run () {
  if [ -z "$NAMEUSER" ]; then >&2 echo "USERNAME is not set"; return 1; fi
  if [ -z "$TOKEN" ]; then >&2 echo "TOKEN is not set"; return 1; fi
  if [ -z "$DOMAINNAME" ]; then >&2 echo "DOMAINNAME is not set"; return 1; fi
  if [ -z "$HOST" ]; then >&2 echo "HOST is not set"; return 1; fi
  if [ -z "$TYPE" ]; then
    local TYPE="A"
  fi

  if ! updateRecordByHostWithExternalIp "$NAMEUSER" "$TOKEN" "$DOMAINNAME" "$HOST" "$TYPE" ; then
    >&2 echo "failed to update record"
    return 1
  fi

  return 0
}

fw () {
  f [ -z "$MAPIKEY" ]; then >&2 echo "MAPIKEY is not set"; return 1; fi
  if [ -z "$NETWORKID" ]; then >&2 echo "NETWORKID is not set"; return 1; fi
  if [ -z "$WGPORT" ]; then >&2 echo "WGPORT is not set"; return 1; fi

  local ip="$( getExternalIp )"
  if [ -z "$ip" ]; then
    >&2 echo "failed to fetch ip"
    return 1
  fi

  if ! merakiFWUpdate "$MAPIKEY" "$NETWORKID" "$WGPORT" "$ip" ; then
    >&2 echo "failed to update firewall"
    return 1
  fi

  return 0  
}

run
fw
exit $?
