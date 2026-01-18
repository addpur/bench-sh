**Enhanced VPS Benchmark Script**

A modified and optimized version of the classic bench.sh script. This tool is designed to provide comprehensive system information, I/O performance metrics, and enhanced network diagnostics, including dual-stack (IPv4 & IPv6) detection and refined speedtest results.

**Credits & Original Source**

This script is an enhanced version based on the original work by Teddysun.

Original Author: [Teddysun](teddysun.com)

Original Repository: https://github.com/teddysun/across

**Key Enhancements**

* **Dual-Stack IP Detection**: Automatically identifies and displays both public IPv4 and IPv6 addresses.

* **Detailed Network Info**: Shows ISP and geographical location data for both IP versions using `ipinfo.io` and `ip-api.com`.

* **Clean UI Alignment**: All system and network information is perfectly aligned for better readability.

* **Optimized Speedtest**:  Expanded node name columns to support long server names.

  * **Extended Columns**: Expanded node name columns (35 characters) to support long server names without breaking the layout.

  * **Instant Results**: Removed artificial delays; results are displayed immediately after each test completes.

  * **Curated Nodes**: Includes stable global and local (Indonesia - Biznet, Telkom, CBN) speedtest nodes.
* **Robust Error Handling**: Specific reporting for network timeouts or empty API responses.

**Features**

* **System Overview**: CPU model, core count, OS, Architecture, Kernel version, RAM, Disk usage, and Virtualization type.

* **I/O Performance**: Measures disk write speeds using multiple dd runs.

* **Network Diagnostics**: Public IP addresses, ISP identification, and city/country location.

* **Global Speedtest**: Real-time upload and download speeds to various strategic locations worldwide.

**Installation & Usage**

To use this script, you need to download it and grant execution permissions. Use one of the following methods:

**Option 1: Using wget (Recommended)**

```
wget -qO bench.sh https://raw.githubusercontent.com/addpur/bench-sh/master/bench.sh
chmod +x bench.sh
./bench.sh
```


**Option 2: Using curl**

```
curl -Lso bench.sh https://raw.githubusercontent.com/addpur/bench-sh/master/bench.sh
chmod +x bench.sh
./bench.sh
```


**Direct Execution (One-liner)**

If you don't want to save the file locally:

```
wget -qO- https://raw.githubusercontent.com/addpur/bench-sh/master/bench.sh | bash
```

**Requirements**

The script is lightweight and relies on standard Linux utilities:

```bash ```<br>
```wget or curl ```<br>
```awk ``` <br>
```tar ```  (for speedtest binary extraction)

**Disclaimer**

This script is provided "as is" without any warranty. Use it at your own risk. Performance results may vary based on server load and network conditions at the time of testing.

_Modified with ❤️ for the VPS Community._