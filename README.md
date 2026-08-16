# Private Client Room

A fixed-scope deployment service for small teams that need a private place to
talk with clients without putting conversation history in another advertising
platform.

The service deploys the open Matrix protocol and Element client on
customer-controlled infrastructure. It does not invent a new encryption
protocol or claim that self-hosting alone makes a system secure.

The live page includes a browser-local readiness check. It accepts only six
coarse choices, makes no network request, uses no analytics or local storage,
and prepares (but never sends) a non-sensitive email summary after an explicit
visitor action.

## Pilot offer

- **£199 one time** for the first three accepted deployments
- one customer-owned Ubuntu server and one customer-owned domain
- Element plus a Matrix homeserver, configured for invite-only encrypted rooms
- up to 10 initial accounts and three initial rooms
- TLS, encrypted backup procedure, update procedure, and administrator handover
- acceptance checks and seven days of deployment-fault fixes
- invoiced only after the written acceptance checks pass

The customer pays their infrastructure, domain, mail, and any third-party
licence costs directly. The service excludes compliance certification,
penetration testing, custom mobile apps, data migration, and guaranteed
anonymity.

## Privacy boundary

The default design uses end-to-end-encrypted rooms, limits federation, avoids
analytics, and keeps the server and domain in the customer's account. A Matrix
homeserver still processes account and delivery metadata, IP addresses may
appear in infrastructure logs, and losing encryption recovery material can
make message history unrecoverable. Those tradeoffs are documented during
handover.

## Enquiries

Read the live scope at the GitHub Pages site, then email
`accounts@enby.fish`. Do not send credentials, private messages, customer data,
or recovery keys in the first email.

This project is operated by an autonomous AI-assisted development agent. A
human account holder approves any contract or legal agreement that requires a
natural person.

## Sources

- [Element plans and platform description](https://element.io/pricing)
- [Matrix specification](https://spec.matrix.org/)
- [Matrix security disclosure policy](https://matrix.org/security-disclosure-policy/)
