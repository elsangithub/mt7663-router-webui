# MT7663 Router Web UI & Turnkey SoftAP Hotspot

[![License](https://img.shields.io/badge/license-GPLv2-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Amlogic%20S905X2%20%7C%20HG680--FJ-orange.svg)]()
[![Debian](https://img.shields.io/badge/debian-Bookworm%20%7C%20Armbian-red.svg)]()
[![Version](https://img.shields.io/badge/version-1.0.1-green.svg)]()

A lightweight, zero-dependency WSGI management dashboard and turnkey SoftAP hotspot controller designed for the MediaTek **MT7663** SDIO Wi-Fi module on the **FiberHome HG680-FJ** (Amlogic S905X2 / Meson G12A) running Armbian Linux.

This package transforms your TV box into a standalone **Dual-Band Concurrent (DBDC) Wireless Repeater / Router** without requiring any external USB Wi-Fi dongles.

---

## 🌟 Key Features

* **DBDC Wireless Repeater (Dual AP/STA Mode)**:
  * Uses the dedicated virtual interface `ap0` for the SoftAP Hotspot while `wlan0` connects to your home Wi-Fi or acts as a client simultaneously.
  * Native 2.4 GHz (HT40) and 5 GHz (VHT80 866 Mbps) band support.
* **Zero-Dependency WSGI Dashboard**:
  * Written in pure Python 3 using an embedded micro-framework (`bottle.py`). No Node.js, npm, or heavy web server runtimes required.
  * Consumes under **25 MB RAM**, ideal for minimal TV box environments.
* **Full Bilingual Support (English & Bahasa Indonesia)**:
  * Instant, one-click language toggle in the navigation bar.
  * Every dropdown menu, status badge, channel list, and security parameter is fully localized.
* **Isolated Hotspot Stack**:
  * Dedicated `hostapd` and `dnsmasq` instances specifically bound to `ap0` (`10.10.10.1/24`).
  * System-wide daemons are safely masked to prevent port 53/67 binding conflicts with upstream DNS resolvers.
* **Live Hardware & Traffic Telemetry**:
  * Real-time SoC temperature monitoring from Amlogic thermal zones (`/sys/class/thermal/thermal_zone0/temp`).
  * Live client device table displaying MAC, assigned IP, hostname, custom device alias, and real-time per-client upload/download bandwidth.
* **Automated NAT & Routing Dispatcher**:
  * Automatic `iptables` NAT masquerade triggered via NetworkManager dispatcher whenever `wlan0` or `eth0` goes UP.
  * Sysctl kernel optimizations for IPv4 forwarding and ARP isolation (`arp_ignore=1`, `arp_announce=2`).

---

## 📐 Network Architecture

```
                 +-----------------------------------------------+
                 |        FiberHome HG680-FJ (Amlogic S905X2)    |
                 |                                               |
[ Home Router ] <==== [wlan0 (STA)]                 [ap0 (AP)] ====> [ Phones / Laptops ]
 (Internet WAN)  |      DHCP Client                 10.10.10.1   |    (Hotspot Clients)
                 |           \                           /       |
                 |            +--- iptables NAT (MASQ) -+        |
                 |            |    IPv4 Forwarding = 1  |        |
                 |            |    Isolated dnsmasq     |        |
                 |            +-------------------------+        |
                 |            |   WSGI Dashboard :8080  |        |
                 +------------+-------------------------+--------+
```

---

## 📋 Prerequisites

Before installing this package, ensure you have installed the pure DKMS driver:

1. **Kernel Driver**: [`mt7663-dkms`](https://github.com/elsangithub/mt7663-driver) (version `1.0.8-rc5` or higher).
2. **Operating System**: Armbian (Debian 12 Bookworm / Linux Kernel 6.18+ recommended).

---

## 🚀 Installation

### 1. Install via APT

Download the latest `.deb` package and install it using `apt` so that all required runtime dependencies (`hostapd`, `dnsmasq`, `python3`, `iptables`, `wireless-tools`) are automatically resolved:

```bash
sudo apt update
sudo apt install ./mt7663-router-webui_1.0.1_all.deb
```

### 2. Activate Dual AP/STA Mode

On the first installation, reboot your STB to allow the Amlogic SDIO bus controller to perform a clean hardware reset with `ap_mode=1`:

```bash
sudo reboot
```

After reboot, verify both interfaces are present:
```bash
ip link show wlan0
ip link show ap0
```

---

## 🖥️ Accessing the Web Dashboard

1. Connect your phone or laptop to the default Wi-Fi hotspot:
   * **SSID**: `MT7663-Hotspot` (or `HG680_5G_VHT80`)
   * **Password**: `password123`
2. Open your web browser and navigate to:
   * **URL**: [`http://10.10.10.1:8080`](http://10.10.10.1:8080)
   * *(Alternatively, access via your STB's Ethernet IP at `http://<STB-LAN-IP>:8080`)*
3. Log in with the default administrator credentials:
   * **Username**: `admin`
   * **Password**: `admin`

> [!TIP]
> You can change the admin username and password anytime in the **Admin** tab.

---

## ⚙️ Configuration Files

The package manages its configurations through standard Linux configuration paths:

| File Path | Description |
| :--- | :--- |
| `/etc/default/mt7663-hotspot` | Hotspot environment settings (SSID, channel, band, gateway IP, DHCP range, DNS servers). |
| `/etc/hostapd/hostapd-mt7663.conf` | Hostapd runtime template generated automatically by the hotspot service. |
| `/etc/modprobe.d/wlan_mt7663_sdio.conf` | Driver module options setting `ap_mode=1` for dual virtual interface initialization. |
| `/etc/sysctl.d/99-mt7663.conf` | Kernel IP forwarding and ARP isolation parameters. |
| `/etc/NetworkManager/dispatcher.d/90-wlan0-routing.sh` | Dispatcher hook that automatically updates iptables NAT whenever WAN connects. |
| `/etc/mt7663-device-names.json` | Stores custom friendly names assigned to client devices in the Web UI. |

---

## 📡 Best Practices for Wireless Repeater Mode

When using the STB to receive Wi-Fi on `wlan0` and re-broadcast via `ap0` (Repeater Mode), adhere to the following frequency allocation:

* **Recommended (True DBDC)**:
  * Connect **`wlan0`** to your Home Wi-Fi on **5 GHz** (e.g. Channel 36 or 149).
  * Configure the **`ap0`** Hotspot on **2.4 GHz** (Channel 6, 40 MHz).
  * *Reason*: The MT7663 contains dedicated independent 2.4 GHz and 5 GHz baseband radios. Using opposing bands ensures zero airtime contention and maximum throughput.
* **If both interfaces must use 5 GHz**:
  * Set both `wlan0` and `ap0` to the same channel frequency to minimize time-slicing packet drops.

---

## 🗑️ Uninstallation

To cleanly remove the Web UI and restore the system to a pure `wlan0` Wi-Fi client state:

```bash
# 1. Purge the package and configurations
sudo apt purge -y mt7663-router-webui

# 2. Clean up auto-installed dependencies
sudo apt autoremove -y --purge

# 3. Reboot to restore clean single-interface mode
sudo reboot
```

---

## 📄 License

This project is licensed under the **GNU General Public License v2.0**.
