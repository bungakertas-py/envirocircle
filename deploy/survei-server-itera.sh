#!/usr/bin/env bash
# =====================================================================
# survei-server-itera.sh
#
# Mendata keadaan server ITERA, buat menentukan bentuk pipeline dan
# deploy Envirocircle di sana.
#
# HANYA MEMBACA. Tidak memasang apa pun, tidak mengubah apa pun, tidak
# menulis di luar /tmp, tidak butuh sudo, tidak menyentuh berkas WRF.
# Satu satunya yang ditulis berkas sementara di /tmp yang dihapus lagi
# di akhir.
#
#   Pakai:  HOSTING_IP=<ip> HOSTING_NAMA=<nama-server> \
#           bash survei-server-itera.sh 2>&1 | tee /tmp/survei-itera.txt
#
#   Lalu salin SELURUH keluarannya, dari baris MULAI sampai baris SELESAI.
#
# Alamat hostingan SENGAJA tidak ditulis di sini, pola yang sama dengan
# kirim-ke-server.sh. Repo ini publik, dan alamat server tidak perlu ikut
# terbaca siapa saja. Isinya ada di bundel pribadi.
# Tanpa dua env itu, bagian 3 dilewati dan sisanya tetap jalan.
# =====================================================================

VERSI="survei-itera-1.1"
BATAS=8                       # detik, buat tiap uji jaringan

HOSTING_IP="${HOSTING_IP:-}"
HOSTING_NAMA="${HOSTING_NAMA:-}"

garis() { printf '%s\n' "--------------------------------------------------------------"; }
judul() { echo; garis; echo "== $* "; garis; }
baris() { printf '  %-34s %s\n' "$1" "$2"; }

# Balikan 0 kalau soket TCP-nya kebuka.
tembus() {
  timeout "$BATAS" bash -c "exec 3<>/dev/tcp/$1/$2" 2>/dev/null
}

# Baris pertama yang dikirim server, buat mengenali SSH.
banner() {
  timeout "$BATAS" bash -c "exec 3<>/dev/tcp/$1/$2 || exit 1; head -c 100 <&3" 2>/dev/null \
    | tr -d '\r' | head -1
}

uji_port() {
  local nama="$1" host="$2" port="$3" b
  printf '  %-26s %-24s ' "$nama" "$host:$port"
  if tembus "$host" "$port"; then
    b="$(banner "$host" "$port")"
    if [ -n "$b" ]; then echo "TEMBUS  [$b]"; else echo "TEMBUS"; fi
  else
    echo "BUNTU"
  fi
}

uji_https() {
  local nama="$1" url="$2" kode
  printf '  %-26s %-40s ' "$nama" "$url"
  if command -v curl >/dev/null 2>&1; then
    kode="$(timeout 20 curl -s -o /dev/null -w '%{http_code}' --max-time 18 "$url" 2>/dev/null)"
    [ "$kode" = "000" ] && echo "GAGAL" || echo "HTTP $kode"
  else
    echo "(curl tidak ada)"
  fi
}

ada() {
  local c="$1" p
  p="$(command -v "$c" 2>/dev/null)"
  if [ -n "$p" ]; then printf '  %-12s %s\n' "$c" "$p"; else printf '  %-12s TIDAK ADA\n' "$c"; fi
}

echo "===== MULAI SURVEI $VERSI ====="
echo "waktu lokal   : $(date 2>/dev/null)"
echo "waktu UTC     : $(date -u 2>/dev/null)"

judul "1. MESIN"
baris "hostname"      "$(hostname 2>/dev/null)"
baris "pengguna"      "$(id -un 2>/dev/null) (uid $(id -u 2>/dev/null))"
baris "home"          "$HOME"
baris "kernel"        "$(uname -sr 2>/dev/null)"
baris "arsitektur"    "$(uname -m 2>/dev/null)"
if [ -r /etc/os-release ]; then
  baris "distro"      "$(. /etc/os-release 2>/dev/null; echo "$PRETTY_NAME")"
fi
baris "inti CPU"      "$(nproc 2>/dev/null)"
baris "beban"         "$(uptime 2>/dev/null | sed 's/.*load average/load average/')"
if command -v free >/dev/null 2>&1; then
  baris "RAM"         "$(free -h 2>/dev/null | awk '/^Mem:/{print $2" total, "$7" tersedia"}')"
fi
baris "shell"         "$SHELL"

