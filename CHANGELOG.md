# Changelog

All notable changes to the **MT7663 Router Web UI** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.5] - 2026-11-07

### Fixed
- **Eliminated Kernel `rtnl_lock` Deadlock (`hostapd-mt7663.conf`, `mt7663-hotspot.service` & `mt7663-hotspot`)**:
  - Removed `country_code=ID` and `ieee80211d=1` from `hostapd-mt7663.conf`. MediaTek MT7663 driver cannot handle userspace Netlink regulatory domain requests on modern Linux (6.18+), which previously locked `rtnl_lock` indefinitely in uninterruptible sleep (`D-state`) and froze network/console/SSH sequences.
  - Removed redundant `iw reg set ID` commands from `mt7663-hotspot.service` and `/usr/sbin/mt7663-hotspot`.
  - Regulatory domain is now cleanly handled by hardware NVRAM/EEPROM without userspace netlink interference.
- **Eliminated Package Collision with `mt7663-dkms`**:
  - Removed duplicate `/etc/NetworkManager/conf.d/99-mt7663-unmanaged-ap0.conf` from this package, resolving `dpkg: error: trying to overwrite ... which is also in package mt7663-dkms`.
- **Non-Blocking Post-Installation (`debian/postinst`)**:
  - Conditioned `systemctl restart mt7663-hotspot.service` during package installation to only execute if `ap0` is already present.
  - On fresh installs prior to reboot, hotspot service is enabled for next boot while only `mt7663-webui.service` is started immediately, completely eliminating the 50-second freeze at 93% progress.
- **Dedicated DBDC AP Isolation (`mt7663-hotspot`)**:
  - Removed destructive `wlan0` fallback and config file mutation (`sed -i ... interface=wlan0`) in `/usr/sbin/mt7663-hotspot`.
  - SoftAP strictly binds to `ap0`, preventing race conditions, IP flushing, and disconnections on active client interface `wlan0`.
- **CPU Governor Sweet Spot Baseline (`mt7663-hotspot`)**:
  - Explicitly enforced `ondemand` governor and 1.0 GHz minimum frequency (`scaling_min_freq = 1000000`) across all CPU cores prior to tuning sampling rate.
- **Pre-daemon Clean Startup & Enhanced Diagnostics**:
  - Moved stale process termination (`hostapd`, `dnsmasq`) and socket deletion to the start of `start_hotspot()`.
  - Added `export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"` and automated `rfkill unblock all`.
  - Replaced rigid 1-second check with a 6-second hostapd PID polling loop and stderr log diagnostics.
- **Systemd Unit Decoupling (`mt7663-hotspot.service`)**:
  - Removed obsolete device dependency `sys-subsystem-net-devices-ap0.device` from `After=` to allow reliable standalone boot without LAN.
  - Added module pre-load `ExecStartPre=-/sbin/modprobe wlan_mt7663_sdio ap_mode=1`.

---

## [1.0.4] - 2026-11-03

### Fixed
- **Python 3.13 / Debian 13 (Trixie) Compatibility**:
  - Upgraded embedded WSGI micro-framework `bottle.py` from v0.12.25 to **v0.13.2**.
  - Resolves fatal `ModuleNotFoundError: No module named 'cgi'` caused by the PEP 594 removal of the deprecated `cgi` module in Python 3.13.
  - Improved `server.py` import error handling to output the explicit Python exception details.
- **Hotspot Daemon Hardening & SDIO Boot Enumeration**:
  - Added `-u root` parameter to `dnsmasq` invocation in `/usr/sbin/mt7663-hotspot` to prevent privilege drop and permission denied failures across varied base distributions.
  - Added driver auto-load (`modprobe wlan_mt7663_sdio`) and a 15-second interface detection loop in `start_hotspot()` to eliminate boot race conditions while SDIO hardware initializes.

---

## [1.0.3] - 2026-11-01

### Added
- **One-Click STB System Reboot (`/api/system/reboot`)**:
  - Added a dedicated reboot trigger button in the STB Status card with an interactive confirmation prompt.
  - Built an animated 45-second countdown progress bar overlay with automated reconnect and page reload once the STB finishes rebooting.
- **Configurable DHCP Lease Duration**:
  - Added a customizable DHCP Lease Time selector in the 5 GHz Hotspot settings (1h, 2h, 6h, 12h, 24h, 48h, 7d), replacing hardcoded configuration values.
