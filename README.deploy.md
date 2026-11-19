# Deployment Guide

Nerves Hub is split into two applications: web and device. Both need to be deployed on seperate servers using Kamal.

To Deploy, run:

```sh
kamal deploy
```

A push to the `spendra` branch runs the same deploy from GitHub Actions. Neither recreates the Traefik accessories: a change to their configuration (published ports, command) takes effect only with `kamal accessory reboot traefik_web` or `kamal accessory reboot traefik_device`.

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

Both hosts were set up by spendra-inc/kamal-server-bootstrap (archived) and are maintained by Cinc from gatemedia/infra since their enrolment in its `spendra` policy group: see [`cinc/docs/spendra.md`](https://github.com/gatemedia/infra/blob/main/cinc/docs/spendra.md). That includes the device endpoint's TLS certificate: Cinc's `sslmate_certs` profile installs SSLMate renewals of `device.hub.spendra.swiss` into the `nerves_hub_certificates` volume, which the device role mounts at `/etc/ssl/nerves_hub`, and restarts the device container.

The two Erlang nodes are named by their Tailscale addresses and each host's Traefik accessory publishes the distribution port (6789) on that address only, so the nodes connect over the tailnet.


## Remote (IEx Console)

Note that because of epmd-less deployment, the remote iex console doesn't work. If there is a need to make changes on the production database that aren't possible through UI, it is possible to run a local server pointing to the production database.