judul "2. RUANG DISK"
echo "  Yang dipakai pipeline itu HOME dan tempat kerja WRF. Data mentah GFS"
echo "  sekali unduh sekitar 2 GB, keluaran jadinya sekitar 250 MB."
df -h "$HOME" /tmp 2>/dev/null | sed 's/^/  /'
echo
echo "  Inode:"
df -i "$HOME" 2>/dev/null | sed 's/^/  /'
if command -v quota >/dev/null 2>&1; then
  echo
  echo "  Kuota akun (kalau ada):"
  quota -s 2>/dev/null | sed 's/^/  /' || echo "  (tidak ada kuota)"
fi

judul "3. JARINGAN KELUAR, SASARAN HOSTINGAN"
echo "  INI PERTANYAAN PALING PENTING DI SELURUH SKRIP."
echo "  Kalau port 22 BUNTU, deploy tidak bisa didorong dari mesin ini dan"
echo "  bentuknya harus diubah, misalnya server hostingan yang menarik sendiri."
echo
if [ -z "$HOSTING_IP" ] && [ -z "$HOSTING_NAMA" ]; then
  echo "  DILEWATI. Set HOSTING_IP dan HOSTING_NAMA dulu, lalu jalankan lagi."
  echo "  Contoh:  HOSTING_IP=1.2.3.4 HOSTING_NAMA=server.contoh.com \\"
  echo "           bash $0"
else
  [ -n "$HOSTING_IP" ] && {
    uji_port "SSH hostingan (IP)"   "$HOSTING_IP"   22
    uji_port "HTTPS hostingan"      "$HOSTING_IP"   443
    uji_port "cPanel hostingan"     "$HOSTING_IP"   2083
    uji_port "FTP hostingan"        "$HOSTING_IP"   21
  }
  [ -n "$HOSTING_NAMA" ] && uji_port "SSH hostingan (nama)" "$HOSTING_NAMA" 22
fi

judul "4. JARINGAN KELUAR, SUMBER DATA DAN GITHUB"
echo "  Kalau pipeline betulan pindah ke sini, semua ini harus tembus."
echo
uji_https "GitHub"        "https://github.com/"
uji_https "GitHub Pages"  "https://bungakertas-py.github.io/envirocircle/"
uji_https "NOAA NOMADS"   "https://nomads.ncep.noaa.gov/"
uji_https "Copernicus ADS" "https://ads.atmosphere.copernicus.eu/"
uji_https "NASA FIRMS"    "https://firms.modaps.eosdis.nasa.gov/"

judul "5. DNS"
for n in github.com nomads.ncep.noaa.gov ${HOSTING_NAMA:+"$HOSTING_NAMA"} envirocircle.info; do
  printf '  %-34s ' "$n"
  if command -v getent >/dev/null 2>&1; then
    r="$(getent hosts "$n" 2>/dev/null | awk '{print $1}' | tr '\n' ' ')"
  else
    r="$(python3 -c "import socket,sys;print(socket.gethostbyname(sys.argv[1]))" "$n" 2>/dev/null)"
  fi
  [ -n "$r" ] && echo "$r" || echo "TIDAK TERPECAHKAN"
done
echo
echo "  Catatan, envirocircle.info memang BELUM terdaftar per 5 Sep 2026."
echo "  Kalau di sini juga tidak terpecahkan, itu WAJAR, bukan masalah mesin."

judul "6. PROXY"
for v in http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY; do
  printf '  %-14s %s\n' "$v" "${!v:-(kosong)}"
done

judul "7. ALAT DASAR"
for c in bash ssh scp sftp tar gzip bzip2 xz unzip git curl wget rsync \
         crontab systemctl python3 pip3 node npm make gcc; do ada "$c"; done

judul "8. VERSI YANG PENTING"
command -v python3 >/dev/null 2>&1 && baris "python3"  "$(python3 --version 2>&1)"
command -v pip3    >/dev/null 2>&1 && baris "pip3"     "$(pip3 --version 2>&1 | cut -c1-70)"
command -v git     >/dev/null 2>&1 && baris "git"      "$(git --version 2>&1)"
command -v ssh     >/dev/null 2>&1 && baris "ssh"      "$(ssh -V 2>&1)"
command -v tar     >/dev/null 2>&1 && baris "tar"      "$(tar --version 2>&1 | head -1)"
command -v curl    >/dev/null 2>&1 && baris "curl"     "$(curl --version 2>&1 | head -1 | cut -c1-70)"