- **Sequential IP Allocation Option (`--dhcp-sequential-ip`)**:
  - Added configurable IP distribution method in Web UI: choose between **Sequential** (allocating IPs in order immediately following the gateway) or **Random / Hash-based** (MAC hash-based).
- **Real-Time Lease Time Remaining Column**:
  - Added a dedicated **Lease Time** (`Sisa Sewa`) column in the connected clients table displaying dynamic remaining lease countdown for each leased IP.
- **Table Layout & Header Streamlining**:
  - Condensed `Device Name / Hostname` table header to simply `Hostname` for cleaner spacing and perfect responsiveness across mobile and desktop viewports.
- **Multi-Core Network Packet Steering (RPS & XPS)**:
  - Added automatic Receive Packet Steering (RPS) and Transmit Packet Steering (XPS) on interfaces `ap0` (Wi-Fi) and `eth0` (Ethernet WAN) targeting Cores 1, 2, and 3 (`rps_cpus = e`, `xps_cpus = e`), with `rps_flow_cnt = 4096` and `net.core.rps_sock_flow_entries = 32768`.
  - Load-balances incoming and outgoing packet routing symmetrically across all CPU cores, eliminating single-core bottlenecks on CPU 0.
- **Turbo DNS Cache (10,000 Entries) & Parallel Upstream Resolver**:
  - Activated local high-speed DNS proxy in `dnsmasq` with 10,000 RAM cache entries, sub-millisecond local response times, and `--all-servers` parallel querying across Cloudflare (1.1.1.1) and Google (8.8.8.8).
  - Isolated listener socket (`-i ap0 --bind-interfaces --listen-address="${AP_GATEWAY}"`) ensuring zero port 53 conflicts with host OS resolvers (e.g., `systemd-resolved` on `127.0.0.53`).
- **Google TCP BBR Congestion Control & FQ Queuing**:
  - Enabled kernel `bbr` TCP congestion control and `fq` pacing queue discipline via `/etc/sysctl.d/99-mt7663.conf`, minimizing packet latency and bufferbloat under full bandwidth saturation.
- **Conntrack Fast-Reap & Active Connections Telemetry**:
  - Accelerated kernel TCP dead connection cleanup (`time_wait = 30s`, `close_wait = 15s`, `fin_wait = 30s`) to prevent NAT connection table exhaustion.
  - Added live **Active Connections** (`Koneksi Aktif`) telemetry row in Card 4 (STB Status) displaying real-time connection count, maximum capacity (65,535), and utilization percentage.
- **CPU Governor Sweet Spot Tuning (Cooler Baseline & Low Jitter)**:
  - Tuned `ondemand` governor parameters (`sampling_rate=20000` / 20ms, `up_threshold=60`, `sampling_down_factor=2`, `io_is_busy=0`).
  - Allows CPU to rest stably at 1000 MHz (1.0 GHz) during idle to lower operating temperatures, while instantly bursting to 2.0 GHz within 0.02s during gaming or heavy network bursts.
- **Real-Time CPU Clock Frequency Telemetry**:
  - Replaced raw RAM megabytes in Card 4 with active live CPU clock frequency (`X.XX GHz`), providing immediate visibility into dynamic CPU governor scaling between 1.0 GHz idle and 1.9–2.0 GHz burst.
- **Automated Ophub Governor Persistence (`postinst` / `postrm`)**:
  - Integrated automated injection of `ondemand` sweet-spot parameters (`sampling_rate=20ms`, `up_threshold=60%`) directly into `/etc/custom_service/start_service.sh` during `.deb` package installation (`postinst`), with clean teardown on package removal (`postrm`). Guarantees cool ~50°C baseline temperatures across reboots on any Ophub Armbian build.

### Changed
- **Symmetrical Dashboard Card Balancing**:
  - Relocated the **Active NAT Sessions / Connections** telemetry row from Card 4 (Hotspot) to Card 3 (Internet WAN), balancing both Card 3 and Card 4 symmetrically with exactly 6 informative rows each.

### Fixed
- **Station Disconnect & OFFLINE Status Accuracy**:
  - Fixed logic flaw where an empty active station set (`active_wifi_stas`) evaluated to `True` (`not active_wifi_stas`), causing disconnected DHCP lease entries to falsely display with `CONNECTED` green status.
  - Wired real-time association check directly to kernel mac80211 station dump (`iw dev ap0 station dump`); stations absent from the dump are strictly assigned `OFFLINE` status with muted badge styling.
