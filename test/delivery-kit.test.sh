#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
prepare_script="${repo_root}/delivery/prepare.sh"
public_check_script="${repo_root}/delivery/check-public.sh"
preflight_script="${repo_root}/delivery/preflight.sh"

bash -n "$prepare_script" "$public_check_script" "$preflight_script"

"$prepare_script" --help >/dev/null
"$public_check_script" --help >/dev/null
"$preflight_script" --help >/dev/null

if "$prepare_script" invalid-domain 192.0.2.10 /tmp/should-not-exist 2>/dev/null; then
  printf 'prepare.sh accepted an invalid domain\n' >&2
  exit 1
fi

if "$public_check_script" invalid-domain 2>/dev/null; then
  printf 'check-public.sh accepted an invalid domain\n' >&2
  exit 1
fi

if "$preflight_script" invalid-domain 192.0.2.10 2>/dev/null; then
  printf 'preflight.sh accepted an invalid domain\n' >&2
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

fixture_root="${integration_root}/fixtures"
mkdir -p "$fixture_root/bin"
cat >"${fixture_root}/os-release" <<'EOF'
ID=ubuntu
PRETTY_NAME="Ubuntu 24.04 LTS"
EOF
cat >"${fixture_root}/meminfo" <<'EOF'
MemTotal:        4194304 kB
EOF
for command_name in date df id mkdir mktemp mv chmod dirname awk sort grep cat stat; do
  command_path="$(command -v "$command_name")"
  ln -s "$command_path" "${fixture_root}/bin/${command_name}"
done
ln -s "$(command -v bash)" "${fixture_root}/bin/bash"
cat >"${fixture_root}/bin/uname" <<'EOF'
#!/usr/bin/env bash
printf 'x86_64\n'
EOF
cat >"${fixture_root}/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"${fixture_root}/bin/python3" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"${fixture_root}/bin/sudo" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"${fixture_root}/bin/getent" <<'EOF'
#!/usr/bin/env bash
case "${2:-}" in
  192.0.2.10|matrix.example.test|element.example.test) printf '192.0.2.10 STREAM host\n' ;;
  *) exit 2 ;;
esac
EOF
chmod 700 "${fixture_root}/bin/uname" "${fixture_root}/bin/systemctl" \
  "${fixture_root}/bin/python3" "${fixture_root}/bin/sudo" "${fixture_root}/bin/getent"

preflight_report="${integration_root}/preflight.md"
PATH="${fixture_root}/bin" \
PCR_OS_RELEASE_FILE="${fixture_root}/os-release" \
PCR_MEMINFO_FILE="${fixture_root}/meminfo" \
PCR_DISK_PATH="${integration_root}" \
  "$preflight_script" example.test 192.0.2.10 "$preflight_report" >/dev/null

[[ -f "$preflight_report" && "$(stat -c '%a' "$preflight_report")" == "600" ]]
grep -Fq 'Result: **READY FOR WRITTEN REVIEW**' "$preflight_report"
grep -Fq 'Matrix DNS:** matrix.example.test resolves to the supplied server address' "$preflight_report"
grep -Fq 'Element DNS:** element.example.test resolves to the supplied server address' "$preflight_report"
grep -Fq 'did not log in remotely' "$preflight_report"

if PATH="${fixture_root}/bin" \
  PCR_OS_RELEASE_FILE="${fixture_root}/os-release" \
  PCR_MEMINFO_FILE="${fixture_root}/meminfo" \
  PCR_DISK_PATH="${integration_root}" \
    "$preflight_script" example.test 192.0.2.10 "$preflight_report" >/dev/null 2>&1; then
  printf 'preflight.sh overwrote an existing report\n' >&2
  exit 1
fi

cat >"${fixture_root}/os-release" <<'EOF'
ID=debian
PRETTY_NAME="Debian GNU/Linux 13"
EOF
cat >"${fixture_root}/meminfo" <<'EOF'
MemTotal:        1048576 kB
EOF
cat >"${fixture_root}/bin/uname" <<'EOF'
#!/usr/bin/env bash
printf 'aarch64\n'
EOF
cat >"${fixture_root}/bin/getent" <<'EOF'
#!/usr/bin/env bash
exit 2
EOF
chmod 700 "${fixture_root}/bin/uname" "${fixture_root}/bin/getent"

review_report="${integration_root}/review.md"
PATH="${fixture_root}/bin" \
PCR_OS_RELEASE_FILE="${fixture_root}/os-release" \
PCR_MEMINFO_FILE="${fixture_root}/meminfo" \
PCR_DISK_PATH="${integration_root}" \
  "$preflight_script" example.test 192.0.2.10 "$review_report" >/dev/null

grep -Fq 'Result: **PREPARATION NEEDED**' "$review_report"
grep -Fq 'REVIEW — Operating system' "$review_report"
grep -Fq 'REVIEW — Architecture' "$review_report"
grep -Fq 'REVIEW — Memory' "$review_report"
grep -Fq 'REVIEW — Matrix DNS' "$review_report"
grep -Fq 'REVIEW — Element DNS' "$review_report"

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
