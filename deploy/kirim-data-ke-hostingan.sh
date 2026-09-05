#!/usr/bin/env bash
# =====================================================================
# kirim-data-ke-hostingan.sh
#
# Mengirim HASIL MASAK dari server ke hostingan. Dijalankan DI SERVER
# yang memasak, biasanya lewat cron sesudah pipeline selesai.
#
# Yang dikirim CUMA isi backend/*/data/output. Kode situs TIDAK ikut,
# dia datang dari GitHub lewat pasang-di-hostingan.sh. Skrip ini dan
# skrip itu tidak pernah saling menimpa.
#
#   TUJUAN=pengguna@alamat-hostingan \
#   TUJUAN_DIR=/home/pengguna/public_html \
#   KUNCI=~/.ssh/kunci_deploy \
#   bash kirim-data-ke-hostingan.sh
#
# Alamat SENGAJA tidak ditulis di sini. Repo ini publik.
#
# Boleh juga menyebut ASAL, yaitu folder backend yang berisi keluaran.
# Bawaannya backend/ di sebelah skrip ini. Kalau pipeline kalian menaruh
# hasilnya di tempat lain, arahkan ke situ, TIDAK PERLU memindahkan
# apa pun. Yang penting bentuk di dalamnya:
#
#   <ASAL>/atmosight/data/output/
#   <ASAL>/smokewatch/data/output/
# =====================================================================
set -euo pipefail

: "${TUJUAN:?Set TUJUAN, contoh pengguna@alamat-hostingan}"
: "${TUJUAN_DIR:?Set TUJUAN_DIR, contoh /home/pengguna/public_html}"
KUNCI="${KUNCI:-$HOME/.ssh/id_ed25519}"
AKAR="$(cd "$(dirname "$0")/.." && pwd)"
ASAL="${ASAL:-$AKAR/backend}"
APP_LIST="${APP_LIST:-atmosight smokewatch}"

# Hostingan ini sambungannya TIDAK STABIL. Waktu survei, satu dari tiga
# sambungan berturut turut kena Connection timed out sementara port 22
# tetap terbuka dan situsnya tetap hidup. Bukan diblokir, cuma putus
# putus. Sekali tembak PASTI gagal cepat atau lambat, jadi tiap perintah
# jaringan di sini dicoba beberapa kali.
COBA="${COBA:-3}"
JEDA="${JEDA:-20}"

SSH_OPT=(-i "$KUNCI" -o StrictHostKeyChecking=yes -o ConnectTimeout=20 -o BatchMode=yes)

ulangi() {
  local n=1
  until "$@"; do
    if [ "$n" -ge "$COBA" ]; then
      echo "GAGAL setelah $COBA percobaan: $*" >&2
      return 1
    fi
    echo "  percobaan $n gagal, tunggu ${JEDA}s lalu ulangi" >&2
    n=$((n + 1))
    sleep "$JEDA"
  done
}

echo "== Kirim data ke hostingan =="
echo "  asal   $ASAL"
echo "  tujuan $TUJUAN:$TUJUAN_DIR"

# --- bungkus -----------------------------------------------------------
# Satu tarball, bukan ratusan berkas satu satu. Situsnya berisi ratusan
# berkas kecil, dan lewat SFTP tiap berkas butuh bolak balik jaringan
# sendiri. Satu tar berarti sekali sambung.
CAP="$(mktemp -d)"
trap 'rm -rf "$CAP"' EXIT
BUNGKUS="$CAP/data.tar.gz"

ADA=()
for app in $APP_LIST; do
  d="$ASAL/$app/data/output"
  if [ -d "$d" ] && [ -n "$(ls -A "$d" 2>/dev/null)" ]; then
    ADA+=("$app/data/output")
    printf '  %-12s %s berkas, %s\n' "$app" \
      "$(find "$d" -type f | wc -l)" "$(du -sh "$d" | cut -f1)"
  else
    printf '  %-12s kosong, dilewati\n' "$app"
  fi
done

if [ "${#ADA[@]}" -eq 0 ]; then
  echo "Tidak ada yang dikirim, semua folder keluaran kosong." >&2
  exit 1
fi

tar -czf "$BUNGKUS" -C "$ASAL" "${ADA[@]}"
echo "  bungkus $(du -h "$BUNGKUS" | cut -f1)"

# --- kirim -------------------------------------------------------------
CAP_JAUH="/tmp/envirocircle-data-$$.tar.gz"
echo "  mengirim"
ulangi scp "${SSH_OPT[@]}" "$BUNGKUS" "$TUJUAN:$CAP_JAUH"

# --- bongkar dan tukar --------------------------------------------------
# Ditukar PER APP dan secara atomik. Dibongkar ke folder di sebelahnya
# dulu, baru ditukar dengan mv. Tanpa ini, ada jendela beberapa detik
# waktu folder data setengah terisi dan pengunjung melihat peta bolong.
#
# Yang lama disimpan sebentar sebagai .lama lalu dibuang, jadi kalau mv
# kedua gagal, masih ada yang bisa dikembalikan tangan.
echo "  membongkar dan menukar"
ulangi ssh "${SSH_OPT[@]}" "$TUJUAN" "
  set -e
  for app in $APP_LIST; do
    HIDUP='$TUJUAN_DIR'/backend/\$app/data/output
    BARU=\"\$HIDUP.baru\"
    LAMA=\"\$HIDUP.lama\"
    rm -rf \"\$BARU\" \"\$LAMA\"
    mkdir -p \"\$BARU\"
  done

  mkdir -p /tmp/ec-bongkar-$$
  tar -xzf '$CAP_JAUH' -C /tmp/ec-bongkar-$$

  for app in $APP_LIST; do
    SUMBER=/tmp/ec-bongkar-$$/\$app/data/output
    [ -d \"\$SUMBER\" ] || continue
    HIDUP='$TUJUAN_DIR'/backend/\$app/data/output
    rm -rf \"\$HIDUP.baru\"
    mv \"\$SUMBER\" \"\$HIDUP.baru\"
    if [ -d \"\$HIDUP\" ]; then mv \"\$HIDUP\" \"\$HIDUP.lama\"; fi
    mv \"\$HIDUP.baru\" \"\$HIDUP\"
    rm -rf \"\$HIDUP.lama\"
    echo \"    \$app: \$(find \"\$HIDUP\" -type f | wc -l) berkas\"
  done

  rm -rf /tmp/ec-bongkar-$$ '$CAP_JAUH'
"

echo "  beres"