- **Active Clients Counter Accuracy**:
  - Fixed `client_count` in both Dashboard card and table header (`Perangkat Terhubung ( ... )`) to sum only stations actively associated with `status == "CONNECTED"`. Disconnected devices or stale lease entries no longer increment the active client counter.
- **Device Deletion & DHCP Release Reliability**:
  - Updated `/api/devices/delete` (🗑️ button) to remove MAC mappings from `mt7663-devices.json`, purge matching lease entries from `/var/lib/misc/dnsmasq.leases`, and flush kernel ARP cache (`ip neigh flush dev ap0`), removing the device instantly and permanently.
  - Revamped `/api/dhcp/release` (`♻️ Release DHCP`) to truncate lease files, flush ARP, terminate running `dnsmasq`, and cleanly spawn a fresh instance so in-memory DHCP cache is completely wiped.
- **Frontend Action Handlers & Settings Round-Trip**:
  - Implemented missing client-side JavaScript functions `flushDhcpLeases()` and `deleteDevice()` in `index.html` to ensure action buttons execute smoothly without DOM errors.
  - Included `dhcp_lease` duration and `dhcp_alloc` distribution method in settings save payload, ensuring full configuration round-trip synchronization between frontend and backend.
- **Authoritative DHCP Service Flag (`--dhcp-authoritative`)**:
  - Added `--dhcp-authoritative` to `dnsmasq` invocation in `/usr/sbin/mt7663-hotspot` to immediately reject foreign DHCP lease requests from mobile devices reconnecting after network restarts, forcing instant clean IP re-allocation.
- **Authentication Handshake Fix in Management Endpoints**:
  - Replaced undefined `check_auth()` calls in `/api/devices/rename`, `/api/devices/delete`, and `/api/dhcp/release` with proper `is_authenticated()` session checks, resolving HTTP 500 Internal Server Errors when modifying devices or releasing DHCP.

---

## [1.0.2] - 2026-11-01

### Added
- **Low-Latency Online Gaming Optimizations**:
  - **DTIM Period Tuning (`dtim_period=1`)**: Shortened beacon wake-up intervals from 200 ms to 100 ms in `hostapd-mt7663.conf`, eliminating micro-sleep buffering delays on mobile gaming clients.
  - **U-APSD Advertisement Disabled (`uapsd_advertisement_enabled=0`)**: Prevented WMM sleep buffer queuing jitter on modern smartphone wireless chipsets.
  - **Bufferbloat Mitigation (`fq_codel`)**: Automatically applied Fair Queueing Controlled Delay (`target 5ms interval 100ms noecn`) queue discipline on interface `ap0` during hotspot startup, prioritizing small UDP gaming packets over large TCP bulk transfers.
  - **CPU Governor Responsiveness Tuning**: Tuned kernel `ondemand` governor parameters (`up_threshold=25`, `sampling_down_factor=10`, `io_is_busy=1`) when hotspot activates to maintain steady processing frequencies and eliminate clock switching micro-jitter.
- **Client & Hostname Management**:
  - **Delete Device Action (🗑️)**: Added an explicit delete button next to hostname editing in the connected devices table, enabling instant removal of duplicate/stale entries caused by mobile MAC Randomization.
  - **API Endpoint (`/api/devices/delete`)**: Backend endpoint to cleanly remove cached MAC mappings from `/var/lib/misc/mt7663-devices.json`.
  - **Flush DHCP Leases Button (`♻️ Release DHCP`)**: Added a quick action button and backend endpoint (`/api/dhcp/release`) to flush inactive DHCP leases from `dnsmasq.leases`, freeing orphaned IP addresses immediately.
- **Admin Password Safety & Confirmation**:
  - Added a mandatory **Confirm New Password** field with real-time match validation (`checkPassMatch`) and backend validation to prevent accidental lockouts caused by typos.
  - Added automated session invalidation and re-login flow upon successful password modification.

### Changed
- **Client Status Accuracy**:
  - Replaced stale DHCP lease status assumptions with real-time station dump verification (`iw dev ap0 station dump`). Devices that disconnected or roamed to another Wi-Fi network are now marked as `OFFLINE` (with muted styling) instead of remaining misleadingly `ACTIVE`.
- **Table Column Headers**:
  - Simplified traffic table headers by removing redundant directional indicators: `Upload (UP)` -> `Upload` (`Unggah`), `Download (DOWN)` -> `Download` (`Unduh`).
