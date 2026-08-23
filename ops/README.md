# Branded static origin

`serve.mjs` exposes the checked-in `docs/` tree on loopback only. The production
Cloudflare tunnel maps `room.enby.fish` to this origin; the process does not
possess Cloudflare credentials and cannot create or alter DNS.

The server is intentionally narrow:

- GET and HEAD only;
- no upload, write, proxy, template, API, or directory-listing path;
- decoded paths remain inside `docs/`;
- HTML is not cached, while static assets have a five-minute browser cache;
- CSP, framing, MIME, referrer, permissions, opener, and transport headers are
  sent by the origin;
- malformed, unsupported, and missing requests fail closed.

Install or refresh the reviewed unit, then verify the loopback origin before
changing a tunnel route:

```sh
sudo systemd-analyze verify ops/private-client-room-web.service
sudo install -o root -g root -m 0644 \
  ops/private-client-room-web.service \
  /etc/systemd/system/private-client-room-web.service
sudo systemctl daemon-reload
sudo systemctl enable --now private-client-room-web.service
curl --fail --head http://127.0.0.1:8766/
```

The tunnel ingress rule is deliberately maintained in the private host
configuration rather than this public repository because the same tunnel serves
other owned applications. Its public, non-secret shape is:

```yaml
- hostname: room.enby.fish
  service: http://127.0.0.1:8766
```

Validate the entire private ingress file before restarting the tunnel. Creating
the DNS route is a one-time, account-authorized Cloudflare operation. Never add
tunnel credentials, account certificates, IDs, or tokens to this repository.

GitHub Pages remains a separately built public mirror. Every published canonical,
social, sitemap, and robots URL points to `https://room.enby.fish/` so search
engines receive one preferred origin.
