# Name.com Dynamic DNS

Dynamic DNS Script for Name.com. Forked from: (https://github.com/LowieHuyghe/name-com-ddns)https://github.com/LowieHuyghe/name-com-ddns. Modified to act as a AAAA record updater (IPv6).

## Usage

### With Docker

```yaml
version: "3"
services:
  name-com-ddns:
    image: lowieh/name-com-ddns:latest
    environment:
      - NAMEUSER=mynameuser
      - TOKEN=mytoken1234567890
      - DOMAINNAME=mydomain.name
      - HOST=www
      - TYPE=A  # Optional, default: A
```

### With CMD

```bash
git clone git@github.com:LowieHuyghe/name-com-ddns.git

NAMEUSER=mynameuser \
TOKEN=mytoken1234567890 \
DOMAINNAME=mydomain.name \
HOST=www \
TYPE=A \  # Optional, default: A
./name-com-ddns/run.sh
```
