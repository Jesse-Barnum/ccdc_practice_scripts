#!/usr/bin/env bash
# Standalone Linux CCDC inject menu.
#
# Embedded injects:
#   1. banner.sh
#   2. clamav.sh
#   3. rdp.sh
#   4. wazuh.sh
#   5. wazuh_dashboard.sh
#
# The original inject behavior is retained, while package installation is
# routed through the detected distro's package manager.

set -Eeuo pipefail

DRY_RUN=0
LIST_ONLY=0
INJECT_NUMBER=0
WAZUH_MANAGER_IP=''
TARGET_IP=''
DISTRO_ID='unknown'
DISTRO_LIKE=''
DISTRO_NAME='unknown'
DISTRO_FAMILY='unknown'
PACKAGE_MANAGER='unknown'

usage() {
    cat <<'USAGE'
Usage: linux-inject-menu.sh [options]

Options:
  --list                    List injects and exit
  --inject NUMBER           Run one inject without prompting
  --dry-run                 Show intended actions without changing the host
  --wazuh-manager-ip IP     Supply the Wazuh Manager IP
  --target-ip IP            Supply the source IP allowed for RDP
  -h, --help                Show this help
USAGE
}

die() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

detect_platform() {
    if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO_ID=$(awk -F= '$1 == "ID" { gsub(/"/, "", $2); print $2 }' /etc/os-release)
        DISTRO_LIKE=$(awk -F= '$1 == "ID_LIKE" { gsub(/"/, "", $2); print $2 }' /etc/os-release)
        DISTRO_NAME=$(awk -F= '$1 == "PRETTY_NAME" { sub(/^[^=]*=/, ""); gsub(/"/, "", $0); print }' /etc/os-release)
    fi

    case "$DISTRO_ID $DISTRO_LIKE" in
        *debian*|*ubuntu*|*mint*|*kali*) DISTRO_FAMILY='debian' ;;
        *rhel*|*fedora*|*centos*|*rocky*|*alma*|*ol*) DISTRO_FAMILY='rhel' ;;
        *suse*) DISTRO_FAMILY='suse' ;;
        *arch*|*manjaro*) DISTRO_FAMILY='arch' ;;
        *alpine*) DISTRO_FAMILY='alpine' ;;
        *) DISTRO_FAMILY='unknown' ;;
    esac

    for candidate in apt-get dnf yum zypper pacman apk; do
        if command -v "$candidate" >/dev/null 2>&1; then
            PACKAGE_MANAGER=$candidate
            break
        fi
    done
}

is_root() {
    [[ "$(id -u)" -eq 0 ]]
}

require_root() {
    (( DRY_RUN == 1 )) && return 0
    is_root && return 0
    command -v sudo >/dev/null 2>&1 || die 'This inject requires root privileges and sudo is unavailable.'
}

run_root() {
    printf '+'
    printf ' %q' "$@"
    printf '\n'
    (( DRY_RUN == 1 )) && return 0
    if is_root; then
        "$@"
    else
        sudo "$@"
    fi
}

write_root_file() {
    local content=$1
    local target=$2
    printf 'write %s\n' "$target"
    (( DRY_RUN == 1 )) && return 0
    local temp_file
    temp_file=$(mktemp)
    printf '%s\n' "$content" > "$temp_file"
    if is_root; then
        install -m 0644 "$temp_file" "$target"
    else
        sudo install -m 0644 "$temp_file" "$target"
    fi
    rm -f "$temp_file"
}

package_install() {
    require_root
    case "$PACKAGE_MANAGER" in
        apt-get)
            run_root apt-get update
            run_root apt-get install -y "$@"
            ;;
        dnf) run_root dnf install -y "$@" ;;
        yum) run_root yum install -y "$@" ;;
        zypper) run_root zypper --non-interactive install --no-confirm "$@" ;;
        pacman) run_root pacman -Sy --noconfirm "$@" ;;
        apk) run_root apk add "$@" ;;
        *) die "Unsupported Linux package manager for $DISTRO_NAME." ;;
    esac
}

start_service() {
    local service=$1
    run_root systemctl enable --now "$service" || printf 'Warning: could not start %s\n' "$service" >&2
}

ensure_root_cron() {
    local job=$1
    require_root
    printf 'cron: %s\n' "$job"
    (( DRY_RUN == 1 )) && return 0

    local current temp_file
    if is_root; then
        current=$(crontab -l 2>/dev/null || true)
    else
        current=$(sudo crontab -l 2>/dev/null || true)
    fi
    if grep -Fqx "$job" <<< "$current"; then
        return 0
    fi

    temp_file=$(mktemp)
    printf '%s\n%s\n' "$current" "$job" > "$temp_file"
    if is_root; then
        crontab "$temp_file"
    else
        sudo crontab "$temp_file"
    fi
    rm -f "$temp_file"
}

