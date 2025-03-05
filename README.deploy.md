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
