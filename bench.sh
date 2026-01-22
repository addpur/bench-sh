#!/usr/bin/env bash
#
# Description: Enhanced Bench Script (Original by Teddysun) https://raw.githubusercontent.com/teddysun/across/refs/heads/master/bench.sh
# Modified by Add
#
trap _exit INT QUIT TERM

_red() { printf '\033[0;31;31m%b\033[0m' "$1"; }
_green() { printf '\033[0;31;32m%b\033[0m' "$1"; }
_yellow() { printf '\033[0;31;33m%b\033[0m' "$1"; }
_blue() { printf '\033[0;31;36m%b\033[0m' "$1"; }

_exists() {
    local cmd="$1"
    if eval type type >/dev/null 2>&1; then eval type "$cmd" >/dev/null 2>&1
    elif command >/dev/null 2>&1; then command -v "$cmd" >/dev/null 2>&1
    else which "$cmd" >/dev/null 2>&1; fi
}

_exit() {
    _red "\nScript stopped. Cleaning up files....\n"
    rm -fr speedtest.tgz speedtest-cli benchtest_*
    exit 1
}

get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print $0}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

next() { printf "%-70s\n" "-" | sed 's/\s/-/g'; }
speed_test() {
    local nodeName="$2"
    local serverId="$1"
    printf " %-45s" "${nodeName}"

    if [ -z "$serverId" ]; then
        ./speedtest-cli/speedtest --progress=no --accept-license --accept-gdpr >./speedtest-cli/speedtest.log 2>&1
    else
        ./speedtest-cli/speedtest --progress=no --server-id="$serverId" --accept-license --accept-gdpr >./speedtest-cli/speedtest.log 2>&1
    fi

    if [ $? -eq 0 ]; then
        local dl=$(awk '/Download:/{print $2" "$3}' ./speedtest-cli/speedtest.log)
        local up=$(awk '/Upload:/{print $2" "$3}' ./speedtest-cli/speedtest.log)
        local lat=$(awk '/Latency:/{print $2" "$3}' ./speedtest-cli/speedtest.log)
        
        if [[ -n "$dl" && -n "$up" ]]; then
            printf "\033[0;32m%-18s\033[0;31m%-20s\033[0;36m%-12s\033[0m\n" "${up}" "${dl}" "${lat}"
        else
            printf "\033[0;31m%-50s\033[0m\n" "Failed (Result Empty)"
        fi
    else
        local err_msg=$(grep -iE "error|failed|timeout" ./speedtest-cli/speedtest.log | head -n 1 | cut -c 1-45)
        if [ -z "$err_msg" ]; then err_msg="Failed / Timeout"; fi
        printf "\033[0;31m%-50s\033[0m\n" "$err_msg"
    fi
}

speed() {
    printf " %-19s %b\n" "Test internet with Speedtest"
    printf " \033[1;34m%-45s %-18s %-18s %-12s\033[0m\n" "Node Name" "Upload Speed" "Download Speed" "Latency"
    
    speed_test '' 'Default (Auto)'
    speed_test '797' 'Jakarta, ID (Biznet)'
    speed_test '7582' 'Jakarta, ID (Telkom)'
    speed_test '42688' 'Singapore, SG (XLSMART Telecom)'
    speed_test '13623' 'Singapore, SG (Singtel)'
    speed_test '35180' 'Seattle, US (Ziply Fiber)'
    speed_test '53393' 'Toronto, CN (Bell Canada)'
    speed_test '62473' 'Vilnius, LN (UAB DELSKA Lithuania)'
    speed_test '36998' 'Amsterdam, NL (RETN)'
    speed_test '43356' 'Hongkong, CN (1010)'
    speed_test '50686' 'Tokyo, JP (GSL Networks)'
}