install_login_banner() {
    require_root
    local banner_text
    banner_text=$(cat <<'BANNER'
******** WARNING ********
This system is the property of a private organization and is for authorized use only. By accessing this system, users agree to comply with the company's Acceptable Use Policy.

All activities on this system may be monitored, recorded, and disclosed to authorized personnel for security purposes. There is no expectation of privacy while using this system.

Unauthorized or improper use may result in disciplinary action or legal penalties. By continuing to use this system you indicate your awareness of and consent to these terms and conditions of use.

**************************
BANNER
)

    local file
    for file in /etc/issue /etc/motd /etc/issue.net /etc/login.warn; do
        if [[ -e "$file" ]]; then
            run_root cp "$file" "$file.bak"
        fi
    done
    for file in /etc/issue /etc/motd /etc/issue.net /etc/login.warn; do
        write_root_file "$banner_text" "$file"
    done
    printf 'Login banner installed successfully.\n'
}

install_clamav() {
    require_root
    printf 'Installing ClamAV for %s using %s...\n' "$DISTRO_NAME" "$PACKAGE_MANAGER"

    case "$DISTRO_FAMILY" in
        debian) package_install clamav clamav-daemon ;;
        rhel)
            if [[ "$DISTRO_ID" == 'rhel' || "$DISTRO_ID" == 'centos' || "$DISTRO_ID" == 'rocky' || "$DISTRO_ID" == 'almalinux' ]]; then
                package_install epel-release || true
            fi
            package_install clamav clamav-update clamav-scanner-systemd
            ;;
        suse) package_install clamav clamav-freshclam ;;
        arch) package_install clamav ;;
        alpine) package_install clamav clamav-daemon ;;
        *) die 'ClamAV is not mapped for this distro family.' ;;
    esac

    if command -v freshclam >/dev/null 2>&1; then
        run_root freshclam || true
    fi

    if [[ -f /etc/freshclam.conf ]]; then
        run_root sed -i 's/^Example/#Example/' /etc/freshclam.conf
    fi
    if [[ -f /etc/clamd.d/scan.conf ]]; then
        run_root sed -i 's/^Example/#Example/; s/^#LocalSocket /LocalSocket /' /etc/clamd.d/scan.conf
    fi

    case "$DISTRO_FAMILY" in
        debian) start_service clamav-daemon ;;
        rhel) start_service clamd@scan ;;
        alpine) start_service clamav-daemon ;;
    esac

    run_root mkdir -p /var/log/clamav
    local cron_job='*/30 * * * * /usr/bin/clamscan -r --log=/var/log/clamav/scan.log --exclude-dir="^/sys" --exclude-dir="^/proc" --exclude-dir="^/dev" /'
    ensure_root_cron "$cron_job"
    printf 'ClamAV installation and scheduled scan configuration complete.\n'
}

install_rdp() {
    require_root
    if [[ -z "$TARGET_IP" ]]; then
        read -r -p 'Enter the IP address to allow for RDP: ' TARGET_IP
    fi
    [[ "$TARGET_IP" =~ ^[0-9A-Fa-f:.]+$ ]] || die 'A valid IPv4 or IPv6 address is required.'

    case "$DISTRO_FAMILY" in
        debian) package_install xfce4 xfce4-goodies xrdp ;;
        rhel) package_install epel-release xfce4 xrdp ;;
        suse) package_install xfce4-session xrdp ;;
        arch) package_install xfce4 xfce4-goodies xrdp ;;
        *) die 'RDP package installation is not mapped for this distro family.' ;;
    esac

    local target_user home_dir
    target_user=''
    if [[ -n "${SUDO_USER-}" ]]; then target_user=$SUDO_USER; else target_user=$(id -un); fi
    home_dir=$(getent passwd "$target_user" | cut -d: -f6 || true)
    [[ -n "$home_dir" ]] || home_dir=$HOME
    write_root_file 'xfce4-session' "$home_dir/.xsession"
    run_root systemctl restart xrdp

    if command -v firewall-cmd >/dev/null 2>&1; then
        run_root firewall-cmd --permanent --add-rich-rule "rule family=ipv4 source address=$TARGET_IP/32 port port=3389 protocol=tcp accept"
        run_root firewall-cmd --reload
    elif command -v ufw >/dev/null 2>&1; then
        run_root ufw allow from "$TARGET_IP" to any port 3389 proto tcp
    elif command -v iptables >/dev/null 2>&1; then
        run_root iptables -A INPUT -s "$TARGET_IP/32" -p tcp --dport 3389 -j ACCEPT
    else
        printf 'Warning: no supported firewall command found; add the RDP rule manually.\n' >&2
    fi
    printf 'RDP service configured for source %s.\n' "$TARGET_IP"
}

