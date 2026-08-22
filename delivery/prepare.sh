#!/usr/bin/env bash
set -euo pipefail

umask 077

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The lock file is resolved relative to this script at runtime.
# shellcheck disable=SC1091
source "${script_dir}/upstream.env"

usage() {
  cat <<'EOF'
Usage: delivery/prepare.sh BASE_DOMAIN SERVER_ADDRESS OUTPUT_DIRECTORY

Creates a new, mode-700 customer delivery workspace from the audited upstream
Matrix Docker Ansible deploy commit. The output contains generated secrets.
Keep it outside public repositories, synced folders, tickets, and chat.

Example:
  delivery/prepare.sh example.com 203.0.113.10 /secure/client-room-example
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

[[ $# -eq 3 ]] || { usage >&2; exit 2; }

base_domain="$1"
server_address="$2"
output_directory="$3"

[[ "$base_domain" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$ ]] \
  || die "BASE_DOMAIN must be a bare domain such as example.com"
[[ "$server_address" =~ ^[A-Za-z0-9.:_-]+$ ]] \
  || die "SERVER_ADDRESS must be an IP address or hostname without shell metacharacters"
[[ "$output_directory" != "/" && "$output_directory" != "." ]] \
  || die "OUTPUT_DIRECTORY must be a new, explicit directory"
[[ ! -e "$output_directory" ]] || die "OUTPUT_DIRECTORY already exists; refusing to overwrite it"

for command_name in git make openssl realpath; do
  command -v "$command_name" >/dev/null 2>&1 || die "required command is missing: ${command_name}"
done

# A generated inventory contains credentials. Never allow it to land inside the
# public source tree, even when the requested path does not exist yet.
repository_root="$(realpath "${script_dir}/..")"
resolved_output_directory="$(realpath -m "$output_directory")"
case "$resolved_output_directory" in
  "$repository_root"|"$repository_root"/*)
    die "OUTPUT_DIRECTORY must be outside the public repository"
    ;;
esac

output_parent="$(dirname "$output_directory")"
mkdir -p "$output_parent"
staging_directory="$(mktemp -d "${output_parent}/.private-client-room.XXXXXX")"

cleanup() {
  if [[ -n "${staging_directory:-}" && -d "$staging_directory" ]]; then
    rm -rf -- "$staging_directory"
  fi
}
trap cleanup EXIT

git -C "$staging_directory" init --quiet
git -C "$staging_directory" remote add origin "$MATRIX_DEPLOY_REPOSITORY"
git -C "$staging_directory" fetch --quiet --depth=1 origin "$MATRIX_DEPLOY_COMMIT"
git -C "$staging_directory" checkout --quiet --detach FETCH_HEAD

actual_commit="$(git -C "$staging_directory" rev-parse HEAD)"
[[ "$actual_commit" == "$MATRIX_DEPLOY_COMMIT" ]] \
  || die "upstream commit mismatch: expected ${MATRIX_DEPLOY_COMMIT}, received ${actual_commit}"

make --no-print-directory -C "$staging_directory" add-inventory-host \
  domain="$base_domain" ip="$server_address"

vars_file="${staging_directory}/inventory/host_vars/matrix.${base_domain}/vars.yml"
[[ -f "$vars_file" ]] || die "upstream inventory generator did not create ${vars_file}"

cat >>"$vars_file" <<'EOF'

# Private Client Room pilot defaults. Review these with the customer before install.
# Accounts are created by the administrator; there is no public registration.
matrix_synapse_enable_registration: false
matrix_client_element_registration_enabled: false

# Do not advertise or expose a public room directory.
matrix_synapse_allow_public_rooms_without_auth: false
matrix_synapse_allow_public_rooms_over_federation: false

# The fixed pilot is private and non-federated by default. Any federation change
# requires a separate written scope and a new privacy-boundary review.
matrix_homeserver_federation_enabled: false

# Do not send anonymous homeserver usage statistics.
matrix_synapse_report_stats: false
EOF

find "${staging_directory}/inventory" -type d -exec chmod 700 {} +
find "${staging_directory}/inventory" -type f -exec chmod 600 {} +

cat >"${staging_directory}/PRIVATE-CLIENT-ROOM.md" <<EOF
# Private Client Room delivery workspace

Base domain: ${base_domain}
Matrix host: matrix.${base_domain}
Element Web host: element.${base_domain}
Server address: ${server_address}
Upstream repository: ${MATRIX_DEPLOY_REPOSITORY}
Locked upstream commit: ${MATRIX_DEPLOY_COMMIT}

This directory contains generated secrets. Keep it mode 700, outside public
repositories and synced folders, and transfer ownership to the customer at
handover. Review the upstream changelog and migration acknowledgement before
every install or update. Do not paste inventory files into tickets or chat.

The fixed pilot defaults to no public registration, no public room directory,
no Synapse telemetry, and no federation. The administrator creates accounts.
See the public operator handover template in the Private Client Room repository.
EOF

chmod 600 "${staging_directory}/PRIVATE-CLIENT-ROOM.md"
mv -- "$staging_directory" "$output_directory"
staging_directory=""
chmod 700 "$output_directory"

printf 'Prepared private delivery workspace at %s\n' "$output_directory"
printf 'Locked upstream commit: %s\n' "$MATRIX_DEPLOY_COMMIT"
printf 'Generated secrets were not printed. Review the inventory locally before install.\n'
