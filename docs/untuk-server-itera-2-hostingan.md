# Envirocircle, hostingan dan cara mengirim

Untuk **yang memegang server ITERA**, dan untuk **Claude yang bekerja di server
itu**. Ditulis 5 September 2026.

Cara mengirim hasil masak, keadaan mesin tujuannya, cara dapat akses, dan apa yang dilakukan kalau jalannya buntu.

> Repo ini publik. Alamat server, nama pengguna, dan kunci **tidak ada di
> berkas manapun di sini**, semuanya lewat environment. Nilainya dikirim
> terpisah.

## Berkas lain di rangkaian ini

| berkas | isinya | untuk apa |
|---|---|---|
| [`0-baca-dulu`](untuk-server-itera-0-baca-dulu.md) | Baca dulu, orientasi | Peta besar sistemnya, apa yang sudah ada di server kalian, apa yang belum, dan apa yang kami tunggu. |
| [`1-data`](untuk-server-itera-1-data.md) | Data dan cara memasaknya | Bentuk berkas yang harus dihasilkan, pipeline yang sudah ada, dan batas domain unduhannya. Ini bagian yang paling teknis. |
| [`2-hostingan`](untuk-server-itera-2-hostingan.md) | Hostingan dan cara mengirim | Cara mengirim hasil masak, keadaan mesin tujuannya, cara dapat akses, dan apa yang dilakukan kalau jalannya buntu. |
| [`3-tampilan`](untuk-server-itera-3-tampilan.md) | Konteks tampilan | Bukan pekerjaan kalian. Ditulis supaya pilihan di sisi data konsisten dengan sisi tampilan. |

Isinya cuma backend dan hostingan. Sisi tampilan dikerjakan di tempat lain,
yang menghubungkan dua sisi cuma bentuk berkas keluaran, ada di `1-data`.

---

## 1. Cara mengirim ke hostingan


**Tulis sendiri skripnya, bebas.** Yang di bawah ini bukan perintah tentang
bentuk kodenya, tapi empat hal yang sudah terbukti perlu. Tiga dari empat baru
ketahuan setelah servernya diukur, jadi jangan dilewati.

**1. Satu tarball, jangan berkas satu satu.** Keluarannya ratusan berkas kecil,
dan lewat SFTP tiap berkas butuh bolak balik jaringan sendiri. Satu tar berarti
sekali sambung.

**2. Jangan pakai `rsync`.** Tidak ada di ujung sana dan tidak bisa dipasang.
Sudah dicek sampai `/usr/bin/rsync`, bukan soal PATH. Yang ada `tar`, `gzip`,
`scp`, dan sftp-server.

**3. Tukar secara atomik, per app.** Bongkar ke folder di sebelahnya dulu, baru
`mv`. Tanpa ini ada jendela beberapa detik waktu folder data setengah terisi
dan pengunjung melihat peta bolong.

```
output.baru  <- bongkar ke sini
output       -> output.lama
output.baru  -> output
output.lama  dibuang
```

**4. Coba ulang, jangan sekali tembak.** Ini yang paling mudah dilewatkan.
Waktu survei, **satu dari tiga sambungan SSH berturut turut kena
`Connection timed out`** sementara port 22 tetap terbuka dan situsnya tetap
hidup. Bukan diblokir, cuma tidak stabil. Sekali tembak akan gagal cepat atau
lambat, dan gagalnya di tengah malam. Minimal tiga percobaan dengan jeda.

Pasang ke cron sesudah pipeline selesai.

### Kalau mau contoh jadi

Ada di repo, `deploy/kirim-data-ke-hostingan.sh`, sudah memuat keempat hal di
atas. Boleh dipakai apa adanya, boleh cuma dibaca lalu ditulis ulang sesuai
bentuk pipeline kalian.

```
TUJUAN=<pengguna>@<alamat-hostingan> \
TUJUAN_DIR=/home/<pengguna>/public_html \
KUNCI=~/.ssh/<kunci-deploy> \
ASAL=/path/ke/folder/backend \
bash deploy/kirim-data-ke-hostingan.sh
```

