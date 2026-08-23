#!/usr/bin/env bash
set -euo pipefail

umask 077

usage() {
  cat <<'EOF'
Usage: delivery/preflight.sh BASE_DOMAIN SERVER_ADDRESS [REPORT_FILE]

Runs read-only prerequisite and public-DNS checks before a Private Client Room
deployment. It does not log in remotely, install packages, open ports, change
DNS, or inspect Matrix accounts. If REPORT_FILE is supplied, the script creates
a new mode-600 Markdown report and refuses to overwrite an existing file.
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

[[ $# -ge 2 && $# -le 3 ]] || { usage >&2; exit 2; }

base_domain="$1"
server_address="$2"
report_file="${3:-}"

[[ "$base_domain" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$ ]] \
  || die "BASE_DOMAIN must be a bare domain such as example.com"
[[ "$server_address" =~ ^[A-Za-z0-9.:_-]+$ ]] \
  || die "SERVER_ADDRESS must be an IP address or hostname without shell metacharacters"
[[ -z "$report_file" || ! -e "$report_file" ]] \
  || die "REPORT_FILE already exists; refusing to overwrite it"

for command_name in date df getent uname; do
  command -v "$command_name" >/dev/null 2>&1 || die "required command is missing: ${command_name}"
done

os_release_file="${PCR_OS_RELEASE_FILE:-/etc/os-release}"
meminfo_file="${PCR_MEMINFO_FILE:-/proc/meminfo}"
[[ -r "$os_release_file" ]] || die "cannot read OS release information"
[[ -r "$meminfo_file" ]] || die "cannot read memory information"

# shellcheck disable=SC1090
source "$os_release_file"
os_id="${ID:-unknown}"
os_name="${PRETTY_NAME:-${NAME:-unknown}}"
architecture="$(uname -m)"
memory_kib="$(awk '/^MemTotal:/ { print $2; exit }' "$meminfo_file")"
[[ "$memory_kib" =~ ^[0-9]+$ ]] || die "could not parse total memory"
memory_mib=$((memory_kib / 1024))
disk_available="$(df -hP "${PCR_DISK_PATH:-/}" | awk 'NR == 2 { print $4 }')"

declare -a findings=()
review_count=0

add_pass() {
  findings+=("- **PASS — $1:** $2")
}

add_review() {
  findings+=("- **REVIEW — $1:** $2")
  review_count=$((review_count + 1))
}

add_info() {
  findings+=("- **INFO — $1:** $2")
}

if [[ "$os_id" == "ubuntu" ]]; then
  add_pass "Operating system" "${os_name}. The fixed pilot targets Ubuntu."
else
  add_review "Operating system" "${os_name}. The pinned upstream supports other stable systemd distributions, but this fixed pilot is scoped to Ubuntu."
fi

if command -v systemctl >/dev/null 2>&1; then
  add_pass "Service manager" "systemctl is available."
else
  add_review "Service manager" "systemctl was not found; the pinned upstream requires a systemd-based server."
fi

if [[ "$architecture" == "x86_64" || "$architecture" == "amd64" ]]; then
  add_pass "Architecture" "${architecture}; the upstream recommends x86/amd64."
else
  add_review "Architecture" "${architecture}; the upstream permits some alternatives but does not fully support every component on them."
fi

if (( memory_mib >= 2048 )); then
  add_pass "Memory" "${memory_mib} MiB total; this meets the upstream starting recommendation of at least 2 GB."
else
  add_review "Memory" "${memory_mib} MiB total; the upstream recommends starting with at least 2 GB."
fi

add_info "Available disk" "${disk_available} is currently available on the checked filesystem. The pinned upstream does not publish one universal minimum because media retention and optional services change storage needs; agree a customer-specific budget before installation."

if command -v python3 >/dev/null 2>&1; then
  add_pass "Python" "python3 is available for Ansible on the server."
else
  add_review "Python" "python3 was not found and must be available before deployment."
fi

if command -v sudo >/dev/null 2>&1; then
  if [[ "$(id -u)" == "0" ]] || sudo -n true >/dev/null 2>&1; then
    add_pass "Privilege path" "sudo is installed and non-interactive elevation is available for this operator."
  else
    add_review "Privilege path" "sudo is installed, but non-interactive elevation was not confirmed. No password prompt was opened."
  fi
else
  add_review "Privilege path" "sudo was not found; the pinned upstream requires it even when Ansible connects as root."
fi

resolve_addresses() {
  { getent ahosts "$1" 2>/dev/null || true; } | awk '{ print $1 }' | sort -u
}

expected_addresses="$(resolve_addresses "$server_address")"
if [[ -z "$expected_addresses" ]]; then
  expected_addresses="$server_address"
fi

check_dns_name() {
  local label="$1"
  local host="$2"
  local resolved
  resolved="$(resolve_addresses "$host")"
  if [[ -z "$resolved" ]]; then
    add_review "$label DNS" "${host} does not currently resolve publicly."
    return
  fi
  if grep -Fqx -f <(printf '%s\n' "$expected_addresses") <(printf '%s\n' "$resolved"); then
    add_pass "$label DNS" "${host} resolves to the supplied server address."
  else
    add_review "$label DNS" "${host} resolves, but not to the supplied server address."
  fi
}

check_dns_name "Matrix" "matrix.${base_domain}"
check_dns_name "Element" "element.${base_domain}"

if (( review_count == 0 )); then
  overall="READY FOR WRITTEN REVIEW"
  summary="Every automated prerequisite check passed. Manual scope, firewall, backup destination, recovery ownership, and customer approval are still required."
else
  overall="PREPARATION NEEDED"
  summary="${review_count} item(s) need review before deployment. A REVIEW result is not automatically a failure where the pinned upstream documents an alternative."
fi

report="$(cat <<EOF
# Private Client Room preflight

- Checked at: $(date -u +'%Y-%m-%dT%H:%M:%SZ')
- Base domain: ${base_domain}
- Supplied server address: ${server_address}
- Result: **${overall}**

${summary}

## Read-only findings

$(printf '%s\n' "${findings[@]}")

## Not proved by this report

This check did not log in remotely, install software, inspect accounts or rooms,
change DNS or firewall rules, test ports from outside the network, validate
end-to-end encryption, perform a backup restore, or approve a deployment. Review
the pinned upstream prerequisites and the customer-owned acceptance record before
installation.
EOF
)"

printf '%s\n' "$report"

if [[ -n "$report_file" ]]; then
  report_parent="$(dirname "$report_file")"
  mkdir -p "$report_parent"
  temporary_report="$(mktemp "${report_parent}/.private-client-room-preflight.XXXXXX")"
  trap '[[ -n "${temporary_report:-}" && -f "$temporary_report" ]] && rm -f -- "$temporary_report"' EXIT
  printf '%s\n' "$report" >"$temporary_report"
  chmod 600 "$temporary_report"
  mv -- "$temporary_report" "$report_file"
  temporary_report=""
  printf 'Saved mode-600 report to %s\n' "$report_file" >&2
fi
