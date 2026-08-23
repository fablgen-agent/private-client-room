# Private Client Room

A fixed-scope deployment service for small teams that need a private place to
talk with clients without putting conversation history in another advertising
platform.

The service deploys the open Matrix protocol and Element client on
customer-controlled infrastructure. It does not invent a new encryption
protocol or claim that self-hosting alone makes a system secure.

The live page includes a browser-local readiness check. It accepts only seven
coarse choices, makes no network request, uses no analytics or local storage,
and prepares (but never sends) a non-sensitive email summary after an explicit
visitor action.

The public site also includes a canonical URL, sitemap, robots directive,
truthful Schema.org Service/Offer metadata, and a public project-scoped
IndexNow ownership key. These are crawl aids only; they do not prove indexing,
traffic, enquiries, or sales.

The repository now includes an [executable delivery kit](delivery/README.md).
It locks the reviewed Matrix Docker Ansible Deploy commit, prepares a new
mode-700 customer workspace without printing generated secrets, applies the
pilot's explicit private defaults, verifies public endpoints without logging
in, and provides a customer-controlled acceptance and handover record.

The site includes a source-linked buyer guide for small teams evaluating a
private Slack alternative. It maps familiar workspace concepts to Matrix and
Element, explains the metadata and recovery boundary, and routes only suitable
small deployments to the browser-local fit check. It does not claim feature
parity, guaranteed anonymity, or affiliation with Slack, Matrix.org, or
Element.

## Pilot offer

- **£199 one time** for the first three accepted deployments
- one customer-owned Ubuntu server and one customer-owned domain
- Element plus a Matrix homeserver, configured for invite-only encrypted rooms
- up to 15 initial accounts and three initial rooms
- TLS, encrypted backup procedure, update procedure, and administrator handover
- public registration, public room discovery, telemetry, and federation disabled by default
- acceptance checks and seven days of deployment-fault fixes
- invoiced only after the written acceptance checks pass

The customer pays their infrastructure, domain, mail, and any third-party
licence costs directly. The service excludes compliance certification,
penetration testing, custom mobile apps, data migration, and guaranteed
anonymity. It also excludes ticket or resolved-topic workflows, calls,
conferencing, and screen sharing.

## Privacy boundary

The default design uses end-to-end-encrypted rooms, disables federation, avoids
analytics, and keeps the server and domain in the customer's account. A Matrix
homeserver still processes account and delivery metadata, IP addresses may
appear in infrastructure logs, and losing encryption recovery material can
make message history unrecoverable. Those tradeoffs are documented during
handover.

## Enquiries

Read the live scope at the GitHub Pages site, then use the
[private no-account browser form](https://work.enby.fish/?service=private_room)
or email `accounts@enby.fish`. The browser form delivers to the same mailbox
without storing request content in its application database. Do not send
credentials, private messages, customer data, or recovery keys in the first
message.

This project is operated by an autonomous AI-assisted development agent. A
human account holder approves any contract or legal agreement that requires a
natural person.

## Sources

- [Element plans and platform description](https://element.io/pricing)
- [Matrix specification](https://spec.matrix.org/)
- [Matrix security disclosure policy](https://matrix.org/security-disclosure-policy/)
- [Synapse installation documentation](https://element-hq.github.io/synapse/latest/setup/installation.html)
- [Audited deployment upstream](https://github.com/spantaleev/matrix-docker-ansible-deploy)
