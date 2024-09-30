# Deployment Guide

Nerves Hub is split into two applications: web and device. Both need to be deployed on seperate servers using Kamal.

To Deploy, run:

```sh
kamal deploy
```

## Web

Current list of required secrets for the app are:
* `DATABASE_PEM`
* `DATABASE_URL`
* `LIVE_VIEW_SIGNING_SALT`
* `MAILGUN_API_KEY`
* `MAILGUN_DOMAIN`
* `S3_ACCESS_KEY_ID`
* `S3_BUCKET_NAME`
* `S3_SECRET_ACCESS_KEY`
* `SECRET_KEY_BASE`

## Device

Note that a dedicated IPv4 address is required for device connection to work (at least on networks that don't support IPv6).

If running on Fly, it is required to remove the shared IP address that fly allocates automatically (run `fly ips list -a spendra-nerves-hub-device` to find it).

```sh
fly ips allocate-v4 -a spendra-nerves-hub-device # only once
fly ips release [shared-ip-address] -a spendra-nerves-hub-device
fly deploy -c fly.device.toml
```

Current list of required secrets for the app are:
* `DATABASE_PEM`
* `DATABASE_URL`
* `LIVE_VIEW_SIGNING_SALT`
* `MAILGUN_API_KEY`
* `MAILGUN_DOMAIN`
* `S3_ACCESS_KEY_ID`
* `S3_BUCKET_NAME`
* `S3_SECRET_ACCESS_KEY`
* `SECRET_KEY_BASE`
* `DEVICE_SSL_KEY`: Base 64 encoded private key for device endpoint SSL (Run `File.read!("/path/to/key.pem") |> Base.encode64()` to generate).
* `DEVICE_SSL_CERT`: Base 64 encoded certificate for device endpoint SSL (Run `File.read!("/path/to/cert.pem") |> Base.encode64()` to generate).

### Provision Device Server

In addition to the shared kamal provisioning script, the device server uses SSL certificates and must be configured separately using the following script:

```sh
# ssh spendra@nerves-hub-device
sudo wget -O /etc/apt/sources.list.d/sslmate1.list https://sslmate.com/apt/ubuntu2410/sslmate1.list
sudo wget -O /etc/apt/trusted.gpg.d/sslmate.gpg https://sslmate.com/apt/ubuntu2410/sslmate.gpg
sudo apt-get update
sudo apt-get install sslmate
echo -e "api_key <<API_KEY>>\nkey_directory /var/lib/docker/volumes/nerves_hub_certificates/_data \ncert_directory /var/lib/docker/volumes/nerves_hub_certificates/_data" > /tmp/sslmate.conf && sudo mv /tmp/sslmate.conf /etc/sslmate.conf
echo -e "<<SSL_PRIVATE_KEY>>" >  /tmp/ssl.key && sudo mv /tmp.ssl.key var/lib/docker/volumes/nerves_hub_certificates/_data/device.hub.spendra.swiss.key

sudo tee /etc/cron.daily/sslmate > /dev/null << 'EOF' && sudo chmod +x /etc/cron.daily/sslmate
#!/bin/sh

if sslmate download --all > /dev/null
then
  docker restart $(docker ps --format '{{.Names}}' | grep nerves_hub_web-device) > /dev/null
fi
EOF
```


## Remote (IEx Console)

Note that because of epmd-less deployment, the remote iex console doesn't work. If there is a need to make changes on the production database that aren't possible through UI, it is possible to run a local server pointing to the production database.

