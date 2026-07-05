###############################################################################
#  Minecraft Forge Server - Auto Installer (Windows)
#  Support: Minecraft 1.1 s/d versi terbaru (mengikuti data resmi Forge)
###############################################################################

$ErrorActionPreference = "Stop"

function Write-Banner {
@"

  ███╗   ███╗ ██████╗    ███████╗ ██████╗ ██████╗ ██████╗ ███████╗
  ████╗ ████║██╔════╝    ██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝
  ██╔████╔██║██║         █████╗  ██║  ██║██████╔╝██║  ██║█████╗
  ██║╚██╔╝██║██║         ██╔══╝  ██║  ██║██╔══██╗██║  ██║██╔══╝
  ██║ ╚═╝ ██║╚██████╗    ██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗
  ╚═╝     ╚═╝ ╚═════╝    ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝
              Server Installer  -  Windows Edition
"@ | Write-Host -ForegroundColor Cyan
}

function Info($msg)  { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function OkMsg($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }
function Warn($msg)  { Write-Host "[PERHATIAN] $msg" -ForegroundColor Yellow }
function ErrMsg($msg){ Write-Host "[ERROR] $msg" -ForegroundColor Red }

# ---------------------------------------------------------------------------
# Bandingkan versi model "1.20.1" dengan [version] .NET (aman untuk 2-4 segmen)
# ---------------------------------------------------------------------------
function ConvertTo-Version($s) {
    $parts = $s.Split('.')
    while ($parts.Count -lt 4) { $parts += "0" }
    return [version]("{0}.{1}.{2}.{3}" -f $parts[0], $parts[1], $parts[2], $parts[3])
}

function Test-VersionLessThan($a, $b) {
    return (ConvertTo-Version $a) -lt (ConvertTo-Version $b)
}

function Get-RequiredJavaVersion($mc) {
    if (Test-VersionLessThan $mc "1.17")   { return 8 }
    if (Test-VersionLessThan $mc "1.18")   { return 16 }
    if (Test-VersionLessThan $mc "1.20.5") { return 17 }
    return 21
}

# ---------------------------------------------------------------------------
# Ambil data Forge resmi
# ---------------------------------------------------------------------------
$ForgeMetaUrl  = "https://maven.minecraftforge.net/net/minecraftforge/forge/maven-metadata.xml"
$ForgePromoUrl = "https://files.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json"

function Get-ForgeData {
    Info "Mengambil daftar versi Forge dari server resmi..."
    try {
        $script:MetaXml  = [xml](Invoke-WebRequest -Uri $ForgeMetaUrl -UseBasicParsing).Content
        $script:PromoObj = (Invoke-WebRequest -Uri $ForgePromoUrl -UseBasicParsing).Content | ConvertFrom-Json
    } catch {
        ErrMsg "Gagal mengambil data Forge. Cek koneksi internet kamu."
        exit 1
    }
    OkMsg "Data versi Forge berhasil diambil."
}

function Get-AllForgeVersions {
    return $script:MetaXml.metadata.versioning.versions.version
}

function Get-McVersionsList {
    return (Get-AllForgeVersions | ForEach-Object { $_ -replace '-.*$','' } | Select-Object -Unique)
}

function Get-BuildsForMc($mc) {
    $escaped = [regex]::Escape($mc)
    return (Get-AllForgeVersions | Where-Object { $_ -match "^$escaped-" })
}

function Get-PromoForMc($mc) {
    $result = @{}
    foreach ($prop in $script:PromoObj.promos.PSObject.Properties) {
        if ($prop.Name -eq "$mc-recommended") { $result["recommended"] = $prop.Value }
        if ($prop.Name -eq "$mc-latest")      { $result["latest"] = $prop.Value }
    }
    return $result
}

# ---------------------------------------------------------------------------
# Pilih versi Minecraft & Forge secara interaktif
# ---------------------------------------------------------------------------
function Select-Versions {
    while ($true) {
        Write-Host ""
        Write-Host "Masukkan versi Minecraft yang diinginkan (contoh: 1.20.1)" -ForegroundColor White
        Write-Host "  Ketik 'list' untuk melihat versi yang didukung Forge" -ForegroundColor Yellow
        Write-Host "  Support resmi: dari Minecraft 1.1 sampai versi terbaru"
        $mc = Read-Host "> Versi Minecraft"

        if ($mc -eq "list") {
            Get-McVersionsList | Format-Wide -Column 6 | Out-Host
            continue
        }

        $candidates = Get-BuildsForMc $mc
        if (-not $candidates -or $candidates.Count -eq 0) {
            ErrMsg "Versi Minecraft '$mc' tidak ditemukan di data Forge. Coba lagi (ketik 'list')."
            continue
        }
        $script:McVersion = $mc
        $script:Candidates = $candidates
        break
    }

    Write-Host ""
    Write-Host "Build Forge yang tersedia untuk Minecraft $($script:McVersion):" -ForegroundColor White
    $promo = Get-PromoForMc $script:McVersion
    if ($promo.recommended) { Write-Host "recommended=$($promo.recommended)" -ForegroundColor Green }
    if ($promo.latest)      { Write-Host "latest=$($promo.latest)" -ForegroundColor Green }
    $script:Candidates | Select-Object -Last 15 | ForEach-Object { Write-Host "  - $_" }

    Write-Host ""
    Write-Host "Ketik 'recommended' (default), 'latest', atau nomor build manual." -ForegroundColor Yellow
    $choice = Read-Host "> Pilihan build Forge [recommended]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "recommended" }

    if ($choice -eq "recommended" -or $choice -eq "latest") {
        $buildVer = $promo[$choice]
        if (-not $buildVer) {
            Warn "Tidak ada rekomendasi resmi, memakai build terbaru yang tersedia."
            $last = $script:Candidates | Select-Object -Last 1
            $buildVer = $last -replace "^$([regex]::Escape($script:McVersion))-",""
        }
    } else {
        $buildVer = $choice
    }

    $script:ForgeBuild = $buildVer
    $script:ForgeFull   = "$($script:McVersion)-$($script:ForgeBuild)"

    if ($script:Candidates -notcontains $script:ForgeFull) {
        ErrMsg "Build '$buildVer' tidak valid untuk Minecraft $($script:McVersion)."
        exit 1
    }

    OkMsg "Dipilih: Minecraft $($script:McVersion) + Forge build $($script:ForgeBuild)"
}

# ---------------------------------------------------------------------------
# Siapkan folder server
# ---------------------------------------------------------------------------
function New-ServerDir {
    $dirName = Read-Host "> Nama folder server [mc-server]"
    if ([string]::IsNullOrWhiteSpace($dirName)) { $dirName = "mc-server" }
    $script:ServerDir = Join-Path (Get-Location) $dirName
    New-Item -ItemType Directory -Force -Path $script:ServerDir | Out-Null
    Set-Location $script:ServerDir
    OkMsg "Folder server: $($script:ServerDir)"
}

# ---------------------------------------------------------------------------
# Download & siapkan OpenJDK portable yang sesuai (Adoptium), terisolasi per-server
# ---------------------------------------------------------------------------
function Setup-Java {
    $javaMajor = Get-RequiredJavaVersion $script:McVersion
    Info "Minecraft $($script:McVersion) butuh OpenJDK versi $javaMajor"

    $arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    $jdkUrl = "https://api.adoptium.net/v3/binary/latest/$javaMajor/ga/windows/$arch/jdk/hotspot/normal/eclipse"

    Info "Mengunduh OpenJDK $javaMajor portable khusus untuk server ini..."
    $zipPath = Join-Path $script:ServerDir "jdk.zip"
    try {
        Invoke-WebRequest -Uri $jdkUrl -OutFile $zipPath -UseBasicParsing
        $extractPath = Join-Path $script:ServerDir "jdk_temp"
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        $inner = Get-ChildItem $extractPath | Select-Object -First 1
        $jdkFinal = Join-Path $script:ServerDir "jdk"
        if (Test-Path $jdkFinal) { Remove-Item $jdkFinal -Recurse -Force }
        Move-Item $inner.FullName $jdkFinal
        Remove-Item $extractPath -Recurse -Force
        Remove-Item $zipPath -Force
        $script:JavaBin = Join-Path $jdkFinal "bin\java.exe"
        $script:UseLocalJdk = $true
        OkMsg "OpenJDK $javaMajor terpasang secara lokal di folder server."
    } catch {
        Warn "Gagal mengunduh JDK portable. Mencoba memakai 'java' dari sistem (pastikan sudah terpasang)."
        $script:JavaBin = "java"
        $script:UseLocalJdk = $false
    }
}

# ---------------------------------------------------------------------------
# Download & jalankan Forge installer
# ---------------------------------------------------------------------------
function Invoke-ForgeInstaller {
    $url = "https://maven.minecraftforge.net/net/minecraftforge/forge/$($script:ForgeFull)/forge-$($script:ForgeFull)-installer.jar"
    Info "Mengunduh Forge installer: $($script:ForgeFull)"
    try {
        Invoke-WebRequest -Uri $url -OutFile "forge-installer.jar" -UseBasicParsing
    } catch {
        ErrMsg "Gagal mengunduh installer Forge. Versi ini mungkin tidak memakai format installer"
        ErrMsg "(umumnya untuk Minecraft di bawah 1.5.2). Silakan instal manual untuk versi ini."
        exit 1
    }

    Info "Menjalankan Forge installer (--installServer)..."
    & $script:JavaBin -jar forge-installer.jar --installServer
    OkMsg "Instalasi Forge server selesai."
}

# ---------------------------------------------------------------------------
# EULA
# ---------------------------------------------------------------------------
function Set-Eula {
    Write-Host ""
    Write-Host "Mojang mewajibkan persetujuan EULA untuk menjalankan server." -ForegroundColor White
    Write-Host "Baca di: https://www.minecraft.net/eula"
    $agree = Read-Host "Apakah kamu SETUJU dengan Minecraft EULA? (y/n)"
    if ($agree -ne "y") {
        ErrMsg "EULA tidak disetujui. Server tidak bisa dijalankan tanpa ini."
        exit 1
    }
    "eula=true" | Out-File -FilePath "eula.txt" -Encoding ascii
    OkMsg "eula.txt dibuat."
}

# ---------------------------------------------------------------------------
# Konfigurasi tambahan (opsional)
# ---------------------------------------------------------------------------
function Set-ServerProperties {
    Write-Host ""
    $customize = Read-Host "Atur pengaturan server sekarang (port, RAM, dll)? (y/n) [n]"
    if ([string]::IsNullOrWhiteSpace($customize)) { $customize = "n" }

    $script:RamMin = 1024
    $script:RamMax = 2048
    $port = "25565"; $difficulty = "easy"; $gamemode = "survival"
    $motd = "A Minecraft Server"; $maxPlayers = "20"; $whitelist = "false"

    if ($customize -eq "y") {
        $inp = Read-Host "Server port [25565]"; if ($inp) { $port = $inp }
        $inp = Read-Host "Difficulty (peaceful/easy/normal/hard) [easy]"; if ($inp) { $difficulty = $inp }
        $inp = Read-Host "Gamemode (survival/creative/adventure) [survival]"; if ($inp) { $gamemode = $inp }
        $inp = Read-Host "MOTD [A Minecraft Server]"; if ($inp) { $motd = $inp }
        $inp = Read-Host "Max players [20]"; if ($inp) { $maxPlayers = $inp }
        $inp = Read-Host "Whitelist aktif? (true/false) [false]"; if ($inp) { $whitelist = $inp }
        $inp = Read-Host "RAM minimum MB [1024]"; if ($inp) { $script:RamMin = $inp }
        $inp = Read-Host "RAM maksimum MB [2048]"; if ($inp) { $script:RamMax = $inp }
    }

    Add-Content -Path "server.properties" -Value @(
        "server-port=$port"
        "difficulty=$difficulty"
        "gamemode=$gamemode"
        "motd=$motd"
        "max-players=$maxPlayers"
        "white-list=$whitelist"
    )
    OkMsg "server.properties disiapkan (port=$port, difficulty=$difficulty, gamemode=$gamemode)."
}

# ---------------------------------------------------------------------------
# Buat script start.bat yang seragam
# ---------------------------------------------------------------------------
function New-StartScript {
    $serverJar = Get-ChildItem -Filter "forge-*.jar" | Where-Object { $_.Name -notmatch "installer" } | Select-Object -First 1

    $lines = @("@echo off", "cd /d %~dp0")

    if ($script:UseLocalJdk) {
        $lines += 'set "JAVA_HOME=%~dp0jdk"'
        $lines += 'set "PATH=%JAVA_HOME%\bin;%PATH%"'
    }

    if (Test-Path "run.bat") {
        $lines += "call run.bat nogui"
    } elseif ($serverJar) {
        $lines += "java -Xms$($script:RamMin)M -Xmx$($script:RamMax)M -jar `"$($serverJar.Name)`" nogui"
    } else {
        $lines += "echo Tidak menemukan server jar Forge!"
        $lines += "pause"
    }

    $lines | Out-File -FilePath "start-server.bat" -Encoding ascii
    OkMsg "Script start dibuat: start-server.bat"
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
function Main {
    Write-Banner
    Get-ForgeData
    Select-Versions
    New-ServerDir
    Setup-Java
    Invoke-ForgeInstaller
    Set-Eula
    Set-ServerProperties
    New-StartScript

    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host " Server Minecraft Forge $($script:McVersion) siap! " -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "Lokasi   : $($script:ServerDir)"
    Write-Host "Jalankan : cd `"$($script:ServerDir)`" && start-server.bat" -ForegroundColor Yellow
    Write-Host ""
    Info "Untuk menghentikan server, ketik 'stop' di console server."
}

Main
