# Envirocircle

Satu pohon berisi tiga hal.

| bagian | letak | isi |
|---|---|---|
| Landing page | akar | halaman perkenalan, hero animasi, Showcase, tim |
| Atmosight | `atmosight/` | peta cuaca, angin hujan suhu kelembapan awan tekanan |
| Smokewatch | `smokewatch/` | peta kualitas udara, ISPU AQI tujuh polutan |

Dulu ini tiga repo terpisah dengan pipeline masing masing di GitHub Actions.
Sekarang disatukan supaya bisa dipindah ke server sendiri tanpa Actions.

## Jalankan di komputer sendiri

```bash
python dev_server.py
```

Lalu buka salah satu.

```
http://127.0.0.1:8013/              landing page
http://127.0.0.1:8013/atmosight/    peta cuaca
http://127.0.0.1:8013/smokewatch/   peta kualitas udara
```

Server itu memasang header no-store untuk semua balasan. Itu perlu, sebab app
peta memuat ratusan PNG dan JSON yang namanya sama antar run. Tanpa itu browser
menyajikan frame kemarin dan orang mengira pipeline-nya rusak.

**Jangan buka lewat `file://`.** Browser memblokir pemuatan data dari sana, dan
app-nya memang sudah dibuat untuk menolak dengan pesan yang jelas.

## Data, keadaan sekarang

Pohon ini tidak membawa keluaran pipeline sama sekali, dan itu disengaja,
ukurannya ratusan MB. Tapi supaya petanya tetap berisi, untuk sementara
datanya **ditumpang dari keluaran repo lama** yang masih hidup dan masih
diperbarui tiap hari.

```
atmosight/app.js    DATA_JAUH -> .../atmosight/backend/data/output/
smokewatch/app.js   DATA_JAUH -> .../smokewatch/backend/data/output/
```

Ini TAMBALAN, bukan susunan akhir. Begitu pipeline jalan di server sendiri,
**kosongkan `DATA_JAUH`** di kedua berkas itu, dan dua duanya otomatis balik
memakai path relatif ke `backend/*/data/output/`. Tidak ada yang lain yang
perlu diubah.

Selama masih menumpang, jangan matikan repo lama `atmosight` dan `smokewatch`.

## Kalau DATA_JAUH dikosongkan

Kedua app akan terbuka dalam **mode kosong**. Peta, basemap, panel, dan seluruh
antarmukanya jalan normal, yang belum ada cuma lapisan datanya. Itu bukan
kerusakan. Keluaran pipeline itu ratusan MB dan tidak pantas ikut dikirim.

Untuk mengisinya.

```bash
cd backend/atmosight/pipeline
python run.py
```

```bash
cd backend/smokewatch/pipeline
python run.py
```

Hasilnya mendarat di `backend/atmosight/data/output/` dan
`backend/smokewatch/data/output/`. Muat ulang halamannya, mode kosong hilang
sendiri.

Sebelum itu pasang dulu dependensinya.

```bash
pip install -r requirements.txt
```

`cfgrib` dan `eccodes` ada di daftar itu walau tidak diimpor di kode mana pun.
Dua duanya dipakai xarray sebagai mesin pembaca GRIB waktu membuka berkas GFS.
Kalau dibuang, galatnya baru muncul jauh di dalam saat runtime.

## Kunci Smokewatch

Pipeline CAMS butuh kunci Atmosphere Data Store. Lihat
`backend/smokewatch/pipeline/config.py`. Titik api FIRMS butuh kunci sendiri
dan sifatnya opsional, tanpa kunci itu lapisannya saja yang tidak muncul.

## Susunan folder

```
index.html style.css anim.js hero.js   landing page
img/ vendor/ pm25-frames.json          aset landing
atmosight/                             frontend peta cuaca
smokewatch/                            frontend peta kualitas udara
backend/atmosight/pipeline/            pipeline GFS
backend/atmosight/data/output/         keluarannya, TIDAK masuk git
backend/smokewatch/pipeline/           pipeline CAMS
backend/smokewatch/data/output/        keluarannya, TIDAK masuk git
dev_server.py                          server lokal untuk ketiganya
```

Frontend menunjuk datanya dengan path relatif, `../backend/atmosight/data/output/`
dan `../backend/smokewatch/data/output/`. Susunan folder di atas itulah yang
membuat path tersebut benar. **Kalau folder dipindah, dua acuan itu ikut.**
Letaknya di `atmosight/app.js` baris 14 sampai 16 dan `smokewatch/app.js` baris 5.

Sisi pipeline tidak punya path mati. `BACKEND_DIR` dihitung dari letak
`config.py` itu sendiri, jadi dia ikut ke mana pun foldernya dipindah.

## Pilihan model

Dropdown MODEL di kedua app sudah memuat rencana lengkapnya. Yang belum ada
pipeline-nya ditampilkan **mati dan tidak bisa dipilih**, supaya rencananya
kelihatan tanpa menjanjikan sesuatu yang belum ada.

| app | hidup | dipajang, belum ada |
|---|---|---|
| Atmosight | GFS | ECMWF IFS, WRF 3 km, WRFDA 3 km |
| Smokewatch | CAMS | WRF-Chem, CAMx, CMAQ, FLEXPART |

Atmosight juga masih menyimpan WRF Citarum dan Private Model 9 km lengkap
dengan pipeline-nya, dua duanya dimatikan lewat `MODEL_AKTIF`.

**Menyalakan sebuah model butuh DUA tempat yang cocok.** Dropdown-nya di
`app.js`, dan langkah memasak datanya di pipeline. Kalau cuma yang di `app.js`
dinyalakan, dropdown-nya muncul tapi petanya kosong sebab berkasnya memang tak
pernah dibuat.

## Git cuma cadangan

Repo ini disimpan di GitHub sebagai cadangan, bukan sebagai tempat menjalankan
pipeline. Tidak ada workflow di pohon ini, dan itu disengaja. Yang menjalankan
pipeline dan menyajikan situsnya adalah server sendiri.
