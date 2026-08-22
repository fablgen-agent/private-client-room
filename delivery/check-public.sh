#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: delivery/check-public.sh BASE_DOMAIN

Checks only public, non-authenticated Matrix and Element endpoints. It does not
log in, inspect rooms, read messages, or prove end-to-end encryption, backups,
access control, federation policy, or recovery. Those remain manual acceptance
checks performed with customer-controlled accounts and devices.
EOF
}

die() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

[[ $# -eq 1 ]] || { usage >&2; exit 2; }
base_domain="$1"
[[ "$base_domain" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$ ]] \
  || die "BASE_DOMAIN must be a bare domain such as example.com"

for command_name in curl jq; do
  command -v "$command_name" >/dev/null 2>&1 || die "required command is missing: ${command_name}"
done

temporary_directory="$(mktemp -d)"
trap 'rm -rf -- "$temporary_directory"' EXIT

fetch_json() {
  local url="$1"
  local destination="$2"
  curl --proto '=https' --tlsv1.2 --fail --silent --show-error \
    --max-time 20 --output "$destination" "$url"
  jq empty "$destination" || die "invalid JSON returned by ${url}"
}

versions_file="${temporary_directory}/versions.json"
client_well_known_file="${temporary_directory}/client-well-known.json"
element_config_file="${temporary_directory}/element-config.json"

fetch_json "https://matrix.${base_domain}/_matrix/client/versions" "$versions_file"
jq -e '.versions | type == "array" and length > 0' "$versions_file" >/dev/null \
  || die "Matrix client versions response is missing a non-empty versions array"
printf 'PASS: Matrix client API is reachable over HTTPS.\n'

fetch_json "https://${base_domain}/.well-known/matrix/client" "$client_well_known_file"
client_base_url="$(jq -er '."m.homeserver".base_url' "$client_well_known_file")"
[[ "$client_base_url" == "https://matrix.${base_domain}" || "$client_base_url" == "https://matrix.${base_domain}/" ]] \
  || die "client well-known points to unexpected homeserver: ${client_base_url}"
printf 'PASS: client discovery points to the intended homeserver.\n'

fetch_json "https://element.${base_domain}/config.json" "$element_config_file"
element_base_url="$(jq -er '.default_server_config."m.homeserver".base_url // empty' "$element_config_file")"
[[ "$element_base_url" == "https://matrix.${base_domain}" || "$element_base_url" == "https://matrix.${base_domain}/" ]] \
  || die "Element Web points to unexpected homeserver: ${element_base_url:-missing}"
printf 'PASS: Element Web points to the intended homeserver.\n'

printf '\nPublic checks passed. Still required before acceptance:\n'
printf '%s\n' \
  '- verify two fresh devices and cross-signing' \
  '- prove invited access and uninvited refusal' \
  '- send one message and attachment between verified devices' \
  '- complete an encrypted backup and restore preflight' \
  '- confirm public registration, public directory, telemetry, and federation are disabled' \
  '- remove temporary operator access and transfer administrator/recovery material'