- **Form Text & Localization**:
  - Removed confusing `Default: admin` placeholder in current password input; replaced with localized contextual prompts (`Enter current password` / `Ketik kata sandi saat ini`).
  - Standardized all admin form placeholders to fully respect active language selection.

## [1.0.1] - 2026-10-31

### Added
- **Full Bilingual Localization (ID / EN)**:
  - Translated all dropdown `<option>` selectors dynamically:
    - **Security Modes**: WPA2-Personal (AES/CCMP) [Recommended], WPA2/WPA3 Mixed, WPA3-Personal Only, and Open.
    - **Wireless Bands**: 2.4 GHz (Recommended for Repeater) and 5 GHz (High Speed LAN).
    - **5 GHz & 2.4 GHz Channels**: Channel 1–11, UNII-1 (Channels 36–48), and UNII-3 (Channels 149–161).
    - **Channel Widths**: 20 MHz, 40 MHz (HT40), and 80 MHz (VHT80).
    - **DNS Presets**: Cloudflare (Fastest & Privacy, Security Malware, Family), Google Public DNS, AdGuard (Anti-Ads, Family SafeSearch), Quad9 Phishing Protection, OpenDNS, and Custom manual configuration.
  - Translated all contextual guidance hints, the Repeater Mode Performance Warning box, and DoH / Private DNS tips.
  - Translated Wi-Fi connection modal dialogue, password placeholders, and "Forget Network" button.

### Changed
- **Dynamic Band Switching (`onBandChange`)**: Updated channel and bandwidth options rendering to respect active language while preserving currently selected form values.
- **Safe Hardware Installation (`postinst`)**: Removed aggressive live `modprobe -r wlan_mt7663_sdio` during package installation. On Amlogic SDIO controllers (`meson-gx-mmc`), on-the-fly driver unloading without physical power-cycling can freeze the MMC bus; the package now applies options gracefully and guides the user to reboot only when needed.

---

## [1.0.0] - 2026-10-31

### Added
- **Initial Standalone Release**: Decoupled Turnkey SoftAP Router & Management Web UI from the pure DKMS driver repository (`mt7663-driver`).
- **Zero-Dependency WSGI Web Dashboard**:
  - Built with Python 3 and embedded micro-framework (`bottle.py`).
  - Dark-mode responsive UI supporting desktop and mobile browsers.
  - Real-time STB telemetry: CPU load, SoC temperature (`amlogic_thermal`), RAM consumption, and uptime.
  - Live client table displaying connected MACs, IP leases, hostnames, and per-device TX/RX bandwidth.
  - Device friendly name alias persistence stored in `/etc/mt7663-device-names.json`.
- **Dedicated SoftAP Management Daemon (`mt7663-hotspot`)**:
  - Independent `hostapd` and `dnsmasq` instances dedicated strictly to the `ap0` virtual interface.
  - Isolated subnet on `10.10.10.1/24` with configurable DHCP range (`10.10.10.10`–`10.10.10.100`).
  - Automatic masking of Debian's system-wide `hostapd` and `dnsmasq` services to avoid port 53/67 binding conflicts.
- **Automated Routing & Internet Sharing**:
  - NetworkManager dispatcher script (`90-wlan0-routing.sh`) for automatic iptables NAT masquerade whenever `wlan0` or `eth0` comes UP.
  - Sysctl kernel optimizations (`99-mt7663.conf`) enabling IPv4 forwarding and ARP isolation (`arp_ignore=1`, `arp_announce=2`).
- **Interactive Wi-Fi Client Manager**:
  - Scan nearby 2.4 GHz and 5 GHz networks via `nmcli` with signal strength, channel, and security indicators.
  - One-click connect to open or saved networks without re-entering credentials.
  - Password modal for newly discovered secured networks with profile forget support.
- **Session Authentication & Security**:
  - Cookie-based session authentication with SHA-256 password hashing.
  - Default administrative credentials (`admin` / `admin`) with in-dashboard credential update.
- **Debian Packaging**:
  - Debian standard packaging (`dpkg-deb`) generating `mt7663-router-webui_1.0.0_all.deb`.
  - Automated systemd service integration (`mt7663-hotspot.service` and `mt7663-webui.service`).
  - MOTD login banner (`15-ap-info`) displaying hotspot status, SSID, and Web UI URL upon SSH login.