install_wazuh_agent() {
    require_root
    if [[ -z "$WAZUH_MANAGER_IP" ]]; then
        read -r -p 'Enter the Wazuh Manager IP address: ' WAZUH_MANAGER_IP
    fi
    [[ -n "$WAZUH_MANAGER_IP" ]] || die 'No Wazuh Manager IP was provided.'

    if (( DRY_RUN == 1 )); then
        printf 'DRY RUN: would install Wazuh Agent 4.7.2-1 for %s on %s using %s, then enable wazuh-agent.\n' \
            "$DISTRO_NAME" "$WAZUH_MANAGER_IP" "$PACKAGE_MANAGER"
        return 0
    fi

    local key_file repo_text
    case "$DISTRO_FAMILY" in
        debian)
            package_install curl gnupg apt-transport-https
            key_file=$(mktemp)
            curl -fsSL https://packages.wazuh.com/key/GPG-KEY-WAZUH -o "$key_file"
            run_root gpg --dearmor --yes -o /usr/share/keyrings/wazuh.gpg "$key_file"
            rm -f "$key_file"
            repo_text='deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main'
            write_root_file "$repo_text" /etc/apt/sources.list.d/wazuh.list
            run_root apt-get update
            run_root env WAZUH_MANAGER="$WAZUH_MANAGER_IP" apt-get install -y --allow-downgrades wazuh-agent=4.7.2-1
            ;;
        rhel)
            run_root rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
            repo_text=$(cat <<'REPO'
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=Wazuh repository
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
REPO
)
            write_root_file "$repo_text" /etc/yum.repos.d/wazuh.repo
            if [[ "$PACKAGE_MANAGER" == 'dnf' ]]; then
                run_root env WAZUH_MANAGER="$WAZUH_MANAGER_IP" dnf install -y wazuh-agent-4.7.2-1
            else
                run_root env WAZUH_MANAGER="$WAZUH_MANAGER_IP" yum install -y wazuh-agent-4.7.2-1
            fi
            ;;
        *) die 'Wazuh Agent is currently mapped for Debian/Ubuntu and RHEL-family distributions.' ;;
    esac

    start_service wazuh-agent
    printf 'Wazuh Agent installation and service startup complete.\n'
}

install_wazuh_dashboard() {
    require_root
    case "$DISTRO_FAMILY" in
        debian) package_install curl tar gnupg ;;
        rhel|suse|arch|alpine) package_install curl tar ;;
        *) die 'Wazuh Manager installation is not mapped for this distro family.' ;;
    esac

    local installer='wazuh-install.sh'
    local log_file='wazuh_install_log.txt'
    printf 'Downloading Wazuh Manager installer...\n'
    if (( DRY_RUN == 1 )); then
        printf '+ curl -fsSL -o %q https://packages.wazuh.com/4.7/wazuh-install.sh\n' "$installer"
        printf '+ bash %q -a -i | tee %q\n' "$installer" "$log_file"
        return 0
    fi
    curl -fsSL -o "$installer" https://packages.wazuh.com/4.7/wazuh-install.sh
    chmod 700 "$installer"
    if is_root; then
        bash "$installer" -a -i | tee "$log_file"
    else
        sudo bash "$installer" -a -i | tee "$log_file"
    fi

    if systemctl is-active --quiet wazuh-manager; then
        printf 'SUCCESS: Wazuh Manager is running.\n'
    else
        printf 'WARNING: Wazuh Manager is not active; review %s.\n' "$log_file" >&2
        systemctl status wazuh-manager --no-pager || true
    fi
    printf 'Allow Wazuh ports 443, 1514, and 1515 through the host firewall.\n'
}

show_menu() {
    printf '\nLinux CCDC Injects - %s (%s, %s)\n' "$DISTRO_NAME" "$DISTRO_FAMILY" "$PACKAGE_MANAGER"
    printf '%s\n' '================================================'
    printf '[1] Install Linux login banner\n'
    printf '[2] Install and configure ClamAV\n'
    printf '[3] Install XRDP and allow one source IP\n'
    printf '[4] Install Wazuh Agent\n'
    printf '[5] Install Wazuh Manager/dashboard\n'
    printf '[Q] Quit\n\n'
}

invoke_selected() {
    case "$1" in
        1) install_login_banner ;;
        2) install_clamav ;;
        3) install_rdp ;;
        4) install_wazuh_agent ;;
        5) install_wazuh_dashboard ;;
        *) die "Unknown Linux inject: $1" ;;
    esac
}

while (($# > 0)); do
    case "$1" in
        --list) LIST_ONLY=1; shift ;;
        --dry-run) DRY_RUN=1; shift ;;
        --inject) (($# >= 2)) || die '--inject requires a number'; INJECT_NUMBER=$2; shift 2 ;;
        --wazuh-manager-ip) (($# >= 2)) || die '--wazuh-manager-ip requires an IP'; WAZUH_MANAGER_IP=$2; shift 2 ;;
        --target-ip) (($# >= 2)) || die '--target-ip requires an IP'; TARGET_IP=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

detect_platform
if (( LIST_ONLY == 1 )); then
    show_menu
    exit 0
fi

if (( INJECT_NUMBER == 0 )); then
    while :; do
        show_menu
        read -r -p 'Select an inject number: ' answer || exit 0
        [[ "$answer" =~ ^[qQ]$ ]] && exit 0
        if [[ "$answer" =~ ^[1-5]$ ]]; then
            INJECT_NUMBER=$answer
            break
        fi
        printf 'Invalid selection.\n' >&2
    done
fi

[[ "$INJECT_NUMBER" =~ ^[1-5]$ ]] || die 'Inject number must be between 1 and 5.'
invoke_selected "$INJECT_NUMBER"
