# Catatan untuk Claude yang bekerja di pohon ini

Berkas ini dibaca otomatis. Isinya hal hal yang tidak kelihatan dari membaca
kode, dan beberapa jebakan yang sudah pernah memakan waktu.

## Bahasa

Seluruh komentar, dokumen, dan teks antarmuka **berbahasa Indonesia santai**.
Kalimat pendek. Tanpa em dash, tanpa titik dua di tengah kalimat, tanpa titik
koma. Nama berkas dan istilah teknis TIDAK diterjemahkan, tulis `catalog.json`
apa adanya, bukan "berkas katalog".

Ikuti kepadatan komentar yang sudah ada. Kode di sini komentarnya panjang dan
menjelaskan **alasan**, bukan mengulang apa yang sudah jelas dari kodenya.
Kalau kamu mengubah sesuatu yang punya komentar, komentarnya ikut diperbarui.
Komentar yang berbohong lebih buruk daripada tidak ada komentar.

## Bentuk pohon

Tiga bagian dalam satu pohon, dulu tiga repo terpisah.

```
akar            landing page, statis polos, tanpa bundler
atmosight/      frontend peta cuaca
smokewatch/     frontend peta kualitas udara
backend/atmosight/pipeline/    pipeline GFS, Python
backend/smokewatch/pipeline/   pipeline CAMS, Python
```

Kedua frontend itu app satu berkas yang besar, `app.js` sekitar 2700 dan 3000
baris. Jangan dipecah tanpa diminta.

## Jebakan yang sudah pernah kena

**Path data terikat pada susunan folder.** Frontend menunjuk datanya dengan
`../backend/atmosight/data/output/` dan `../backend/smokewatch/data/output/`.
Ada di `atmosight/app.js` baris 14 sampai 16 dan `smokewatch/app.js` baris 5.
Kalau folder dipindah, dua acuan itu WAJIB ikut. Sisi Python tidak punya path
mati, `BACKEND_DIR` dihitung dari letak `config.py` sendiri.

**Menyalakan model butuh dua tempat yang cocok.** Dropdown di `app.js` dan
langkah memasak di pipeline. Kalau cuma dropdown yang dinyalakan, pilihannya
muncul tapi petanya kosong sebab berkasnya tak pernah dibuat. Ini sudah pernah
terjadi.

**Data sekarang DITUMPANG dari repo lama.** Ada `DATA_JAUH` di kedua `app.js`
yang menunjuk keluaran `atmosight` dan `smokewatch` lama di GitHub Pages.
Itu tambalan sementara sebab pohon ini tidak membawa keluaran pipeline.
Kosongkan `DATA_JAUH` begitu pipeline jalan di server sendiri, dia otomatis
balik ke path relatif.

**Kalau `catalog.json` tidak ada**, Atmosight masuk `modeKosong()` dan
Smokewatch masuk mode cangkang. Dua duanya BUKAN kerusakan.
Jangan "memperbaiki" mode itu.

**Cache browser menipu.** App peta memuat ratusan PNG dan JSON dengan nama yang
sama antar run. Selalu pakai `dev_server.py`, dia memasang no-store. Kalau tidak,
kamu akan mengejar bug yang sebenarnya cuma frame kemarin.

**Screenshot headless menipu juga.** Chrome headless tidak menjalankan animasi
sampai selesai, jadi tangkapan layarnya sering menampilkan keadaan setengah
jalan padahal kodenya benar. Verifikasi lewat DOM dan `getBoundingClientRect`,
bukan lewat mata memandang gambar.

**Landing page tidak punya langkah build.** `import` modul TIDAK bisa dipakai
di sana. GSAP dipanggil sebagai script biasa dari `vendor/`. Cara memperbaruinya
ada di `CARA-PASANG.md`.

## Aturan gaya landing page

