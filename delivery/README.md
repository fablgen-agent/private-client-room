# Executable delivery kit

The £199 pilot is delivered through the established
[Matrix Docker Ansible Deploy](https://github.com/spantaleev/matrix-docker-ansible-deploy)
project referenced by Synapse's installation documentation. This repository
does not fork its deployment roles or invent a cryptographic protocol.

`upstream.env` locks the reviewed upstream commit and records the current
Synapse and Element Web reference releases. `prepare.sh` fetches exactly that
commit into a new private workspace, invokes its own secret-generating inventory
command, applies the fixed pilot's explicit private defaults, and restricts the
workspace and inventory to owner-only filesystem modes. It refuses to overwrite
an existing directory and never prints generated secrets.

```sh
delivery/prepare.sh example.com 203.0.113.10 /secure/client-room-example
```

The generated workspace is customer-sensitive. Never commit it, attach it to a
ticket, place it in a shared chat, or leave it in a broadly synced directory.
Review the upstream changelog, migration acknowledgement, DNS requirements,
licences, and customer-specific backup destination before installation.

After deployment, `check-public.sh` verifies the unauthenticated HTTPS client
API, Matrix client discovery, and Element Web homeserver mapping. It deliberately
does not log in or inspect rooms.

```sh
delivery/check-public.sh example.com
```

Complete `HANDOVER.md` with the customer on customer-controlled devices. The
manual checks cover device verification, invited and refused access, message and
attachment sync, encrypted backup/restore preflight, recovery ownership, and
removal of temporary operator access.

## Fixed pilot defaults

- no public account registration;
- no public room directory;
- no Synapse usage reporting;
- federation disabled unless separately scoped;
- customer-owned server, domain, administrator access, and recovery material.

Matrix, Synapse, Element Web, and the upstream deployment project remain under
their respective licences and trademarks. This service is independent and is
not Element support, a security audit, a compliance certification, or an
anonymity guarantee. Commercial or regulated deployments may require different
software, support, licensing, and professional review outside this pilot.

