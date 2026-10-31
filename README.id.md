<p align="right">
  <a href="README.md">English</a> | <b>Bahasa Indonesia</b>
</p>

# MT7663 Router Web UI & Turnkey SoftAP Hotspot (Panduan Bahasa Indonesia)

[![Rilis](https://img.shields.io/github/v/release/elsangithub/mt7663-router-webui?color=blue&label=rilis)](https://github.com/elsangithub/mt7663-router-webui/releases)
[![Build](https://img.shields.io/github/actions/workflow/status/elsangithub/mt7663-router-webui/release.yml?branch=main&label=build)](https://github.com/elsangithub/mt7663-router-webui/actions)
[![Platform](https://img.shields.io/badge/Platform-FiberHome%20HG680--FJ%20(S905X2)-orange.svg)]()
[![OS](https://img.shields.io/badge/OS-Armbian%20Linux%206.18%2B%20(Ophub)-blue.svg)]()
[![Paket](https://img.shields.io/badge/Paket-Debian%2012%20(Bookworm)-red.svg)]()
[![Lisensi: GPL-2.0](https://img.shields.io/badge/Lisensi-GPL_2.0-blue.svg)](LICENSE)

Dashboard web manajemen router WSGI yang sangat ringan (tanpa dependensi berat) dan pengendali SoftAP hotspot terintegrasi khusus untuk modul Wi-Fi **MediaTek MT7663** SDIO pada STB **FiberHome HG680-FJ** (Amlogic S905X2 / Meson G12A) dengan sistem operasi Armbian Linux.

Paket ini mengubah STB Anda menjadi **Router Wi-Fi Repeater Mandiri (DBDC - Dual-Band Concurrent)** tanpa membutuhkan dongle Wi-Fi USB tambahan.

---

### 🧪 Lingkungan Pengujian Resmi
* **Perangkat Target**: FiberHome HG680-FJ (Amlogic S905X2 / Meson G12A)
* **Modul Wi-Fi**: MediaTek MT7663 / MT7661 SDIO (`037A:7663`)
* **Sistem Operasi**: Armbian v26.11.0 for Aml.S905x2 (Linux kernel `6.18.56-ophub`)
* **Basis Paket**: Debian stable (Bookworm 12)

---

## 🌟 Fitur Utama

* **Mode Wireless Repeater Sejati (DBDC Dual AP/STA)**:
  * Menggunakan virtual interface `ap0` khusus untuk memancarkan Hotspot SoftAP, sementara interface `wlan0` secara bersamaan menangkap sinyal Wi-Fi rumah atau bertindak sebagai klien.
  * Mendukung frekuensi 2.4 GHz (HT40 300 Mbps) dan 5 GHz (VHT80 866 Mbps).
* **Dashboard WSGI Tanpa Dependensi Berat (Zero-Dependency)**:
  * Dibangun dengan Python 3 murni menggunakan micro-framework bawaan (`bottle.py`). Tidak membutuhkan Node.js, npm, ataupun web server berat.
  * Penggunaan RAM sangat hemat: **di bawah 25 MB**, sangat cocok untuk STB TV box minimalis.
* **Bilingual Penuh (Bahasa Indonesia & English)**:
  * Tombol alih bahasa instan dengan satu klik (**ID / EN**) pada bilah navigasi.
  * Seluruh menu drop-down, label statistik, daftar kanal, opsi keamanan, hingga modal dialog diterjemahkan secara rapi dan menyeluruh.
* **Stack Hotspot Terisolasi & Aman**:
  * Menjalankan daemon `hostapd` dan `dnsmasq` mandiri yang khusus mengikat pada interface `ap0` (`10.10.10.1/24`).
  * Service global Debian secara otomatis di-mask agar tidak terjadi bentrok port 53 (DNS) maupun port 67 (DHCP) dengan upstream.
* **Telemetri Suhu & Pemantauan Perangkat Live**:
  * Pemantauan suhu SoC Amlogic secara langsung dari sensor kernel (`/sys/class/thermal/thermal_zone0/temp`).
  * Tabel perangkat terhubung secara *real-time*: menampilkan MAC address, IP sewa DHCP, nama perangkat (hostname), nama alias custom, serta bandwidth unduh (DOWN) dan unggah (UP) per perangkat.
* **Otomasi Routing & NAT Masquerade**:
  * Skrip NetworkManager dispatcher (`90-wlan0-routing.sh`) otomatis menyetel aturan iptables NAT setiap kali antarmuka internet (`wlan0` atau `eth0`) terhubung.
  * Optimasi parameter kernel sysctl untuk *IP Forwarding* dan isolasi ARP (`arp_ignore=1`, `arp_announce=2`).

---

## 📐 Arsitektur Jaringan

```
                 +-----------------------------------------------+
                 |        FiberHome HG680-FJ (Amlogic S905X2)    |
                 |                                               |
[ Router Rumah ] <==== [wlan0 (STA)]                 [ap0 (AP)] ====> [ HP / Laptop ]
 (Internet WAN)  |      DHCP Client                 10.10.10.1   |    (Klien Hotspot)
                 |           \                           /       |
                 |            +--- iptables NAT (MASQ) -+        |
                 |            |    IPv4 Forwarding = 1  |        |
                 |            |    Isolated dnsmasq     |        |
                 |            +-------------------------+        |
                 |            |   WSGI Dashboard :8080  |        |
                 +------------+-------------------------+--------+
```

---

## 📋 Syarat Sistem

Sebelum memasang paket Web UI ini, pastikan paket driver murni DKMS telah terpasang:

1. **Driver Kernel**: [`mt7663-dkms`](https://github.com/elsangithub/mt7663-driver) (versi **1.0.8** atau lebih baru).
2. **Sistem Operasi**: Armbian Linux (`6.18.56-ophub` / basis Debian 12 Bookworm).

---

## 🚀 Panduan Instalasi

### 1. Pasang via Perintah APT

Unduh paket `.deb` terbaru dan pasang menggunakan `apt` agar seluruh dependensi pendukung (`hostapd`, `dnsmasq`, `python3`, `iptables`, `wireless-tools`) diunduh dan dipasang secara otomatis:

```bash
sudo apt update
sudo apt install ./mt7663-router-webui_1.0.1_all.deb
```

### 2. Aktifkan Mode Dual AP/STA

Pada instalasi pertama kali, lakukan reboot pada STB agar kontroler bus SDIO Amlogic melakukan reset daya fisik bersih dan membaca parameter `ap_mode=1`:

```bash
sudo reboot
```

Setelah menyala kembali, pastikan kedua antarmuka nirkabel sudah aktif:
```bash
ip link show wlan0
ip link show ap0
```

---

## 🖥️ Cara Mengakses Web Dashboard

1. Hubungkan HP atau laptop Anda ke hotspot Wi-Fi bawaan STB:
   * **Nama SSID**: `MT7663-Hotspot` (atau `HG680_5G_VHT80`)
   * **Kata Sandi**: `password123`
2. Buka browser dan kunjungi alamat:
   * **URL**: [`http://10.10.10.1:8080`](http://10.10.10.1:8080)
   * *(Atau bisa diakses via IP LAN kabel Ethernet STB Anda di `http://<IP-LAN-STB>:8080`)*
3. Masuk menggunakan akun administrator bawaan:
   * **Username**: `admin`
   * **Password**: `admin`

> [!TIP]
> Anda dapat mengganti username dan password admin kapan saja melalui tab **Admin**.

---

## ⚙️ Berkas Konfigurasi Sistem

Paket ini menempatkan konfigurasinya pada struktur berkas standar Linux:

| Jalur Berkas | Fungsi & Keterangan |
| :--- | :--- |
| `/etc/default/mt7663-hotspot` | Setelan lingkungan hotspot (SSID, kanal, frekuensi band, IP gateway, rentang DHCP, server DNS). |
| `/etc/hostapd/hostapd-mt7663.conf` | Templat konfigurasi runtime hostapd yang digenerate otomatis oleh service hotspot. |
| `/etc/modprobe.d/wlan_mt7663_sdio.conf` | Opsi modul kernel pengaktif `ap_mode=1` untuk pembuatan antarmuka ganda. |
| `/etc/sysctl.d/99-mt7663.conf` | Parameter kernel untuk IPv4 forwarding dan isolasi ARP. |
| `/etc/NetworkManager/dispatcher.d/90-wlan0-routing.sh` | Skrip hook otomatis yang mengatur iptables NAT setiap kali koneksi WAN menyala. |
| `/etc/mt7663-device-names.json` | Menyimpan nama alias custom yang Anda berikan ke perangkat klien di Web UI. |

---

## 📡 Rekomendasi Penggunaan Mode Repeater

Ketika menggunakan STB untuk menangkap Wi-Fi pada `wlan0` dan memancarkannya kembali via `ap0` (Mode Repeater), gunakan panduan alokasi frekuensi berikut:

* **Paling Direkomendasikan (Mode DBDC Sejati)**:
  * Hubungkan **`wlan0`** ke Wi-Fi rumah pada frekuensi **5 GHz** (misal Kanal 36 atau 149).
  * Atur Hotspot **`ap0`** pada frekuensi **2.4 GHz** (Kanal 6, 40 MHz).
  * *Alasan*: Chipset MT7663 memiliki dua modul radio fisik independen (2.4 GHz dan 5 GHz). Penggunaan frekuensi yang berbeda memastikan tidak terjadi perebutan spektrum udara (*airtime contention*) sehingga kecepatan internet maksimal dan stabil tanpa *drop*.
* **Jika kedua antarmuka terpaksa menggunakan 5 GHz**:
  * Samakan kanal frekuensi antara `wlan0` dan `ap0` untuk meminimalisir waktu peralihan frekuensi (*time-slicing*).

---

## 🗑️ Cara Menghapus Paket (Uninstall)

Jika suatu saat Anda ingin mencopot paket Web UI dan mengembalikan STB menjadi klien Wi-Fi biasa (`wlan0` saja):

```bash
# 1. Hapus paket Web UI dan konfigurasinya
sudo apt purge -y mt7663-router-webui

# 2. Bersihkan dependensi yang tidak terpakai lagi
sudo apt autoremove -y --purge

# 3. Reboot untuk memulihkan mode murni wlan0
sudo reboot
```

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah lisensi **GNU General Public License v2.0 (GPLv2)**.
