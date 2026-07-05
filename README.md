# Minecraft Forge Server Installer

Bosan dengan setup Minecraft server yang ribet? Ini tool untuk kamu.

Cukup jalankan satu script, jawab beberapa pertanyaan, dan server siap jalan. Gaya Aternos, tapi lokal. Support Minecraft dari versi 1.1 sampai yang terbaru sekarang. Semua versi Forge yang ada otomatis bisa dipilih.

Kerjanya begini: kamu pilih versi Minecraft, pilih build Forge yang mau, terus script handle sisanya. Mulai dari download Java yang tepat, instalasi Forge, sampe bikin file konfigurasi. Nggak perlu tahu detail teknis.

## Yang ada di sini

Pilih sesuai device kamu:

- **Linux & Termux (Android)**: gunakan `install.sh`
- **Windows**: gunakan `install.bat`

Simpel kok. Cuma dua file untuk masing-masing platform.

## Gimana caranya?

### Windows
Gampang banget. Cari `install.bat`, klik dua kali. Trus ikuti pertanyaan yang muncul.

Kalau Windows bilang "Windows Defender SmartScreen", jangan takut. Ini cuma warning standard untuk aplikasi dari internet. Klik "More info" terus "Run anyway". Script ini nggak ada yang bersifat berbahaya kok.

### Linux atau Termux
Buka terminal, jalankan:

```bash
chmod +x install.sh
./install.sh
```

Di Termux, cara yang sama. Pastikan paket sudah update terlebih dahulu dengan `pkg update` kalau baru kali install Termux.

## Yang auto-setting vs yang bisa kamu atur

**Script akan otomatis tentuin:**

Java. Script cek versi Minecraft yang kamu pilih, terus download Java yang cocok:
- Minecraft 1.16 dan lebih lama → Java 8
- Minecraft 1.17 → Java 16
- Minecraft 1.18 sampai 1.20.4 → Java 17
- Minecraft 1.20.5 dan lebih baru → Java 21

Jadi nggak perlu kamu cari-cari Java versi berapa. Selain itu, Java-nya di-install khusus buat server itu aja, gak ikutan ubah Java di sistem kamu. Artinya kalau punya beberapa server dengan versi Minecraft beda-beda, nggak berisiko conflict.

Daftar versi Forge. Script ambil langsung dari Forge official. Jadi kalo ada versi Forge baru, otomatis bisa dipilih di sini tanpa perlu update script.

**Kamu yang pilih:**

Versi Minecraft berapa. Script bakal show semua versi yang available. Kalo bingung, ketik `list` untuk lihat lengkap.

Build Forge mana. Bisa pilih `recommended` (paling stabil, biasanya pilihan terbaik), `latest` (paling fresh, tapi kemungkinan masih ada bug), atau ketik nomor build specific kalau tahu.

**Boleh di-setting kalau kepingin lebih custom:**

Port server, difficulty, game mode, MOTD (pesan di server list), jumlah pemain max, whitelist on/off, dan berapa MB RAM yang dialokasiin buat server.

Semua ini optional. Kalau di-skip, script pakai setting default yang reasonable (port 25565, difficulty easy, RAM 1 sampai 2 GB).

## Hal-hal yang perlu kamu tau

**Soal EULA.** Minecraft punya peraturan (EULA) yang wajib disetujui buat jalanin server. Script akan minta persetujuan eksplisit dari kamu. Bukan di-accept otomatis diam-diam, karena itu gak sah.

**Minecraft versi lama di Termux.** Kalau pengen buat Minecraft 1.12 atau lebih lama di Termux, mungkin bakal berisiko. Termux punya keterbatasan paket Java yang available. Untuk versi super lama, VPS atau Linux biasa lebih aman.

**Minecraft super duper lama (pre-1.5.2).** Jaman itu Forge belum pakai format installer yang standard. Kalau script gagal unduh installer untuk versi super lawas, script bakal bilang dan kamu perlu instal manual. Tapi ini sangat jarang terjadi, soalnya hampir nggak ada yang pakai Minecraft setua itu lagi.

**Source-nya terpercaya.** Semua file yang di-download berasal dari official source: Forge, Minecraft, sama Adoptium (yang maintain OpenJDK resmi). Jadi aman.

## Setelah instalasi selesai

Folder `mc-server` (atau nama yang kamu buat) udah siap. Buat jalanin server:

**Linux & Termux:**
```bash
cd mc-server
./start-server.sh
```

**Windows:**
```batch
cd mc-server
start-server.bat
```

Server akan start. Console bakal muncul dengan info loading. Ketika udah selesai loading (lihat log sampai nggak ada error), server kamu live.

Mau stop server? Ketik `stop` di console terus Enter. Server akan shutdown dengan proper.

## Helpful tips

- Pertama kali server start, akan ada beberapa file baru yang auto-generated (world data, config, dll). Ini normal.
- Kalau ada error pas startup, lihat log message. Biasanya error message cukup jelas buat troubleshoot.
- Di Termux, kalau khawatir HP auto-sleep, jalankan `termux-wake-lock` sebelum start server. Ini keep device tetap active.
- Khusus Termux juga: gunakan VPN atau pastikan port sudah forward kalau mau teman outside network bisa connect. Termux di HP personal nggak bisa di-access dari internet langsung.