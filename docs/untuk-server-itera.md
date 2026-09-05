# Envirocircle, konteks backend dan hostingan

Untuk **yang memegang server ITERA**, dan untuk **Claude yang bekerja di server
itu**. Ditulis 5 September 2026.

Berkas ini berdiri sendiri. Tidak perlu membaca berkas lain untuk memahaminya.

Isinya cuma backend dan hostingan. **Frontend sengaja tidak dibahas**, itu
dikerjakan di sisi lain. Yang menghubungkan dua sisi itu cuma satu hal, bentuk
berkas keluaran, dan itu ada di bagian Kontrak keluaran di bawah.

> Repo ini publik. Alamat server, nama pengguna, dan kunci **tidak ada di
> berkas ini**, semuanya lewat environment. Nilainya dikirim terpisah.

---

## 1. Bentuk sistemnya

Tiga mesin, dan tiap mesin cuma punya satu pekerjaan.

| mesin | pekerjaannya | siapa |
|---|---|---|
| **Server ITERA** | memasak data | kamu |
| **Hostingan** | menyajikan situs | mesin sewaan, cPanel |
| **GitHub** | menyimpan kode situs | repo publik |

Dua jalur masuk ke hostingan, dan **dua duanya tidak pernah saling menimpa**.

```
GitHub  --git pull-->  hostingan     kode situs, jarang berubah
ITERA   --ssh :22--->  hostingan     data hasil masak, tiap hari
```

Pemisahannya dijaga `.gitignore`. Folder `backend/*/data/output` diabaikan git,
jadi `git pull` di hostingan tidak pernah menyentuh datamu, dan kiriman datamu
tidak pernah menyentuh kode situs. Ini bukan kebetulan, ini yang membuat dua
orang bisa bekerja tanpa saling menimpa.

**Peranmu dua kalimat.** Masak datanya, lalu kirim hasilnya ke hostingan.
Selesai. Kamu tidak perlu menyentuh HTML, CSS, JavaScript, `.htaccess`, cache,
atau apa pun yang berbau tampilan.

---

## 2. Yang sudah ada di kamu, JANGAN diubah

Automasi WRF di server ITERA **sudah berjalan dan sudah benar**. Berkas ini
tidak meminta apa pun diubah di sana.

Yang sudah terbukti jalan sekarang.

- `run-prod.sh` dipanggil crontab tiap 30 menit. Itu **bukan penjadwal**, dia
  cuma bertanya apakah cycle hari ini sudah selesai.
- Cycle mulai **13.00 WIB**, yaitu 06.00 UTC, waktu GFS dianggap siap.
- WRF jalan sekitar **11 jam**.
- Berkas nc mendarat sekitar **00.50 WIB** hari berikutnya. Konsisten, sudah
  terpantau berturut turut.
- Hasilnya satu NetCDF-4, sekitar **279 MB**, di `~/wrf_post`.

Bentuk nc-nya, buat rujukan. Tiap variabel zlib complevel 4, 8 variabel float32
(`t2m` `rh2m` `mslp` `u10` `v10` `wspd10` `rain` `cldfra`), 73 langkah per jam,
grid 679 x 309 pada 9 km Mercator.

**Yang ditambahkan cuma satu langkah di ujungnya**, mengirim hasil jadi ke
hostingan.

Dua peringatan yang sudah pernah memakan korban.

- **Jangan mengganti `driver.sh` atau `run-prod.sh` selagi run jalan.** Ada
  celah peralihan yang bisa memicu `rm -f wrfout_d01_*`, dan hasil sebelas jam
  hilang. Ganti setelah nc mendarat, sebelum jam 13.00.
- **`cleanup.sh` ada di server tapi belum pernah dijadwalkan.** Berkas nc
  menumpuk di `~/wrf_post`. Masalah lama, belum darurat, tapi perlu dipasang ke
  crontab suatu saat.

---

## 3. Jalan penuhnya, dari sumber sampai layar

