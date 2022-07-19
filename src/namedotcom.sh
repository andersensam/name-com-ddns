#!/usr/bin/env sh

nameDotComRequest () {
  local nameuser="$1"
  if [ -z "$nameuser" ]; then >&2 echo "nameuser is not set"; return 1; fi
  local token="$2"
  if [ -z "$token" ]; then >&2 echo "token is not set"; return 1; fi
  local url="$3"
  if [ -z "$url" ]; then >&2 echo "url is not set"; return 1; fi
  local method="$4"
  if [ -z "$method" ]; then >&2 echo "method is not set"; return 1; fi
  local data="$5"
  if [ -z "$data" ]; then >&2 echo "data is not set"; return 1; fi

  if ! which curl > /dev/null; then
    >&2 echo "nameDotComRequest for '$domainName' failed"
    >&2 echo "  curl needs to be installed"
    return 1
  fi

  local result="$( curl -sSf -u "$nameuser:$token" "$url" -X "$method" -H 'Content-Type: application/json' --data "$data" )"
  if [[ $? != 0 ]] || [ -z "$result" ]; then
    >&2 echo "request to '$url' failed"
    >&2 echo "  data: $data"
    >&2 echo "  result: $result"
    return 1
  fi

  echo "$result"
  return 0
}

merakiFWUpdate () {
  local mapikey="$1"
  if [ -z "$mapikey" ]; then >&2 echo "meraki api key is not set"; return 1; fi
  local networkid="$2"
  if [ -z "$networkid" ]; then >&2 echo "meraki network id is not set"; return 1; fi
  local wgport="$3"
  if [ -z "$wgport" ]; then >&2 echo "wireguard port is not set"; return 1; fi
  local ipv6="$4"
  if [ -z "$ipv6" ]; then >&2 echo "target ipv6 address is not set"; return 1; fi

  local url="https://api.meraki.com/api/v1/networks/$networkid/appliance/firewall/inboundFirewallRules"
  local auth_header="\'X-Cisco-Meraki-API-Key:$mapikey\'"
  local data="{\"rules\":[{\"comment\":\"WireGuard\",\"policy\":\"allow\",\"protocol\":\"udp\",\"srcPort\":\"Any\",\"srcCidr\":\"Any\",\"destPort\":\"$wgport\",\"destCidr\":\"$ipv6/128\",\"syslogEnabled\":false}]}"

  local result="$( curl -sSf "$url" -X PUT -H $auth_header -H 'Content-Type: application/json' --data "$data" )"
  if [[ $? != 0 ]] || [ -z "$result" ]; then
    >&2 echo "request to '$url' failed"
    >&2 echo "  data: $data"
    >&2 echo "  result: $result"
    return 1
  fi

  echo "$result"
  return 0
}

listRecords () {
  local nameuser="$1"
  if [ -z "$nameuser" ]; then >&2 echo "nameuser is not set"; return 1; fi
  local token="$2"
  if [ -z "$token" ]; then >&2 echo "token is not set"; return 1; fi
  local domainName="$3"
  if [ -z "$domainName" ]; then >&2 echo "domainName is not set"; return 1; fi
  local page="$4"
  if [ -z "$page" ]; then
    local page=1
  fi
  local perPage="$3"
  if [ -z "$perPage" ]; then
    local perPage=1000
  fi

  local records="$( nameDotComRequest "$nameuser" "$token" "https://api.name.com/v4/domains/$domainName/records" "GET" "{\"page\":$page, \"perPage\":$perPage}" )"
  if [[ $? != 0 ]] || [ -z "$records" ]; then
    >&2 echo "listRecords for '$domainName' failed"
    return 1
  fi

  echo "$records"
  return 0
}

getRecordId () {
  local nameuser="$1"
  if [ -z "$nameuser" ]; then >&2 echo "nameuser is not set"; return 1; fi
  local token="$2"
  if [ -z "$token" ]; then >&2 echo "token is not set"; return 1; fi
  local domainName="$3"
  if [ -z "$domainName" ]; then >&2 echo "domainName is not set"; return 1; fi
  local host="$4"
  if [ -z "$host" ]; then >&2 echo "host is not set"; return 1; fi

  local records="$( listRecords "$nameuser" "$token" "$domainName" )"
  if [ -z "$records" ]; then
    >&2 echo "getRecordId for '$domainName' failed"
    return 1
  fi

  if ! which jq > /dev/null; then
    >&2 echo "getRecordId for '$domainName' failed"
    >&2 echo "  jq needs to be installed"
    return 1
  fi

  local id=$( echo "$records" | jq -M ".records | .[] | select(.host==\"$host\") | .id" )
  if [ -z "$id" ]; then
    >&2 echo "getRecordId for '$domainName' failed"
    >&2 echo "  no id found for '$host'"
    return 1
  fi

  printf "$id"
  return 0
}

updateRecord () {
  local nameuser="$1"
  if [ -z "$nameuser" ]; then >&2 echo "nameuser is not set"; return 1; fi
  local token="$2"
  if [ -z "$token" ]; then >&2 echo "token is not set"; return 1; fi
  local domainName="$3"
  if [ -z "$domainName" ]; then >&2 echo "domainName is not set"; return 1; fi
  local id="$4"
  if [ -z "$id" ]; then >&2 echo "id is not set"; return 1; fi
  local host="$5"
  if [ -z "$host" ]; then >&2 echo "host is not set"; return 1; fi
  local type="$6"
  if [ -z "$type" ]; then >&2 echo "type is not set"; return 1; fi
  local answer="$7"
  if [ -z "$answer" ]; then >&2 echo "answer is not set"; return 1; fi

  if ! nameDotComRequest "$nameuser" "$token" "https://api.name.com/v4/domains/$domainName/records/$id" "PUT" "{\"host\":\"$host\",\"type\":\"$type\",\"answer\":\"$answer\"}"; then
    >&2 echo "updateRecord failed"
    return 1
  fi

  return 0
}

updateRecordByHost () {
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
  local answer="$6"
  if [ -z "$answer" ]; then >&2 echo "answer is not set"; return 1; fi

  local id=$( getRecordId "$nameuser" "$token" "$domainName" "$host" )
  if [ -z "$id" ]; then
    >&2 echo "updateRecordByHost failed"
    return 1
  fi

  if ! updateRecord "$nameuser" "$token" "$domainName" "$id" "$host" "$type" "$answer" > /dev/null; then
    >&2 echo "updateRecordByHost failed"
    return 1
  fi

  return 0
}