judul "9. PUSTAKA PYTHON YANG DIBUTUHKAN PIPELINE"
echo "  Ini isi requirements.txt Envirocircle. Yang belum ada bukan masalah,"
echo "  nanti dipasang di venv sendiri. Yang perlu diketahui cuma apakah"
echo "  python3-nya cukup baru dan pip-nya bisa memasang."
echo
if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY' 2>/dev/null || echo "  (python3 gagal dijalankan)"
# importlib.util WAJIB diimpor tersurat. `import importlib` saja TIDAK
# membawa submodul util-nya, dan galatnya baru muncul di baris find_spec.
import importlib, importlib.util, sys
print("  python  %s" % sys.version.split()[0])
print("  venv    %s" % ("ada" if importlib.util.find_spec("venv") else "TIDAK ADA, ini menghambat"))
for m in ["numpy","xarray","pillow","PIL","requests","netCDF4","contourpy","cfgrib","eccodes"]:
    try:
        mod = importlib.import_module("PIL" if m == "pillow" else m)
        v = getattr(mod, "__version__", "?")
        print("  %-10s ADA   %s" % (m, v))
    except Exception:
        print("  %-10s belum ada" % m)
PY
fi

judul "10. PENJADWAL"
echo "  Pipeline harian butuh salah satu dari ini hidup."
echo
printf '  %-24s ' "crontab milik saya"
if command -v crontab >/dev/null 2>&1; then
  if crontab -l >/dev/null 2>&1; then
    n=$(crontab -l 2>/dev/null | grep -vc '^\s*#')
    echo "BISA, $n baris terpasang sekarang"
    echo "  --- isi crontab sekarang ---"
    crontab -l 2>/dev/null | sed 's/^/  /'
    echo "  ----------------------------"
  else
    echo "crontab ada tapi DITOLAK buat pengguna ini"
  fi
else
  echo "TIDAK ADA"
fi
printf '  %-24s ' "systemd --user"
if command -v systemctl >/dev/null 2>&1 && systemctl --user status >/dev/null 2>&1; then
  echo "BISA"
else
  echo "tidak tersedia"
fi
printf '  %-24s ' "at"
command -v at >/dev/null 2>&1 && echo "ada" || echo "tidak ada"

judul "11. KUNCI SSH YANG SUDAH ADA DI MESIN INI"
echo "  Cuma didata NAMA dan sidik jarinya. Isi kunci privat TIDAK dibaca"
echo "  dan TIDAK ditampilkan."
echo
if [ -d "$HOME/.ssh" ]; then
  ls -la "$HOME/.ssh" 2>/dev/null | sed 's/^/  /'
  echo
  for k in "$HOME"/.ssh/*.pub; do
    [ -e "$k" ] || continue
    printf '  %-30s %s\n' "$(basename "$k")" "$(ssh-keygen -lf "$k" 2>/dev/null)"
  done
else
  echo "  ~/.ssh belum ada"
fi

judul "12. TEMPAT KERJA WRF, kalau ada"
for d in /home/*/WRF* /home/*/wrf* "$HOME"/BuildWRF "$HOME"/WRF*; do
  [ -d "$d" ] && printf '  %-44s %s\n' "$d" "$(du -sh "$d" 2>/dev/null | cut -f1)"
done 2>/dev/null
echo "  (kosong berarti tidak ketemu di jalur yang ditebak, bukan berarti tidak ada)"

judul "13. UJI TULIS DAN BUNGKUS"
CAP="$(mktemp -d 2>/dev/null)"
if [ -n "$CAP" ] && [ -d "$CAP" ]; then
  mkdir -p "$CAP/a/b"
  head -c 200000 /dev/urandom > "$CAP/a/b/isi.bin" 2>/dev/null
  if tar -czf "$CAP/uji.tar.gz" -C "$CAP" a 2>/dev/null; then
    baris "bungkus tar.gz" "BISA, $(du -h "$CAP/uji.tar.gz" 2>/dev/null | cut -f1)"
  else
    baris "bungkus tar.gz" "GAGAL"
  fi
  ln -sfn "$CAP/a" "$CAP/tautan" 2>/dev/null \
    && baris "symlink (tukar atomik)" "BISA" \
    || baris "symlink (tukar atomik)" "GAGAL"
  rm -rf "$CAP"
  baris "bersih bersih" "selesai"
else
  baris "mktemp" "GAGAL, /tmp tidak bisa ditulis"
fi

judul "14. BATAS PROSES"
ulimit -a 2>/dev/null | sed 's/^/  /'

echo
echo "===== SELESAI SURVEI $VERSI ====="
echo "Salin SELURUH keluaran di atas, dari baris MULAI sampai baris ini."