```
NOAA NOMADS ─┐
             ├──> [1] WRF Indonesia ──> nc lokal 279 MB ──┐
Copernicus ──┘         di ITERA                           │
                                                          v
                                             [2] Pipeline di ITERA
                                                          │
                                                  keluaran ~250 MB
                                                          │
                                                          v
                                             [3] kirim ssh :22
                                                          │
                                                          v
                                                    Hostingan ──> pengunjung
```

**GFS dipakai dua kali oleh dua tahap berbeda.** Sebagai syarat batas WRF, dan
sebagai model global untuk peta Atmosight. Itu bukan pemborosan, dua duanya
memang butuh.

Jam demi jam, dan jamnya sudah berjalan begitu sekarang.

| jam WIB | yang terjadi |
|---|---|
| 13.00 | GFS siap, tick memulai cycle. `do_wrf` menghapus wrfout lama dulu |
| 13.00 sampai 00.50 | WRF jalan, sekitar 11 jam |
| 00.50 | nc jadi, 279 MB, mendarat di `~/wrf_post`. Hari berikutnya |
| ~01.00 | pipeline mulai, **membaca nc dari disk yang sama** |
| ~02.00 | hasilnya dikirim ke hostingan, ditukar atomik |
| ~02.05 | peta terbaca dengan run hari ini |

**Berkas nc TIDAK perlu diunggah ke mana pun.** Selama ini dia harus naik ke
GitHub Release lalu diturunkan lagi, sebab yang memasak berada di runner
GitHub. Sekarang yang memasak ada di mesin yang sama, jadi cukup dibaca dari
disk. Dua perpindahan 279 MB per hari hilang, dan jeda tiga jam menunggu cron
GitHub jam 04.00 juga hilang.

---

## 4. Kontrak keluaran, ini satu satunya yang mengikat

Bebas memasak dengan cara apa pun. Yang mengikat cuma **bentuk hasilnya**.

Dua folder ini yang isinya nanti mendarat apa adanya di hostingan.

```
<ASAL>/atmosight/data/output/      keluaran peta cuaca
<ASAL>/smokewatch/data/output/     keluaran peta kualitas udara
```

`<ASAL>` boleh di mana saja, tinggal disebut lewat environment. Tidak ada path
mati yang harus dicocokkan, tidak ada yang perlu dipindah.

Di dalamnya, inilah yang dicari sisi tampilan. Nama nama ini **tidak boleh
berubah** tanpa memberi tahu, sebab dia yang menyatukan dua sisi pekerjaan.

| berkas | isinya |
|---|---|
| `catalog.json` | **daftar induk.** Menyebut semua layer, semua frame, jam run, dan nama berkas tiap frame |
| `<preview_image>` | gambar layer per frame, namanya disebut di catalog |
| `<velocity_json>` | medan u/v untuk partikel angin, namanya disebut di catalog |
| `point_meta.json` + `point_data.bin.gz` | data per titik, untuk popup klik di peta |
| `profile_meta.json` + `profile.bin.gz` | profil vertikal, untuk Skew-T |
| `city_data.json` | ringkasan per kota |
| `cyclones.json` `itcz.json` `isobars.json` | lapisan fenomena |
| `monsoon.json` `monsoon_velocity.json` `monsoon_velocity_bv.json` | monsun dan Borneo Vortex |

Kalau `catalog.json` tidak ada, situsnya **tetap tampil** dan masuk mode kosong
yang menjelaskan datanya belum ada. Itu bukan kerusakan, jangan diperbaiki.

Berkas geojson batas wilayah dan daftar kota **tidak** datang dari sini, itu
ikut kode situs.

Ukuran total dua folder sekitar **250 MB**.

---

## 5. Pipeline yang ada di repo ini

Kalau kalian mau memakai pipeline yang sudah ada, bukan menulis sendiri.

```
backend/atmosight/pipeline/     GFS, plus WRF Indonesia dan WRF Citarum
backend/smokewatch/pipeline/    CAMS, plus titik api FIRMS
```

Beberapa hal yang tidak kelihatan dari membaca kodenya.

**Dijalankan dari DALAM foldernya, bukan `python -m`.** Import-nya datar,
`from config import ...`.

```
cd backend/atmosight/pipeline && python run.py
cd backend/smokewatch/pipeline && python run.py
```

