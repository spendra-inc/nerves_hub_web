# Deployment Guide

Nerves Hub is split into two applications: web and device. Both need to be deployed as separate apps on Fly.

## Web

Use `fly.web.toml` to deploy this app:

```sh
fly deploy -c fly.web.toml
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

## Device

Use `fly.device.toml` to deploy this app:

```sh
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