Neubrutalism. Garis 3px, bayangan keras tanpa blur, tombol yang benar benar
turun waktu ditekan. Huruf `Space Grotesk` untuk judul dan antarmuka,
`JetBrains Mono` untuk label kecil. Sudut membulat DIIZINKAN di landing, tapi
TIDAK di dalam app peta.

**Margin kiri kanan seluruh halaman satu token**, `--gutter` di `:root`.
Satu satunya yang tidak memakainya mentah adalah `.hero-bar`, dia
`calc(0.96 * var(--gutter) + 2vw)` supaya lambangnya segaris dengan huruf P
pada "Precise". Itu disengaja, jangan diseragamkan.

**Warna kontur hero dibaca dari token CSS**, bukan angka mati. Ada saklar
`PALET_KONTUR` di `hero.js`. Latar hero itu data PM2.5 CAMx asli 72 frame,
bukan hiasan.

Bayangan di atas latar gelap TIDAK boleh berwarna tinta, dia lenyap. Pakai
cyan atau teal yang digelapkan. Ini sudah dua kali kena.

## Server dan deploy

Situs ini menuju **server sendiri, lepas dari GitHub Actions**. Tidak ada
workflow di pohon ini dan itu disengaja. Git dipakai sebagai cadangan saja.

Bentuknya sudah diputuskan pemiliknya, **situs plus datanya sekalian**. Bukan
cuma memindahkan halamannya. Keluaran pipeline ikut naik ke hostingan, lalu
`DATA_JAUH` dikosongkan supaya jalurnya balik jadi relatif dan hostingan itu
berdiri sendiri, tidak lagi menumpang GitHub Pages.

Rinciannya di `docs/serah-terima.md`. Yang di bawah ini ringkasan yang
langsung mengubah cara menulis kode.

### Hostingan tujuannya, hasil ukur 5 September 2026

Semua di bawah ini **diukur langsung**, bukan dibaca dari dokumentasi.

**Server webnya LiteSpeed, bukan Apache.** Terbaca dari `lsapi_module` di
`.htaccess` bawaan dan folder `~/lscache`. Header `Server` disembunyikan.
HTTPS memberi HTTP/2.

**Kompresi brotli SUDAH HIDUP BAWAAN.** JSON 347 KB turun jadi 104 KB tanpa
diatur apa apa. Jangan buang waktu mengurusnya.
JEBAKAN, berkas kecil memang dilewati. **Uji kompresi wajib pakai berkas
ratusan KB**, kalau tidak kesimpulannya salah. Sudah pernah salah baca begitu.

**Yang TIDAK ada bawaan dan harus dikirim lewat `.htaccess`:**
- `cache-control`, sama sekali tidak dipasang. GitHub Pages memasangnya
  sendiri, hostingan ini tidak.
- `Options -Indexes`. Daftar isi folder MENYALA bawaan, folder tanpa index
  membalas 200 dan memajang seluruh isinya.

`mod_expires` dan `mod_headers` terbukti jalan, sudah diuji sampai keluar
`cache-control: public, max-age=3600` dan `access-control-allow-origin`.
MIME `.json` sudah benar bawaan.

**Jatah akun semuanya TANPA BATAS**, disk, inode, dan bandwidth. Yang dibatasi
cuma addon domain, maksimal 5, dan kita tidak membutuhkannya sebab jalurnya
berbasis folder. Jadi 866 berkas per app dan 250 MB data itu aman.

**`rsync` TIDAK ada di sana**, jadi kirim tarball lalu bongkar. `node` dan
`npm` juga tidak ada di PATH, tapi CloudLinux menyediakan `/opt/alt/alt-nodejs22`
dan `/opt/alt/python39` lewat selector cPanel.

**`python3` bawaan hostingan cuma 3.6.8, TUA.** Jangan dipakai untuk apa pun
yang serius. Kalau pipeline betulan dijalankan di sana, pakai alt-python atau
venv sendiri. `tar` 1.30, `git` 2.48.2, `php` 8.2.33.

