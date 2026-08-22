# Private Client Room handover record

This template records evidence without storing passwords, access tokens,
recovery keys, message content, customer data, or private server addresses in
the public repository.

## Scope identity

- Customer-controlled base domain: `[record in the private handover copy]`
- Customer-controlled server: `[record privately]`
- Locked deployment commit: `c0681e4bc2d55df19056f3d3a7b997f9e7335890`
- Installed component versions: `[record after deployment]`
- Written scope agreed: `[date]`
- Acceptance performed: `[date]`

The Matrix server name is effectively permanent after deployment. Confirm it
in writing before installation.

## Automated public evidence

- [ ] `delivery/check-public.sh BASE_DOMAIN` passes.
- [ ] TLS is valid for the base, Matrix, and Element hosts.
- [ ] The public Matrix client API reports supported versions.
- [ ] Client discovery and Element Web point to the intended homeserver.

These checks use public endpoints only. They do not prove encryption, room
authorization, backup recovery, federation policy, or operator removal.

## Customer-controlled acceptance

- [ ] Two fresh devices sign in and verify one another.
- [ ] An invited client joins the intended private room.
- [ ] An uninvited account cannot join the room.
- [ ] One ordinary message and one non-sensitive test attachment sync between
      the two verified devices.
- [ ] Public registration and the public room directory are disabled.
- [ ] Federation is disabled for the fixed pilot, unless a separately written
      scope states the exact allowed domains and privacy implications.
- [ ] Synapse usage reporting is disabled.
- [ ] An encrypted backup completes to the customer-approved destination.
- [ ] A restore preflight verifies that the backup is readable without
      overwriting the live deployment.
- [ ] The customer stores recovery material independently of the server.
- [ ] Temporary operator SSH keys, accounts, and tokens are removed.
- [ ] The customer holds the sole continuing administrator access.

## Operations transferred

- [ ] Customer receives the private inventory and knows it contains secrets.
- [ ] Customer receives the pinned upstream commit and component versions.
- [ ] Update procedure includes reviewing upstream changelogs before applying.
- [ ] Backup schedule, retention, encryption, destination, and restore owner are
      recorded privately.
- [ ] The customer understands that homeserver metadata and infrastructure IP
      logs still exist even when room contents are end-to-end encrypted.
- [ ] Seven-day deployment-fault window and exclusions are restated.

Payment becomes due only after the written acceptance checks pass. This record
is operational evidence, not a penetration test, compliance certification,
anonymity guarantee, or legal opinion.