`ASAL` menunjuk folder yang berisi `atmosight/data/output` dan
`smokewatch/data/output`. Tidak ada yang perlu dipindah.

### Persisnya mendarat di mana

Ini koordinat yang paling penting, jadi ditulis tersurat. Isi kedua folder
keluaran kalian harus berakhir di sini.

```
/home/<pengguna>/public_html/backend/atmosight/data/output/
/home/<pengguna>/public_html/backend/smokewatch/data/output/
```

Dua folder itu **sudah ada** di hostingan, dibuat waktu situsnya dipasang.
Kalian tinggal mengisinya.

Jadi `catalog.json` buatan kalian mendarat sebagai
`public_html/backend/atmosight/data/output/catalog.json`, dan gambar yang
disebut di dalamnya duduk sebagai tetangganya di folder yang sama.

**Jangan menyentuh apa pun di luar dua folder itu.** Sisi situsnya salinan
kerja git, dan apa pun yang kalian taruh di sana akan tertimpa waktu situsnya
diperbarui.

### PERINGATAN, kiriman pertama LANGSUNG dipakai

Ini yang paling penting di seluruh bagian ini, dan baru berlaku sejak
5 September.

Situsnya sekarang **memilih sumber datanya sendiri**. Dia mencoba data lokal di
hostingan dulu. Kalau `catalog.json` lokal menjawab 404, dia mundur menumpang
ke keluaran yang tersaji di GitHub Pages, hasil pipeline yang sama yang
dijalankan di runner GitHub.

Artinya, **detik kalian menaruh `catalog.json` di sana, situsnya berhenti
menumpang dan langsung memakai punya kalian.** Tidak ada tombol, tidak ada
pengumuman, tidak ada persetujuan siapa pun.

Akibatnya satu, dan tolong dibaca dua kali.

**Jangan menaruh keluaran yang belum utuh di hostingan.** Kalau `catalog.json`
sudah ada tapi gambar gambarnya belum, atau layernya baru sebagian, situsnya
akan memakai yang setengah itu dan **berhenti memakai data lengkap yang
sebelumnya tersaji**. Dari sisi pengunjung itu terlihat seperti situsnya rusak,
padahal cadangannya masih hidup dan baik baik saja.

Tukar atomik melindungi dari kiriman yang setengah tertulis, tapi **tidak**
melindungi dari kiriman yang utuh tapi isinya belum benar. Yang kedua itu
tanggung jawab kalian.

Jadi latihannya di tempat lain dulu. Kirim ke hostingan baru kalau keluarannya
sudah lengkap dan sudah diadu dengan pembanding, lihat berkas `0-baca-dulu`
bagian Tahapan.

### Cara memeriksa sesudah mengirim

Situsnya menulis sumber yang sedang dipakai ke atribut `data-sumber` pada
elemen `<html>`. Isinya `dekat` kalau memakai data kalian, `jauh` kalau masih
menumpang.

```
curl -s <alamat-situs>/atmosight/ | grep -o 'data-sumber="[a-z]*"'
```

Perhatikan, itu ditulis oleh JavaScript setelah halaman dimuat, jadi `curl`
biasa **tidak akan** menampilkannya. Cara yang bisa dipakai dari terminal,
periksa berkasnya langsung.

```
curl -s -o /dev/null -w "%{http_code}\n" \
  <alamat-situs>/backend/atmosight/data/output/catalog.json
```

`200` berarti data kalian sudah dipakai. `404` berarti belum ada dan situsnya
masih menumpang. Kalau mau memastikan lewat mata, buka situsnya lalu lihat
Console, ada baris `[data] sumber LOKAL` atau `[data] sumber menumpang`.

---

---

## 2. Fakta hostingan


Semua ini **diukur langsung di servernya**, bukan dibaca dari halaman jualan.