**`wrf_itera_run.py` menerima path berkas nc lokal.** Ini yang paling penting
buat kalian.

```
python wrf_itera_run.py /path/ke/wrf_itera_2026090500.nc
```

Bawaannya `backend/data/raw/wrf_itera/latest.nc`. Yang selama ini mengunduh nc
dari GitHub Release itu workflow, bukan skripnya. Karena sekarang satu mesin,
berkasnya cukup ditunjuk langsung.

**`cfgrib` dan `eccodes` tidak diimpor langsung di kode mana pun tapi tetap
WAJIB ada.** xarray memakainya sebagai mesin pembaca GRIB. Kalau dibuang,
galatnya baru muncul jauh di dalam saat runtime dan bunyinya membingungkan.

**`BACKEND_DIR` dihitung dari letak `config.py` sendiri**, jadi sisi Python
tidak punya path mati dan ikut ke mana pun foldernya dipindah.

**Dua kunci dibaca dari environment, tidak ada di repo.**

| variabel | untuk | wajib |
|---|---|---|
| `ADS_KEY` | Copernicus ADS, data CAMS | ya |
| `FIRMS_KEY` | NASA FIRMS, titik api | tidak, fiturnya cuma mati |

Saklar opsional, `WRF_ITERA_VELSTRIDE`, `WRF_ITERA_TRIM`, `WRF_JAM_MAX`,
`WRF_WORKERS`, `WRF_JENDELA`, `CAMS_RUN`, `SITE_DATA_URL`.

Ketergantungan Python ada di `requirements.txt`. Butuh Python 3.11 ke atas,
`numpy` 2.5 tidak jalan di bawah itu.

---

## 6. Cara mengirim ke hostingan

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

---

## 7. Fakta hostingan

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

## 8. Cara dapat akses

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

## 9. Kalau port 22 dari ITERA ternyata buntu

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

## 10. Yang JANGAN dilakukan

- **Jangan menyentuh apa pun di luar `backend/*/data/output` di hostingan.**
  Sisanya milik git dan akan tertimpa di `git pull` berikutnya.
- **Jangan menaruh kunci atau `.env` di repo ini.** Repo ini publik.
- **Jangan memakai `rsync`.** Tidak ada di ujung sana.
- **Jangan mengubah automasi WRF selagi run jalan.**
- **Jangan mengganti nama berkas keluaran** tanpa memberi tahu. Sisi tampilan
  mencarinya dengan nama, lihat bagian Kontrak keluaran.
- **Jangan mematikan yang lama sebelum yang baru terbukti.** GitHub Pages masih
  hidup, biarkan begitu sampai versi hostingan benar berhari hari.

---

## 11. Yang kami butuhkan darimu, dan ini yang paling ditunggu

Sisi tampilan mau digarap berdasar **keluaran yang sungguhan**, bukan tebakan.
Jadi yang paling berguna dikirim balik itu contoh keluaran asli.

**Pertama, daftar isi dan ukurannya.** Ini yang paling penting.

```
cd <ASAL>
for app in atmosight smokewatch; do
  echo "=== $app ==="
  du -sh $app/data/output
  find $app/data/output -type f | wc -l
  find $app/data/output -type f -printf '%10s  %p\n' | sort -k2 | head -40
done
```

**Kedua, berkas berkas kecil yang menentukan bentuk.** Semuanya ringan, total
di bawah beberapa ratus KB.

```
atmosight/data/output/catalog.json
atmosight/data/output/point_meta.json
atmosight/data/output/profile_meta.json
smokewatch/data/output/catalog.json
```

**Ketiga, satu frame contoh saja.** Satu gambar preview dan satu velocity json,
yang mana saja, sekadar untuk memastikan ukuran dan bentuknya.

**Keempat, hasil `deploy/survei-server-itera.sh`** kalau sudah sempat
dijalankan.

**Kelima, kunci publik** dari server ITERA, dan **jam berapa pipeline selesai**
supaya jadwal kirimnya pas.

Dengan lima itu, sisi tampilan bisa digarap tanpa menebak satu pun bentuk
berkas, dan waktu kiriman pertama datang, semuanya langsung cocok.
