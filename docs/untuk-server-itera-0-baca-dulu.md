# Envirocircle, baca dulu

Untuk **yang memegang server ITERA**, dan untuk **Claude yang bekerja di server
itu**. Ditulis 5 September 2026.

Peta besar sistemnya, apa yang sudah ada di server kalian, apa yang belum, dan apa yang kami tunggu.

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

---

## 4. Tahapan, apa yang sudah jalan dan apa yang baru


Ini pembagian yang paling menentukan urutan kerja. Sekarang di server ITERA
**baru ada WRF**, dan itu berhenti di berkas nc. Belum ada satu pun yang
mengubah data mentah jadi berkas yang bisa ditampilkan.

| tahap | keadaan sekarang | jalan sekarang di mana |
|---|---|---|
| WRF Indonesia menghasilkan nc | **SUDAH ADA di ITERA** | ITERA |
| nc WRF jadi berkas peta | belum ada di ITERA | runner GitHub |
| GFS mentah jadi berkas peta | belum ada di ITERA | runner GitHub |
| CAMS mentah jadi berkas peta | belum ada di ITERA | runner GitHub |

Jadi tiga baris terakhir itulah pekerjaan yang baru. Kodenya **sudah ada dan
sudah terbukti jalan**, ada di `backend/` repo ini, cuma selama ini
dijalankan di tempat lain. Bukan menulis dari nol.

### Urutan yang disarankan, dari yang paling dekat

**1. nc WRF jadi berkas peta.** Mulai dari sini. Berkas nc-nya sudah ada di
disk kalian, jadi tidak perlu mengunduh apa apa, dan skripnya menerima path
lokal.

```
python wrf_itera_run.py ~/wrf_post/wrf_itera_<tanggal>00.nc
```

Kalau ini jalan, sudah terbukti venv dan seluruh pustakanya benar, dan itu
modal untuk dua tahap berikutnya.

**2. GFS mentah jadi berkas peta.** Ini yang paling besar. Perlu mengunduh
sekitar 2 GB dari NOAA NOMADS tiap hari. Perhatikan, **GFS yang ini beda
keperluan dengan GFS yang jadi syarat batas WRF**. Yang ini untuk model global
yang ditampilkan di petanya sendiri, cakupannya jauh lebih luas dari domain
WRF. Dua duanya memang perlu.

**3. CAMS mentah jadi berkas peta.** Perlu `ADS_KEY`. Paling kecil urusannya
kalau kuncinya sudah ada.

### Ada pembanding, pakai itu untuk memeriksa hasil

Keluaran ketiga tahap itu **sedang tersaji sekarang**, hasil pipeline yang sama
yang dijalankan di runner GitHub. Jadi kalian punya jawaban untuk dicocokkan.

```
https://bungakertas-py.github.io/atmosight/backend/data/output/catalog.json
https://bungakertas-py.github.io/smokewatch/backend/data/output/catalog.json
```

Kalau `catalog.json` buatan kalian punya id layer dan jumlah frame yang sama,
berarti sudah benar. Itu cara memeriksa yang jauh lebih cepat daripada membuka
petanya satu satu.

---

---

## 5. Yang JANGAN dilakukan


- **Jangan menyentuh apa pun di luar `backend/*/data/output` di hostingan.**
  Sisanya milik git dan akan tertimpa di `git pull` berikutnya.
- **Jangan menaruh kunci atau `.env` di repo ini.** Repo ini publik.
- **Jangan memakai `rsync`.** Tidak ada di ujung sana.
- **Jangan mengubah automasi WRF selagi run jalan.**
- **Jangan mengganti nama berkas keluaran** tanpa memberi tahu. Sisi tampilan
  mencarinya dengan nama, lihat Kontrak keluaran di berkas `1-data`.
- **Jangan mematikan yang lama sebelum yang baru terbukti.** GitHub Pages masih
  hidup, biarkan begitu sampai versi hostingan benar berhari hari.

---

---

## 6. Yang kami butuhkan darimu


**Bukan `catalog.json`.** Kami sudah punya, ditarik dari keluaran yang sedang
tersaji. Sisi tampilan sudah bisa digarap tanpa menunggu kalian, dan memang
itu yang sedang jalan sekarang.

Yang benar benar berguna dikirim balik cuma empat, dan **tidak ada yang
mendesak**. Kerjakan kalau pipeline sedang tidak jalan.

**1. Apakah port 22 dari ITERA tembus ke hostingan.** Satu baris, tidak
menulis apa apa, aman dijalankan kapan saja termasuk selagi WRF jalan.

```
timeout 8 bash -c "exec 3<>/dev/tcp/<ip-hostingan>/22" \
  && echo "TEMBUS" || echo "BUNTU"
```

Ini yang paling menentukan. Kalau BUNTU, bentuk kirimannya harus diubah.

**2. Kunci publik dari server ITERA**, supaya bisa ditempel ke hostingan.
Cukup keluaran `cat ~/.ssh/<nama>.pub`, satu baris.

**3. Jam berapa pipeline selesai**, supaya jadwal kirimnya pas dan tidak
menabrak run berikutnya.

**4. Keadaan mesinnya**, kalau sempat. Versi python, ada tidaknya venv, sisa
disk, dan boleh tidaknya cron. Ada `deploy/survei-server-itera.sh` di repo yang
mendata semuanya sekaligus, tapi kalau kalian tidak mau menjalankan skrip
selagi run WRF berlangsung, ini setara dan bisa ditempel satu satu.

```
python3 --version
python3 -c "import venv; print('venv ada')"
df -h $HOME
crontab -l
```

Semuanya hanya membaca dan tidak menyentuh berkas WRF sama sekali.

**Nanti**, kalau tahap 1 di bagian Tahapan sudah jalan dan `catalog.json` buatan
kalian sudah ada, kirim itu. Bukan untuk kami pakai, tapi untuk diadu dengan
yang sedang tersaji, memastikan bentuknya cocok sebelum kiriman pertama.
