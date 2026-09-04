#!/usr/bin/env bash
# Kirim situs ke server, tanpa GitHub Actions.
#
# Cara kerjanya, bungkus jadi tarball, kirim lewat ssh, bongkar di sebelah
# folder yang sedang hidup, baru ditukar. Penukaran terakhir itu satu perintah
# mv, jadi pengunjung tidak pernah melihat situs setengah jadi.
#
# JANGAN pakai rsync. Server tujuannya tidak punya rsync, sudah dicek.
#
# Alamat server SENGAJA tidak ditulis di sini. Isi lewat env, supaya berkas ini
# aman ikut masuk repo dan ikut dibagikan.
#
#   TUJUAN=pengguna@alamat-server \
#   TUJUAN_DIR=/home/pengguna/public_html \
#   KUNCI=~/.ssh/kunci_deploy \
#   bash deploy/kirim-ke-server.sh
#
# Yang dikirim cuma bagian yang disajikan ke browser. Pipeline Python TIDAK
# ikut, dia jalan di tempat lain atau di server yang sama lewat cron, dan
# keluarannya menulis langsung ke backend/*/data/output di server.
set -euo pipefail

: "${TUJUAN:?Set TUJUAN, contoh pengguna@alamat-server}"
: "${TUJUAN_DIR:?Set TUJUAN_DIR, contoh /home/pengguna/public_html}"
KUNCI="${KUNCI:-$HOME/.ssh/id_ed25519}"

AKAR="$(cd "$(dirname "$0")/.." && pwd)"
CAP="$(mktemp -d)"
BUNGKUS="$CAP/situs.tar.gz"

echo "Membungkus dari $AKAR"
tar -czf "$BUNGKUS" -C "$AKAR" \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='__pycache__' \
  --exclude='backend/*/data/raw' \
  --exclude='_*' \
  index.html style.css anim.js hero.js pm25-frames.json img vendor \
  atmosight smokewatch

echo "Ukuran $(du -h "$BUNGKUS" | cut -f1)"

# StrictHostKeyChecking dibiarkan menyala. Kalau sidik jari server berubah,
# kirimannya HARUS gagal, bukan diteruskan diam diam.
SSH="ssh -i $KUNCI -o StrictHostKeyChecking=yes"

echo "Mengirim"
scp -i "$KUNCI" "$BUNGKUS" "$TUJUAN:/tmp/situs.tar.gz"

echo "Membongkar dan menukar"
# shellcheck disable=SC2029
$SSH "$TUJUAN" "
  set -e
  BARU='$TUJUAN_DIR.baru'
  LAMA='$TUJUAN_DIR.lama'
  rm -rf \"\$BARU\" \"\$LAMA\"
  mkdir -p \"\$BARU\"
  tar -xzf /tmp/situs.tar.gz -C \"\$BARU\"

  # backend/*/data/output milik server, bukan milik kiriman. Isinya keluaran
  # pipeline yang jalan di sana, dan dia TIDAK boleh ikut terhapus waktu
  # situsnya diperbarui. Jadi dipindahkan dari yang lama ke yang baru.
  for app in atmosight smokewatch; do
    if [ -d '$TUJUAN_DIR'/backend/\$app/data/output ]; then
      mkdir -p \"\$BARU\"/backend/\$app/data
      mv '$TUJUAN_DIR'/backend/\$app/data/output \"\$BARU\"/backend/\$app/data/output
    fi
  done

  if [ -d '$TUJUAN_DIR' ]; then mv '$TUJUAN_DIR' \"\$LAMA\"; fi
  mv \"\$BARU\" '$TUJUAN_DIR'
  rm -rf \"\$LAMA\" /tmp/situs.tar.gz
  echo 'Selesai di server'
"

rm -rf "$CAP"
echo "Beres"
