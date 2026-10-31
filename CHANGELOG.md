# Changelog

All notable changes to the **MT7663 Router Web UI** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

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
