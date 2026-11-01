# Changelog

All notable changes to the **MT7663 Router Web UI** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
- **CPU Governor Sweet Spot Tuning (Cooler Baseline & Low Jitter)**:
  - Tuned `ondemand` governor parameters (`sampling_rate=20000` / 20ms, `up_threshold=60`, `sampling_down_factor=2`, `io_is_busy=0`).
  - Allows CPU to rest stably at 1000 MHz (1.0 GHz) during idle to lower operating temperatures, while instantly bursting to 2.0 GHz within 0.02s during gaming or heavy network bursts.

### Fixed
- **Station Disconnect & OFFLINE Status Accuracy**:
  - Fixed logic flaw where an empty active station set (`active_wifi_stas`) evaluated to `True` (`not active_wifi_stas`), causing disconnected DHCP lease entries to falsely display with `CONNECTED` green status.
  - Wired real-time association check directly to kernel mac80211 station dump (`iw dev ap0 station dump`); stations absent from the dump are strictly assigned `OFFLINE` status with muted badge styling.
- **Active Clients Counter Accuracy**:
  - Fixed `client_count` in both Dashboard card and table header (`Perangkat Terhubung ( ... )`) to sum only stations actively associated with `status == "CONNECTED"`. Disconnected devices or stale lease entries no longer increment the active client counter.
- **Device Deletion & DHCP Release Reliability**:
  - Updated `/api/devices/delete` (🗑️ button) to remove MAC mappings from `mt7663-devices.json`, purge matching lease entries from `/var/lib/misc/dnsmasq.leases`, and flush kernel ARP cache (`ip neigh flush dev ap0`), removing the device instantly and permanently.
  - Revamped `/api/dhcp/release` (`♻️ Release DHCP`) to truncate lease files, flush ARP, terminate running `dnsmasq`, and cleanly spawn a fresh instance so in-memory DHCP cache is completely wiped.
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