io_test() {
    (LANG=C dd if=/dev/zero of=benchtest_$$ bs=512k count="$1" conv=fdatasync && rm -f benchtest_$$) 2>&1 | awk -F '[,，]' '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}

calc_size() {
    local raw=$1
    local total_size=0; local num=1; local unit="KB"
    if ! [[ ${raw} =~ ^[0-9]+$ ]]; then echo ""; return; fi
    if [ "${raw}" -ge 1073741824 ]; then num=1073741824; unit="TB"
    elif [ "${raw}" -ge 1048576 ]; then num=1048576; unit="GB"
    elif [ "${raw}" -ge 1024 ]; then num=1024; unit="MB"
    elif [ "${raw}" -eq 0 ]; then echo "0"; return; fi
    total_size=$(awk 'BEGIN{printf "%.1f", '"$raw"' / '$num'}')
    echo "${total_size} ${unit}"
}

to_kibyte() { awk 'BEGIN{printf "%.0f", '"$1"' / 1024}'; }
calc_sum() { local s=0; for i in "$@"; do s=$((s + i)); done; echo ${s}; }

check_virt() {
    virt="Dedicated"
    if [ -f /proc/user_beancounters ]; then virt="OpenVZ"
    elif [ -d /proc/vz ]; then virt="OpenVZ"
    elif grep -qa docker /proc/1/cgroup; then virt="Docker"
    elif grep -qa lxc /proc/1/cgroup; then virt="LXC"
    elif [ -f /sys/hypervisor/type ] && grep -q "xen" /sys/hypervisor/type; then virt="Xen"
    elif [ -d /sys/devices/virtual/dmi/id ]; then
        sys_manu=$(cat /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null)
        if [[ "${sys_manu}" == *"QEMU"* || "${sys_manu}" == *"KVM"* ]]; then virt="KVM"
        elif [[ "${sys_manu}" == *"VMware"* ]]; then virt="VMware"
        elif [[ "${sys_manu}" == *"VirtualBox"* ]]; then virt="VirtualBox"
        fi
    fi
}

ip_info() {
    local ipv4=$(curl -s4 -m 5 https://icanhazip.com || echo "N/A")
    local ipv6=$(curl -s6 -m 5 https://icanhazip.com || echo "N/A")
    printf " %-19s: %b\n" "IP Address IPv4" "$(_blue "$ipv4")"
    if [ "$ipv4" != "N/A" ]; then
        local info=$(curl -s -m 5 https://ipinfo.io/$ipv4/json)
        local isp=$(echo $info | grep -oP '(?<="org": ")[^"]*')
        local loc=$(echo $info | grep -oP '(?<="city": ")[^"]*'), $(echo $info | grep -oP '(?<="country": ")[^"]*')
        printf " %-19s: %b\n" "ISP IPv4" "$(_yellow "$isp")"
        printf " %-19s: %b\n" "Location IPv4" "$(_blue "$loc")"
    fi

    printf " %-19s: %b\n" "IP Address IPv6" "$(_blue "$ipv6")"
    if [ "$ipv6" != "N/A" ]; then
        local info6=$(curl -s -m 5 "https://ipapi.co/$ipv6/json/")
        local isp6=$(echo $info6 | grep -oP '(?<="org": ")[^"]*')
        printf " %-19s: %b\n" "ISP IPv6" "$(_yellow "$isp6")"
    fi
}

install_speedtest() {
    if [ ! -e "./speedtest-cli/speedtest" ]; then
        sys_bit=""
        local sysarch
        sysarch="$(uname -m)"
        if [ "${sysarch}" = "unknown" ] || [ "${sysarch}" = "" ]; then
            sysarch="$(arch)"
        fi
        if [ "${sysarch}" = "x86_64" ]; then
            sys_bit="x86_64"
        fi
        if [ "${sysarch}" = "i386" ] || [ "${sysarch}" = "i686" ]; then
            sys_bit="i386"
        fi
        if [ "${sysarch}" = "armv8" ] || [ "${sysarch}" = "armv8l" ] || [ "${sysarch}" = "aarch64" ] || [ "${sysarch}" = "arm64" ]; then
            sys_bit="aarch64"
        fi
        if [ "${sysarch}" = "armv7" ] || [ "${sysarch}" = "armv7l" ]; then
            sys_bit="armhf"
        fi
        if [ "${sysarch}" = "armv6" ]; then
            sys_bit="armel"
        fi
        [ -z "${sys_bit}" ] && _red "Error: Unsupported system architecture (${sysarch}).\n" && exit 1
        url1="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-${sys_bit}.tgz"
        url2="https://dl.lamp.sh/files/ookla-speedtest-1.2.0-linux-${sys_bit}.tgz"
        if ! wget --no-check-certificate -q -T10 -O speedtest.tgz ${url1}; then
            if ! wget --no-check-certificate -q -T10 -O speedtest.tgz ${url2}; then
                _red "Error: Failed to download speedtest-cli.\n" && exit 1
            fi
        fi
        mkdir -p speedtest-cli && tar zxf speedtest.tgz -C ./speedtest-cli && chmod +x ./speedtest-cli/speedtest
        rm -f speedtest.tgz
    fi
}

get_system_info() {
    cname=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
    cores=$(awk -F: '/^processor/ {core++} END {print core}' /proc/cpuinfo)
    tram=$(free | awk '/Mem/ {print $2}'); tram=$(calc_size "$tram")
    uram=$(free | awk '/Mem/ {print $3}'); uram=$(calc_size "$uram")
    up=$(awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days, %d hour %d min\n",a,b,c)}' /proc/uptime)
    opsy=$(get_opsy)
    arch=$(uname -m)
    kern=$(uname -r)
    disk_total=$(df -h / | awk 'NR==2 {print $2}')
    disk_used=$(df -h / | awk 'NR==2 {print $3}')
    tcpctrl=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
    ccache=$(awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//')
    cpu_aes=$(grep -i 'aes' /proc/cpuinfo)
    cpu_virt=$(grep -Ei 'vmx|svm' /proc/cpuinfo)
    uswap=$(
        LANG=C
        free | awk '/Swap/ {print $3}'
    )
    uswap=$(calc_size "$uswap")
    if _exists "w"; then
        load=$(
            LANG=C
            w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//'
        )
    elif _exists "uptime"; then
        load=$(
            LANG=C
            uptime | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//'
        )
    fi
}

print_system_info() {
    printf " %-19s: %b\n" "System uptime      " "$(_blue "$up")"
    printf " %-19s: %b\n" "Load average       " "$(_blue "$load")"
    printf " %-19s: %b\n" "CPU Model          " "$(_blue "$cname")"
    printf " %-19s: %b\n" "CPU Cores          " "$(_blue "$cores")"
    printf " %-19s: %b\n" "CPU Cache          " "$(_blue "$ccache")"
    printf " %-19s: %b\n" "AES-NI             " "$(_green "\xe2\x9c\x93 Enabled")"
    if [ -n "$cpu_virt" ]; then
        printf " %-19s: %b\n" "VM-x/AMD-V         " "$(_green "\xe2\x9c\x93 Enabled")"
    else
        printf " %-19s: %b\n" "VM-x/AMD-V         " "$(_red "\xe2\x9c\x97 Disabled")"
    fi
    printf " %-19s: %b\n" "OS                 " "$(_blue "$opsy")"
    printf " %-19s: %b\n" "Arch               " "$(_blue "$arch")"
    printf " %-19s: %b\n" "Kernel             " "$(_blue "$kern")"
    printf " %-19s: %b\n" "Total RAM          " "$(_yellow "$tram")($uram Used)"
    printf " %-19s: %b\n" "Total Swap         " "$(_blue "$swap($uswap Used)")"
    printf " %-19s: %b\n" "Total Disk         " "$(_yellow "$disk_total") ($disk_used Used)"
    printf " %-19s: %b\n" "TCP CC             " "$(_yellow "$tcpctrl")"
    printf " %-19s: %b\n" "Virtualization     " "$(_blue "$virt")"
}

print_end_time() {
    end_time=$(date +%s)
    time=$((end_time - start_time))
    if [ ${time} -gt 60 ]; then
        min=$((time / 60))
        sec=$((time % 60))
        printf " %-19s: %b\n" "Finished in        " "${min} min ${sec} sec"
    else
        printf " %-19s: %b\n" "Finished in        " "${time} sec"
    fi
    date_time=$(date '+%Y-%m-%d %H:%M:%S %Z')
    printf " %-19s: %b\n" "Timestamp          " "$date_time"
}

# Main Execution
clear
start_time=$(date +%s)
echo "-------------------- Bench.sh Enhanced Version -------------------"
get_system_info
check_virt
print_system_info
next
ip_info
next
printf " %-19s %b\n" "Calculating Speed I/O..."
io1=$(io_test 2048); printf " %-19s: %b\n" "I/O Speed (1st)    " "$(_yellow "$io1")"
io2=$(io_test 2048); printf " %-19s: %b\n" "I/O Speed (2nd)    " "$(_yellow "$io2")"
io3=$(io_test 2048); printf " %-19s: %b\n" "I/O Speed (3nd)    " "$(_yellow "$io3")"
io4=$(io_test 2048); printf " %-19s: %b\n" "I/O Speed (4nd)    " "$(_yellow "$io4")"
io5=$(io_test 2048); printf " %-19s: %b\n" "I/O Speed (5nd)    " "$(_yellow "$io5")"
next
install_speedtest
speed
rm -rf speedtest-cli
next
print_end_time
next