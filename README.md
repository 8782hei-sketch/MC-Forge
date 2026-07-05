# Minecraft Forge Server — Auto Installer

Installer gaya "pilih dan selesai" (seperti Aternos) untuk server **Minecraft Forge**,
support dari **Minecraft 1.1 sampai versi terbaru** — mengambil data langsung dari
server resmi Forge (`maven.minecraftforge.net`), jadi otomatis update kalau ada versi baru.

## Isi paket

```
mc-installer/
├── linux-termux/
│   └── install.sh      ← untuk Linux & Termux (Android)
├── windows/
│   ├── install.bat      ← double-click ini di Windows
│   └── install.ps1      ← logic utama (dipanggil otomatis oleh install.bat)
└── README.md
```

## Cara pakai

### Linux / Termux
```bash
chmod +x install.sh
./install.sh
```
Di Termux, jalankan persis sama. Pastikan sudah `pkg update` sebelumnya kalau baru install Termux.

### Windows
Cukup **double-click `install.bat`**. Kalau muncul peringatan SmartScreen,
klik "More info" → "Run anyway" (script ini tidak butuh admin/koneksi berbahaya,
cuma download resmi dari Forge & Adoptium).

## Apa yang otomatis dan apa yang bisa kamu atur

**Otomatis (tidak perlu mikir):**
- Versi OpenJDK yang cocok dipilih otomatis sesuai versi Minecraft:
  - Minecraft < 1.17 → Java 8
  - Minecraft 1.17 → Java 16
  - Minecraft 1.18 – 1.20.4 → Java 17
  - Minecraft ≥ 1.20.5 → Java 21
- JDK diunduh **portable & terisolasi di dalam folder server** (Linux/Windows) — tidak mengubah Java sistem, jadi aman kalau kamu punya beberapa server dengan versi berbeda.
- Daftar versi Forge + rekomendasi build diambil live dari Forge, bukan hardcode — otomatis mendukung versi terbaru begitu Forge merilisnya.

**Kamu tinggal pilih:**
- Versi Minecraft (ketik `list` untuk lihat semua yang didukung)
- Build Forge: `recommended` (paling stabil, disarankan), `latest` (paling baru), atau nomor build manual

**Opsional, kalau mau di-setting-setting:**
- Port server, difficulty, gamemode, MOTD, max players, whitelist
- Alokasi RAM minimum/maksimum

Kalau di-skip, semua pakai default yang wajar (port 25565, difficulty easy, RAM 1024–2048MB).

## Catatan penting

- **EULA**: script akan minta persetujuan EULA Mojang secara eksplisit — ini wajib secara hukum, jadi tidak di-auto-accept diam-diam.
- **Termux & versi lawas**: Termux hanya menyediakan paket OpenJDK yang relatif baru. Untuk Minecraft versi lama (butuh Java 8), server mungkin tidak berjalan mulus di Termux — untuk kasus ini lebih disarankan pakai VPS/Linux biasa.
- **Minecraft sangat lawas (sebelum ±1.5.2)**: dulu Forge belum punya format "installer.jar", jadi kalau download installer gagal untuk versi sangat lama, script akan memberi tahu dan kamu perlu instal manual untuk versi tersebut (Forge di era itu didistribusikan sebagai file "universal").
- Semua unduhan berasal dari sumber resmi: `maven.minecraftforge.net`, `files.minecraftforge.net`, dan `api.adoptium.net` (Eclipse Temurin/OpenJDK resmi).

## Menjalankan server setelah instalasi

```bash
# Linux/Termux
cd mc-server
./start-server.sh
```
```bat
:: Windows
cd mc-server
start-server.bat
```

Untuk mematikan server, ketik `stop` di console lalu Enter.