**Disknya 97 persen penuh dan memburuk cepat**, sisa 25 GB, turun 7 GB dalam
dua hari. Itu disk fisik bersama semua pelanggan di mesin itu, bukan jatah
kita. Kebutuhan kita cuma 250 MB jadi muat, tapi jangan menaruh keluaran
mentah yang besar di sana.

**SSH KADANG PUTUS.** Terjadi sungguhan waktu survei, satu dari tiga sambungan
berturut turut kena `Connection timed out`, dua berikutnya tembus, sementara
port 22 tetap terbuka dan web tetap 200. Bukan diblokir, cuma tidak stabil.
**Skrip deploy JANGAN sekali tembak**, minimal tiga percobaan dengan jeda.

**Tukar atomik bisa.** `ln -sfn` menimpa symlink yang sudah ada, sudah diuji
bolak balik. Jadi pola bongkar ke folder baru lalu tukar symlink jalan di sana.

**Hostingan bisa keluar ke GitHub.** `github.com` dan GitHub Pages dua duanya
200 dari dalam server, dan `git` ada di sana. Jadi ada bentuk ketiga yang belum
pernah dipakai, hostingan yang MENARIK sendiri lewat `git pull` dari cron,
bukan didorong. Dicatat sebagai pilihan, belum diputuskan.

### Alamat

Jalurnya **berbasis folder**, `<akar>/atmosight` dan `<akar>/smokewatch`.
JANGAN dipecah ke subdomain. Pohon ini memakai tautan relatif, `atmosight/`
dari landing dan `../` dari tombol rumah di kedua app. Dipecah ke subdomain,
tautan itu putus semua.

Domain sungguhannya **belum hidup** waktu catatan ini ditulis, jadi pakai
alamat sementara dari penyedia untuk menguji. Pohon ini semua tautannya
relatif, jadi dia jalan apa adanya di bawah alamat mana pun.

### Rahasia, TIDAK ADA di pohon ini dan jangan pernah dimasukkan

Repo ini **PUBLIK**. Jangan pernah menaruh kunci, password, atau berkas `.env`
di dalamnya.

Pipeline membaca dua kunci dari environment.

| variabel | untuk | wajib |
|---|---|---|
| `ADS_KEY` | Copernicus ADS, sumber data CAMS Smokewatch | ya |
| `FIRMS_KEY` | NASA FIRMS, titik api | tidak, fitur mati tanpa dia |

Ada juga beberapa saklar opsional, `SITE_DATA_URL`, `CAMS_RUN`,
`WRF_JAM_MAX`, `WRF_WORKERS`, `WRF_JENDELA`, `WRF_ITERA_VELSTRIDE`,
`WRF_ITERA_TRIM`, `WRF_ITERA_VERIFY`.

`WRF_SANDI` dan `DT_SANDI` di kedua `app.js` itu gerbang sisi browser. Memang
sudah terbaca publik sejak dulu, bukan kebocoran baru, tapi jangan
diperlakukan sebagai pengaman sungguhan.

### Menjalankan pipeline

Import-nya datar, `from config import ...`, jadi **BUKAN `python -m`**.
Yang benar masuk ke foldernya dulu.

```
cd backend/atmosight/pipeline && python run.py
cd backend/smokewatch/pipeline && python run.py
```

`cfgrib` dan `eccodes` tidak diimpor langsung di kode mana pun tapi tetap
WAJIB ada, xarray memakainya sebagai mesin pembaca GRIB. Kalau dibuang,
galatnya baru muncul jauh di dalam saat runtime dan bunyinya membingungkan.

## Yang harus ditanya dulu, jangan diputuskan sendiri

- Menyalakan model yang sekarang mati. Itu keputusan produk, bukan teknis.
- Mengubah chip nama model di kartu Showcase landing page. Isinya sengaja
  melebihi yang sudah jalan, dan pemiliknya sudah tahu.
- Menghapus WRF Citarum atau Private Model dari Atmosight. Dua duanya lengkap
  dengan pipeline, cuma dimatikan.
