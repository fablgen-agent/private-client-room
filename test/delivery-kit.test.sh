#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
prepare_script="${repo_root}/delivery/prepare.sh"
public_check_script="${repo_root}/delivery/check-public.sh"

bash -n "$prepare_script" "$public_check_script"

"$prepare_script" --help >/dev/null
"$public_check_script" --help >/dev/null

if "$prepare_script" invalid-domain 192.0.2.10 /tmp/should-not-exist 2>/dev/null; then
  printf 'prepare.sh accepted an invalid domain\n' >&2
  exit 1
fi

if "$public_check_script" invalid-domain 2>/dev/null; then
  printf 'check-public.sh accepted an invalid domain\n' >&2
  exit 1
fi

repository_output="${repo_root}/.private-delivery-test-workspace"
if "$prepare_script" example.test 192.0.2.10 "$repository_output" 2>/dev/null; then
  printf 'prepare.sh allowed a secret workspace inside the public repository\n' >&2
  exit 1
fi
[[ ! -e "$repository_output" ]]

integration_root="$(mktemp -d)"
trap 'rm -rf -- "$integration_root"' EXIT
delivery_workspace="${integration_root}/workspace"

"$prepare_script" example.test 192.0.2.10 "$delivery_workspace" >/dev/null

# The lock file is resolved from the repository root at runtime.
# shellcheck disable=SC1091
source "${repo_root}/delivery/upstream.env"
[[ "$(git -C "$delivery_workspace" rev-parse HEAD)" == "$MATRIX_DEPLOY_COMMIT" ]]
[[ "$(stat -c '%a' "$delivery_workspace")" == "700" ]]

vars_file="${delivery_workspace}/inventory/host_vars/matrix.example.test/vars.yml"
hosts_file="${delivery_workspace}/inventory/hosts"
[[ -f "$vars_file" && -f "$hosts_file" ]]
[[ "$(stat -c '%a' "$vars_file")" == "600" ]]
[[ "$(stat -c '%a' "$hosts_file")" == "600" ]]

grep -Fxq 'matrix_domain: example.test' "$vars_file"
grep -Fxq 'matrix_homeserver_federation_enabled: false' "$vars_file"
grep -Fxq 'matrix_synapse_enable_registration: false' "$vars_file"
grep -Fxq 'matrix_synapse_report_stats: false' "$vars_file"
grep -Fq 'matrix.example.test ansible_host=192.0.2.10' "$hosts_file"

generic_secret="$(sed -n "s/^matrix_homeserver_generic_secret_key: '\([A-Za-z0-9]*\)'$/\1/p" "$vars_file")"
postgres_secret="$(sed -n "s/^postgres_connection_password: '\([A-Za-z0-9]*\)'$/\1/p" "$vars_file")"
[[ "${#generic_secret}" -eq 64 && "${#postgres_secret}" -eq 64 ]]
[[ "$generic_secret" != "$postgres_secret" ]]

if "$prepare_script" example.test 192.0.2.10 "$delivery_workspace" 2>/dev/null; then
  printf 'prepare.sh overwrote an existing workspace\n' >&2
  exit 1
fi

printf 'delivery kit tests passed\n'
