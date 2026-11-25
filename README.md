# Samsung ML-1630W driver for macOS (Apple Silicon)

Ready-to-install CUPS driver for the **Samsung ML-1630 / ML-1630W** laser printer on
Apple Silicon Macs (M1–M4).

Samsung (now HP) never released an Apple Silicon driver for this printer. It only speaks
Samsung's SPL (QPDL) language, so AirPrint, IPP Everywhere and generic PostScript drivers
can't drive it. This package uses the open-source [SpliX](https://github.com/OpenPrinting/splix)
driver, built natively for arm64 with the JBIG compression library the ML-1630 needs
linked in. You don't need Homebrew, Rosetta or anything else installed.

Tested since August 2026 on a MacBook with an Apple M4 chip (macOS 27.2) and an ML-1630W
on the network (raw socket, port 9100). USB was not tested.

## Install

```bash
git clone https://github.com/nellynelson24/samsung-ml1630w-macos-drivers.git
cd samsung-ml1630w-macos-drivers
./install.sh
```

You can also download the archive from [Releases](../../releases), unpack it and run
`./install.sh`. The script puts two filters into `/usr/libexec/cups/filter` and the PPD
into `/Library/Printers/PPDs/Contents/Resources`, and it removes the browser quarantine
flag, which would otherwise stop CUPS from running the filters.

Then add the printer, replacing `PRINTER_IP` with your printer's address:

```bash
lpadmin -p Samsung_ML1630W -E -v socket://PRINTER_IP:9100 \
  -P /Library/Printers/PPDs/Contents/Resources/ml1630.ppd
```

Or use **System Settings → Printers & Scanners → Add Printer → IP**:
- Address: the printer's IP
- Protocol: *HP Jetdirect – Socket*
- Use: *Select Software…* → **Samsung ML-1630**

Give the printer a fixed address (a DHCP reservation on your router), otherwise the queue
stops working when the IP changes.

To remove everything:

```bash
./uninstall.sh
```

## Printing from iPhone and iPad (AirPrint)

The ML-1630W has no AirPrint, so iPhones and iPads can't see it. The simplest fix is a
small **CUPS print server** on any always-on Linux machine: a Raspberry Pi, a Proxmox
container, a NAS VM. CUPS on Debian/Ubuntu shares the printer as an AirPrint printer, so
iPhones, iPads and Macs print to it **without installing any driver**. This repo is then
only needed if you want to print from a Mac straight to the printer.

On Debian 12/13 or Ubuntu:

```bash
sudo apt install --no-install-recommends cups cups-filters printer-driver-splix avahi-daemon
sudo cupsctl --share-printers
sudo lpadmin -p Samsung_ML1630W -D "Samsung ML-1630W" -E \
  -v socket://PRINTER_IP:9100 \
  -m drv:///splix-samsung.drv/ml1630.ppd \
  -o printer-is-shared=true -o PageSize=A4
```

The printer then appears on iPhones and iPads as **"Samsung ML-1630W @ <server name>"**
(Share → Print). Notes:

- The server and your devices must be on the **same network / VLAN**. AirPrint discovery
  uses mDNS (Bonjour), which does not cross subnets.
- Check the announcement from a Mac: `dns-sd -B _ipp._tcp`.
- Debian's `printer-driver-splix` already includes the ML-1630 driver with JBIG.
  `lpinfo -m | grep 1630` should show `drv:///splix-samsung.drv/ml1630.ppd`.
- In an unprivileged LXC container this works out of the box. Avahi only needs to run in
  that one container.

If you don't have a server, macOS can share the printer too (System Settings → General →
Sharing → Printer Sharing). iOS devices then see it over AirPrint, but only while that
Mac is awake.

## What's inside

| Path | What |
|---|---|
| `filter/rastertoqpdl`, `filter/pstoqpdl` | SpliX CUPS filters, arm64, ad-hoc signed, JBIG-KIT 2.1 statically linked |
| `ppd/ml1630.ppd` (+ `fr`, `pt`) | PPD files for the ML-1630 / ML-1630W |
| `install.sh`, `uninstall.sh` | Install / remove the filters and the PPD |
| `build.sh` | Rebuilds `filter/` and `ppd/` from `source/` |
| `source/` | Complete corresponding source code (see below) |

## Building from source

```bash
xcode-select --install   # once, if you don't have the Command Line Tools
./build.sh
```

`build.sh` builds JBIG-KIT and SpliX from the archives in `source/` and needs nothing else.
The sources are included because the upstream macOS fork was later rebased and the
exact commit used here is no longer part of its history:

- `source/splix-macos-941fe7b-src.tar.gz`: [photovirus/splix-macos](https://github.com/photovirus/splix-macos)
  at commit `941fe7b51103543ff9043a63ee8419ec979ec580`, unmodified
- `source/jbigkit-2.1.tar.gz`: [JBIG-KIT 2.1](https://www.cl.cam.ac.uk/~mgk25/jbigkit/), unmodified,
  SHA-256 `de7106b6bfaf495d6865c7dd7ac6ca1381bd12e0d81405ea81e7f2167263d932`

The only changes compared with a plain `make` are build steps. The bundled JBIG-KIT is
linked in place of a Homebrew copy, and debug info with local build paths is removed
(`strip -S`) before ad-hoc signing.

## Credits and license

- **SpliX**: Aurélien Croc and Till Kamppeter (OpenPrinting), GPL-2.0
- **macOS patch**: [janrueth/splix-2.0.0-macos](https://github.com/janrueth/splix-2.0.0-macos),
  applied in [photovirus/splix-macos](https://github.com/photovirus/splix-macos)
- **JBIG-KIT**: Markus Kuhn, GPL-2.0-or-later

This repository is distributed under the **GNU GPL v2** (see [LICENSE](LICENSE)). It is not
affiliated with Samsung or HP. Provided as is, without warranty.

---

## Po polsku

Sterownik do drukarki **Samsung ML-1630 / ML-1630W** dla Maców z procesorami Apple
(M1–M4). Samsung ani HP nie wydały sterownika na Apple Silicon. Ta paczka to otwarty
sterownik SpliX, skompilowany pod arm64, z wbudowaną kompresją JBIG, której ta drukarka
wymaga.

**Instalacja:** pobierz repo, uruchom `./install.sh`, a potem dodaj drukarkę w
**Ustawieniach systemowych → Drukarki i skanery → Dodaj → IP**. Wpisz adres drukarki,
wybierz protokół *HP Jetdirect – Socket* i sterownik **Samsung ML-1630**. Najlepiej daj
drukarce stały adres IP przez rezerwację DHCP w routerze.

**Drukowanie z iPhone'a i iPada:** drukarka nie obsługuje AirPrint. Warto postawić
**serwer CUPS** na czymś, co działa cały czas, np. Raspberry Pi albo kontenerze w Proxmoxie,
z pakietami `cups printer-driver-splix avahi-daemon`. Polecenia są w sekcji
*Printing from iPhone and iPad* wyżej. CUPS udostępni drukarkę jako AirPrint, więc
iPhone'y, iPady i Maki drukują bez żadnego sterownika. Serwer musi być w tej samej
sieci (VLAN-ie) co telefony.