| hal | kenyataannya |
|---|---|
| `rsync` | **TIDAK ADA** dan tidak bisa dipasang. Jangan dipakai |
| yang ada | `tar` 1.30, `gzip`, `unzip`, `scp`, `sftp`, `git` 2.48.2, `curl`, `php` 8.2 |
| `python3` di PATH | 3.6.8, tua. Ada 3.12.14 lewat `/opt/alt/python312/bin/` |
| `node` | tidak di PATH, ada v22 lewat `/opt/alt/alt-nodejs22/root/usr/bin/` |
| disk dan bandwidth akun | tanpa batas |
| inode akun | tanpa batas |
| disk fisik mesin | **97% penuh**, sisa 25 GB, dipakai bersama semua pelanggan |
| CPU akun | 1 inti |
| RAM akun | 4 GB fisik, 2 GB virtual |
| I/O akun | 24 MB per detik |
| proses | maksimal 200 |
| SSH | port 22 standar, OpenSSH 8.0, **kadang putus** |
| server web | LiteSpeed, bukan Apache. HTTP/2 di HTTPS |
| kompresi | brotli sudah hidup bawaan, tidak perlu diurus |
| symlink | bisa, `ln -sfn` sudah diuji bolak balik |

Dua yang paling menentukan buatmu.

**Disk mesinnya 97 persen penuh dan itu disk bersama.** Jangan menaruh apa pun
yang mentah di sana. Kirim hasil jadinya saja, jangan GRIB, jangan nc 279 MB.

**Jangan menjalankan apa pun yang berat di hostingan.** Satu inti dan 24 MB per
detik, dan shared hosting umumnya melarang proses berat berkelanjutan. Memasak
tetap di ITERA. Ini bukan soal bisa atau tidak, ini soal akunnya bertahan atau
kena tegur.

---

---

## 3. Cara dapat akses


Kunci privat sebaiknya tidak berjalan jalan lewat chat atau flashdisk.
**Bikin kunci sendiri di server ITERA**, lalu kirim yang publiknya saja.

```
ssh-keygen -t ed25519 -N "" -C "kirim-data-dari-itera" \
  -f ~/.ssh/hostingan_deploy
cat ~/.ssh/hostingan_deploy.pub
```

Baris `.pub` itu yang dikirim ke pemilik hostingan buat ditempel ke
`~/.ssh/authorized_keys` di sana. Isi `hostingan_deploy` tanpa `.pub` tidak
perlu ke mana mana.

Sambungan pertama akan menanyakan sidik jari server. **Lakukan sekali secara
manual dulu**, kalau tidak, cron akan menggantung diam diam menunggu jawaban
yang tidak pernah datang.

---

---

## 4. Kalau port 22 dari ITERA ternyata buntu


Ini satu satunya hal yang belum terjawab. Jaringan kampus belum tentu
mengizinkan SSH keluar.

Cara mengetahuinya satu baris, tidak perlu skrip apa pun.

```
timeout 8 bash -c "exec 3<>/dev/tcp/<ip-hostingan>/22" \
  && echo "TEMBUS" || echo "BUNTU"
```

Kalau mau sekalian mendata seluruh keadaan server, ada
`deploy/survei-server-itera.sh` di repo. Hanya membaca, tanpa sudo, tidak
menyentuh berkas WRF, dan yang ditulis cuma berkas sementara di `/tmp` yang
dihapus lagi. Bagian 3 hasilnya yang menjawab pertanyaan di atas.

```
HOSTING_IP=<ip> HOSTING_NAMA=<nama-server> \
  bash deploy/survei-server-itera.sh 2>&1 | tee /tmp/survei-itera.txt
```

Kalau **BUNTU**, arah kirimnya dibalik. ITERA menaruh hasilnya di tempat
singgah lewat HTTPS, lalu hostingan menjemputnya sendiri lewat HTTPS. Dua arah
itu dua duanya sudah terbukti, hostingan sudah diuji bisa menjangkau GitHub,
dan ITERA memang sudah biasa menaruh keluaran WRF di GitHub Release. Kirim
hasil surveinya, nanti skripnya disesuaikan.

---
