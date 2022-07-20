#  ___   __    ________   ___ __ __   ______         ______   ______   ___ __ __       ______   ______   ___   __    ______      
# /__/\ /__/\ /_______/\ /__//_//_/\ /_____/\       /_____/\ /_____/\ /__//_//_/\     /_____/\ /_____/\ /__/\ /__/\ /_____/\     
# \::\_\\  \ \\::: _  \ \\::\| \| \ \\::::_\/_      \:::__\/ \:::_ \ \\::\| \| \ \    \:::_ \ \\:::_ \ \\::\_\\  \ \\::::_\/_    
#  \:. `-\  \ \\::(_)  \ \\:.      \ \\:\/___/\   ___\:\ \  __\:\ \ \ \\:.      \ \    \:\ \ \ \\:\ \ \ \\:. `-\  \ \\:\/___/\   
#   \:. _    \ \\:: __  \ \\:.\-/\  \ \\::___\/_ /__/\\:\ \/_/\\:\ \ \ \\:.\-/\  \ \    \:\ \ \ \\:\ \ \ \\:. _    \ \\_::._\:\  
#    \. \`-\  \ \\:.\ \  \ \\. \  \  \ \\:\____/\\::\ \\:\_\ \ \\:\_\ \ \\. \  \  \ \    \:\/.:| |\:\/.:| |\. \`-\  \ \ /____\:\ 
#     \__\/ \__\/ \__\/\__\/ \__\/ \__\/ \_____\/ \:_\/ \_____\/ \_____\/ \__\/ \__\/     \____/_/ \____/_/ \__\/ \__\/ \_____\/ 
#
#
# @authors: Samuel Andersen
# @version: 20220719
#
# Notes:
#   - This makes use of the request_wrapper from: https://gitlab.com/-/snippets/1900824
#

import requests_wrapper as requests # See note above
import json
import os
import socket

# Information required to connect to Name.com
NAMEUSER = os.environ.get('NAMEUSER')
TOKEN = os.environ.get('TOKEN')
DOMAINNAME = os.environ.get('DOMAINNAME')
HOST = os.environ.get('HOST')

# Meraki-specific variables
MAPIKEY = os.environ.get('MAPIKEY')
NETWORKID = os.environ.get('NETWORKID')
WGPORT = os.environ.get('WGPORT')

## Function to get the IPv4 address of a host
#  @param addressType Either 'ipv4' or 'ipv6'
def getAddress(addressType = 'ipv4'):

    targetURL = 'https://api64.ipify.org?format=json'

    r = None

    if (addressType == 'ipv4'):
        r = requests.get(targetURL, family = socket.AF_INET)

    elif (addressType == 'ipv6'):
        r = requests.get(targetURL, family = socket.AF_INET6)

    if r.ok:
        return r.json()['ip']

    raise BaseException("Unable to fetch address")

## Function to get the record Id for a host
#  @param recordType Either A or AAAA
def getRecordId(recordType = 'A'):

    targetURL = 'https://api.name.com/v4/domains/{}/records'.format(DOMAINNAME)

    requestHeaders = {
        'Content-Type': 'application/json'
    }

    r = requests.get(targetURL, headers = requestHeaders, auth = (NAMEUSER, TOKEN))

    if r.ok:
        for hostRecord in r.json()['records']:
            if ((hostRecord['fqdn'] == '{}.{}.'.format(HOST, DOMAINNAME)) and (hostRecord['type'] == recordType)):
                return hostRecord['id']

    raise BaseException("Unable to find a DNS record for type {} with FQDN {}.{}".format(recordType, HOST, DOMAINNAME))

## Update a DNS record by record Id
#  @param recordType Either A or AAAA
#  @param recordId Id of the record we want to update
#  @param ipAddress IP address to use, either IPv4 or IPv6
def updateRecord(recordType, recordId, ipAddress):

    targetURL = 'https://api.name.com/v4/domains/{}/records/{}'.format(DOMAINNAME, recordId)

    requestHeaders = {
        'Content-Type': 'application/json'
    }

    requestData = {
        'host': HOST,
        'type': recordType,
        'answer': ipAddress
    }

    r = requests.put(targetURL, headers = requestHeaders, auth = (NAMEUSER, TOKEN), data = json.dumps(requestData))

    if r.ok:
        print('Successfully updated record Id {} ({}) with value: {}'.format(recordId, recordType, ipAddress))
        return r.json()

    # Print out the response if we receive an error
    print(r.json())
    raise BaseException("Error updating DNS record")

## Update the Meraki MX Firewall to allow incoming IPv6 traffic to host
#  @param ipAddress IP address to use, *must* be IPv6
def updateMXFirewall(ipAddress):
    
    targetURL = 'https://api.meraki.com/api/v1/networks/{}/appliance/firewall/inboundFirewallRules'.format(NETWORKID)

    requestHeaders = {
        'Content-Type': 'application/json',
        'X-Cisco-Meraki-API-Key': MAPIKEY
    }

    requestData = {
        'rules': [
            {
                'comment': 'WireGuard',
                'policy': 'allow',
                'protocol': 'udp',
                'srcPort': 'Any',
                'srcCidr': 'Any',
                'destPort': WGPORT,
                'destCidr': '{}/128'.format(ipAddress),
                'syslogEnabled': 'false'
            }
        ]
    }

    r = requests.put(targetURL, headers = requestHeaders, data = json.dumps(requestData))

    if r.ok:
        return r.json()

    # Print out the response if we receive an error
    print(r.json())
    raise BaseException("Error updating MX Firewall ruleset")

if __name__ == '__main__':

    # Define which variables *must* be present for this to run
    requiredEnv = ["NAMEUSER", "TOKEN", "DOMAINNAME", "HOST", "MAPIKEY", "NETWORKID", "WGPORT"]

    # Ensure these variables actually exist in ENV
    for envVar in requiredEnv:
        if envVar not in os.environ:
            raise EnvironmentError("Required environmental variable {} missing. Exiting".format(envVar))

    print(getAddress())
    print(getAddress('ipv6'))

    # Update the records for both IPv4 and IPv6
    updateRecord('A', getRecordId(), getAddress())
    updateRecord('AAAA', getRecordId(recordType = 'AAAA'), getAddress(addressType = 'ipv6'))

    # Update the MX Firewall for the IPv6 address
    updateMXFirewall(getAddress(addressType = 'ipv6'))

    exit(0)