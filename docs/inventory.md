# Device inventory list

## Devices

### 1) Proxmox pve node 1
Device name: lenovo m720q tiny
CPU: Intel(R) Core(TM) i5-8500T CPU @ 2.10GHz
Ram: 32Gb (16gb X2), DDR4, 2133 Mhz
Storages:
1) 119 GB LITEON LCH-128V2S-HP (boot/OS, SSD)
2) 1TB Samsung SSD 970 EVO Plus
Network: lab
1) enp2s0
Speed: 2.5Gbit/s
Mac: 02:26:26:02:12:c4
IP: 192.168.20.10

### 2) Proxmox pve node 2
Device name: lenovo m720q tiny
CPU: Intel(R) Core(TM) i5-8500T CPU @ 2.10GHz
Ram: 32Gb (16gb X2), DDR4, 2666 Mhz
Storages:
1) 238 GB Micron MTFDDAK256TBN-1AR1ZABHA (boot/OS, SSD)
2) 1TB Samsung SSD 970 EVO Plus
Network: lab
1) enp2s0
Speed: 2.5Gbit/s
Mac: 02:26:26:02:12:3c
IP: 192.168.20.20

### 3) TrueNAS
Device name: hp proliant microserver gen8
CPU: Intel(R) Xeon(R) CPU E3-1220 V2 @ 3.10GHz
Ram: 16Gb (8gb X2), DDR3 ECC, 1600 Mhz
Storages:
1. 3.6TB WDC WD40EFRX-68WT0N0 (WD Red, media_storage mirror)
2. 3.6TB WDC WD40EFRX-68WT0N0 (WD Red, media_storage mirror)
3. 932 GB HGST HTS721010A9E630 (spare, not in pool)
4. 932 GB ST1000LM048-2E7172 (Seagate, hdd_seagate_barakuda pool, no redundancy)
5. 119 GB P3-128 (boot/OS, SSD)
6. 14.6 GB SATA flash (TrueNAS install stick)
Network: home
7. eno1 (onboard)
Speed: 1Gbit/s
Mac: 94:18:82:37:bf:d8
IP: -
8. eno2 (onboard)
Speed: 1Gbit/s
Mac: 94:18:82:37:bf:d9
IP: -
9. enx00e04c68012a (USB 2.5G adapter)
Speed: 2.5Gbit/s
Mac: 00:e0:4c:68:01:2a
IP: 192.168.0.236

### 4) ODROID XU4 1
Device name: odroid-xu4
CPU: Samsung Exynos 5422, 4x Cortex-A15 @ 2.0GHz + 4x Cortex-A7 @ 1.4GHz (ARMv7)
Ram: 2Gb DDR3
Storages:
1) 447 GB GOODRAM (SSD)
2) 119 GB eMMC
Network: home
1) eth0
Speed: 1Gbit/s
Mac: 00:1e:06:36:99:cb
IP: 192.168.0.78

### 5) ODROID C2 1
Device name: odroid-c2
CPU: Amlogic S905, Quad-core Cortex-A53 @ 1.5GHz (ARMv8)
Ram: 2Gb DDR3
Storages:
1) 30 GB eMMC
Network: home
1) eth0
Speed: 1Gbit/s
Mac: 00:1e:06:34:54:bb
IP: 192.168.0.69

### 6) ODROID C2 2
Device name: odroid-c2
CPU: Amlogic S905, Quad-core Cortex-A53 @ 1.5GHz (ARMv8)
Ram: 2Gb DDR3
Storages:
1) 30 GB eMMC
Network: home
1) eth0
Speed: 1Gbit/s
Mac: 00:1e:06:34:77:68
IP: 192.168.0.228

### 7) ODROID XU4 2
Device name: odroid-xu4
CPU: Samsung Exynos 5422, 4x Cortex-A15 @ 2.0GHz + 4x Cortex-A7 @ 1.4GHz (ARMv7)
Ram: 2Gb DDR3
Storages:
1) 29 GB microSD
2) 119 GB eMMC
Network: home
1) eth0
Speed: 1Gbit/s
Mac: 00:1e:06:36:a0:db
IP: 192.168.0.92

## Network gear 

### 1) MikroTik hAP wi-fi router

Device name: MikroTik hAP ax3 C53UiG+5HPaxD2HPaxD
Network: home/lab
1)
Speed: 1Gbit/s (port 2-4), 2.5Gbit/s (port1)
IP: 192.168.0.1
Mac: 04:F4:1C:D1:3F:1A

### 2) Switch 8 ports 1Gbs Zyxel GS1200-8
Device name: Zyxel GS1200-8 8 ports - managed
Network: home/lab
1)
Speed: 1Gbit/s
IP: 192.168.0.3
Mac: 14:36:0E:F8:CD:2E

### 3) UbiQuiti USW-Flex-2.5G-8
Device name: UbiQuiti USW-Flex-2.5G-8 8-ports - managed
Network: home/lab
1) 
Speed: 2.5Gbit/s
IP: 192.168.0.68
Mac: A8:9C:6C:80:B7:A6

