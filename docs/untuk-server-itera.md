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
| `catalog.json` | **daftar induk.** Semua layer, semua frame, jam run, dan nama berkas tiap frame |
| `<preview_image>` | gambar layer per frame, namanya disebut di catalog |
| `<velocity_json>` | medan u/v untuk partikel angin, namanya disebut di catalog |
| `point_meta.json` + `point_data.bin.gz` | data per titik, untuk popup klik di peta |
| `profile_meta.json` + `profile.bin.gz` | profil vertikal, untuk Skew-T |
| `city_data.json` | ringkasan per kota |
| `cyclones.json` `itcz.json` `isobars.json` | lapisan fenomena |
| `monsoon.json` `monsoon_velocity.json` `monsoon_velocity_bv.json` | monsun dan Borneo Vortex |

Berkas geojson batas wilayah dan daftar kota **tidak** datang dari sini, itu
ikut kode situs.

Kalau `catalog.json` tidak ada, situsnya **tetap tampil** dan masuk mode kosong
yang menjelaskan datanya belum ada. Itu bukan kerusakan, jangan diperbaiki.

### Bentuk catalog.json, dari keluaran yang sedang hidup

Ini bukan contoh karangan, ini dibaca dari keluaran yang sedang tersaji
sekarang. `layers` itu **objek, bukan array**, kuncinya id layer.

```json
{
  "generated_at": "2026-09-04T23:02:55Z",
  "model": "GFS",
  "run_time": "2026-09-04T12:00:00Z",
  "region": { "bounds": [62.0, -33.0, 180.0, 33.0] },
  "akurasi": { },
  "layers": {
    "wind_surface": {
      "kind": "vector",
      "level": "surface",
      "units": "m/s",
      "frames": [
        {
          "valid_time": "2026-09-03T12:00:00Z",
          "forecast_step_hours": 6,
          "preview_image": "wind_surface_20260903_06_f006_preview.webp",
          "data_image":    "wind_surface_20260903_06_f006.png",
          "velocity_json": "wind_surface_20260903_06_f006_velocity.json",
          "speed_knots_max": 0
        }
      ]
    }
  }
}
```

Layer `vector` punya `data_image`, `velocity_json`, dan `speed_knots_max`.
Layer `scalar` tidak punya itu, dia punya `value_max`.

**Id layer yang hidup sekarang, dan jumlah frame-nya.**

| Atmosight, 11 layer | Smokewatch, 15 layer |
|---|---|
| `wind_surface` 33, vector | `ispu` 121 |
| `rain_surface` 33 | `aqi` 121 |
| `rain_accum_surface` 3 | `paparan` 121 |
| `temp_surface` 33 | `pm25` 6, `pm10` 6 |
| `humidity_surface` 33 | `co` `no2` `so2` `o3` 121 |
| `cloud_surface` 33 | `aod` 121, `pbl` 121 |
| `pressure_surface` 33 | `dt_pm25` `dt_pm10` 121 |
| `storm_potential` 33, `cin_surface` 33 | `dt_so2` `dt_no2` 121 |
| `wind_strato` 33 vector, `temp_strato` 33 | |

**Id itu bukan sekadar nama.** Sisi tampilan memakainya untuk memilih palet
warna dan legenda. Id baru yang tidak dikenal akan muncul di dropdown tapi
petanya kosong. Menambah layer itu boleh, tapi kabari dulu.

**Bobot per frame, buat perkiraan.** Satu `preview_image` sekitar 185 KB, satu
`velocity_json` sekitar **4,5 MB**. Yang terakhir itu yang paling menentukan
ukuran total, jadi kalau suatu saat perlu dipangkas, di situ tempatnya.

`point_meta.json` dan `profile_meta.json` isinya tata letak berkas biner di
sebelahnya, `nx` `ny` `dx` `dy` `bounds` `times` `vars`, dan tiap `vars`
menyebut `dtype` `scale` `offset` `byteOffset` `byteLength`. Sisi tampilan
membaca `.bin.gz` berdasar angka angka itu, jadi kalau tata letaknya berubah,
meta-nya harus ikut berubah di saat yang sama.

Ukuran total dua folder sekitar **250 MB**.

### Melihat sendiri keluaran yang sedang hidup

Tidak perlu menunggu siapa pun. Keluaran yang sekarang tersaji ada di sini dan
bisa diambil kapan saja.

```
https://bungakertas-py.github.io/atmosight/backend/data/output/catalog.json
https://bungakertas-py.github.io/smokewatch/backend/data/output/catalog.json
```

Itu keluaran pipeline yang sama, cuma dijalankan di tempat lain. Bentuknya
persis yang harus kalian hasilkan.

---

## 5. Yang sudah ada di kamu, dan yang belum

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

## 6. Pipeline yang ada di repo ini

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

## 7. Domain unduhan, ini yang paling mudah salah

Kalau domain unduhannya beda, seluruh peta melenceng, dan **melencengnya halus**
sehingga tidak terlihat seperti kerusakan. Angka di bawah ini bukan pilihan
bebas, dia harus sama persis dengan yang sekarang.

### Satu domain, dipakai GFS dan CAMS

```python
REGION = {
    "left_lon":    62.0,    # 62E,  Laut Arab / India barat
    "right_lon":  180.0,    # 180E, Pasifik Barat, batas antemeridian
    "top_lat":     33.0,    # 33N,  Cina Selatan plus margin
    "bottom_lat": -33.0,    # 33S,  melewati tengah Australia
}
```

118 derajat bujur kali 66 derajat lintang.

**Kenapa selebar itu, padahal yang dipetakan Indonesia.** Domain DATA sengaja
dibuat **lebih luas dari area tampilan**, supaya waktu pengunjung menggeser dan
memperbesar peta, tepi datanya tidak pernah terlihat. Yang benar benar tampak
sekitar 68 sampai 174 BT dan 28 LS sampai 28 LU, jadi ada margin 5 sampai 6
derajat di tiap sisi. Rasionya juga sengaja, 118 banding 66 itu sekitar 1,75,
dekat dengan layar 16:9, jadi waktu difit ke layar hampir mengisi penuh.

**Jangan dipersempit demi menghemat.** Yang hemat sedikit, yang rusak tepinya.

### JEBAKAN TERBESAR, tiga API tiga urutan kotak batas

Ini yang paling sering bikin data melenceng, dan galatnya tidak pernah muncul.
Permintaannya diterima, datanya turun, cuma isinya wilayah yang salah.

| API | bentuk | urutannya | nilainya untuk domain kita |
|---|---|---|---|
| **GFS** NOMADS | parameter terpisah | `leftlon` `rightlon` `toplat` `bottomlat` | `62`, `180`, `33`, `-33` |
| **CAMS** ADS | satu array | **utara, barat, selatan, timur** | `[33.0, 62.0, -33.0, 180.0]` |
| **FIRMS** | satu string | **barat, selatan, timur, utara** | `94.0,-11.5,141.5,7.5` |

Perhatikan CAMS dan FIRMS **terbalik satu sama lain**. CAMS mulai dari utara,
FIRMS mulai dari barat.

Perhatikan juga **FIRMS domainnya BEDA dan memang disengaja**, jauh lebih
sempit dan Indonesia-sentris. Titik api yang relevan untuk asap Indonesia ada
di kotak itu, memakai domain CAMS cuma menambah ribuan titik yang tidak ada
hubungannya.

### GFS, rinciannya

Diambil lewat endpoint filter NOMADS, jadi yang diunduh sudah tersubset di sisi
server dan berkasnya kecil, bukan GRIB global utuh.

```
https://nomads.ncep.noaa.gov/cgi-bin/filter_gfs_0p25.pl
  ?file=...&subregion=
  &leftlon=62.0&rightlon=180.0&toplat=33.0&bottomlat=-33.0
  &lev_<level>=on&var_<VAR>=on
```

| hal | nilainya |
|---|---|
| resolusi | `0p25`, 0,25 derajat |
| grid hasil | **473 x 265** |
| jam run | 00, 06, 12, 18 UTC |
| jeda aman | **5 jam** sesudah jam run baru dianggap tersedia |
| jendela frame | 24 jam ke belakang sampai 72 jam ke depan |

Grid 473 x 265 itu bukan angka hafalan, dia turunan.
`(180 - 62) / 0,25 + 1 = 473` dan `(33 + 33) / 0,25 + 1 = 265`.
Kalau hasil kalian bukan segitu, domainnya beda.

Variabel dan levelnya per layer.

| layer | variabel GRIB | level | catatan |
|---|---|---|---|
| `wind_surface` | `UGRD` `VGRD` | `10_m_above_ground` | vector, skala encoding -40..40 |
| `rain_surface` | `PRATE` | `surface` | **wajib `stepType: instant`** |
| `rain_accum_surface` | `PRATE` | `surface` | akumulasi 24 jam, harian |
| `temp_surface` | `TMP` | `2_m_above_ground` | K dikurangi 273,15 |
| `humidity_surface` | `RH` | `2_m_above_ground` | |
| `cloud_surface` | `TCDC` | `entire_atmosphere` | **wajib `stepType: instant`** |
| `pressure_surface` | `PRMSL` | `mean_sea_level` | Pa dikali 0,01 |
| `storm_potential` | `CAPE` | `surface` | |
| `cin_surface` | `CIN` | `surface` | nilainya negatif |
| `wind_strato` | `UGRD` `VGRD` | `70_mb` | skala encoding -50..50 |
| `temp_strato` | `TMP` | `70_mb` | |

**`stepType: instant` itu bukan hiasan.** `PRATE` dan `TCDC` punya DUA versi di
f003 ke atas, sesaat dan rata rata. Tanpa penyaring itu, yang terambil bisa
yang rata rata, dan hasilnya kelihatan masuk akal tapi salah.

**Profil vertikal** untuk Skew-T diambil terpisah, satu permintaan multi-level
per waktu, 22 level dari 1000 sampai 50 hPa, lalu dijarangkan tiap 4 titik grid
sehingga jadi sekitar 1 derajat. Hasilnya grid **119 x 67**.

### CAMS, rinciannya

```python
dataset = "cams-global-atmospheric-composition-forecasts"
api     = "https://ads.atmosphere.copernicus.eu/api"
area    = [33.0, 62.0, -33.0, 180.0]      # utara, barat, selatan, timur
data_format  = "netcdf_zip"
leadtime_hour = 0..120, langkah 1        -> 121 langkah
runs = ["00:00", "12:00"]
```

Grid CAMS 0,4 derajat, sekitar 44 km, jauh lebih kasar dari GFS. Itu wajar,
jangan dipaksa disamakan.

Variabelnya dua jenis, dan bedanya penting.

| jenis | artinya | contoh |
|---|---|---|
| `single` | variabel permukaan satu level | `pm25` `pm10` `aod` `pbl` |
| `model` | variabel 3D, **wajib minta `model_level: 137`** | `co` `no2` `so2` `o3` |

Model level 137 itu lapisan paling bawah, sekitar 10 m di atas tanah. Tanpa
menyebutnya, yang turun seluruh kolom dan berkasnya jadi raksasa.

| nama layer | variabel CAMS | nama di netcdf |
|---|---|---|
| `pm25` | `particulate_matter_2.5um` | `pm2p5` |
| `pm10` | `particulate_matter_10um` | `pm10` |
| `co` | `carbon_monoxide` | `co` |
| `no2` | `nitrogen_dioxide` | `no2` |
| `so2` | `sulphur_dioxide` | `so2` |
| `o3` | `ozone` | `go3` |
| `aod` | `total_aerosol_optical_depth_550nm` | `aod550` |
| `pbl` | `boundary_layer_height` | `blh` |

**`ispu`, `aqi`, `paparan`, dan keempat `dt_*` TIDAK diunduh.** Semuanya turunan
yang dihitung dari delapan di atas, jadi jangan dimasukkan ke permintaan.

`pm25` dan `pm10` **dirata-ratakan jadi harian**, sedangkan gas tetap per
langkah. Itu disengaja, baku mutu partikel memang memakai rata rata 24 jam,
sementara `no2` dan `o3` justru berubah tajam dalam sehari.

### Kalau domainnya memang perlu diubah

Boleh, tapi **tiga tempat harus berubah bersamaan**, dan ketiganya dibaca sisi
tampilan.

1. `REGION` di `config.py`
2. `region.bounds` di `catalog.json`
3. `bounds` di `point_meta.json` dan `profile_meta.json`

Gambar peta ditempel apa adanya ke `bounds`. Kalau `REGION` berubah tapi
`bounds` tidak, gambarnya diregangkan ke kotak yang salah, dan garis pantainya
akan meleset beberapa puluh kilometer tanpa satu pun pesan galat. **Kabari sisi
tampilan sebelum mengubahnya.**

---

## 8. Cara mengirim ke hostingan

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
sudah lengkap dan sudah diadu dengan pembanding di bagian 5.

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

## 9. Fakta hostingan

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

## 10. Cara dapat akses

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

## 11. Kalau port 22 dari ITERA ternyata buntu

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

## 12. Sisi tampilan, konteks tambahan

Bagian ini **bukan pekerjaanmu**. Ditulis supaya kamu tahu data itu dipakai
untuk apa, sebab keputusan di sisimu punya akibat di sisi sana, dan sebaliknya.

**Ada dua app peta**, dua duanya satu halaman statis, tanpa server dan tanpa
langkah build. Atmosight untuk cuaca, Smokewatch untuk kualitas udara.

**Frontend TIDAK memasak apa pun.** Dia membaca `catalog.json`, lalu menempel
gambar yang disebut di situ ke atas peta sebagai lapisan, satu gambar per
langkah waktu. Slider waktu di bawah cuma mengganti gambar mana yang tampil.
Partikel angin digambar dari `velocity_json`. Popup waktu peta diklik dibaca
dari `point_data.bin.gz` mengikuti tata letak di `point_meta.json`.

Artinya **semua kecerdasan ada di sisimu**. Kalau petanya salah, hampir selalu
datanya yang salah, bukan tampilannya.

Empat hal yang mengikat dua sisi, dan ini alasan kenapa konsistensi penting.

**Id layer memilih palet dan legenda.** `temp_surface` dapat skala warna suhu
lengkap dengan satuannya, `rain_surface` dapat skala hujan. Id yang tidak
dikenal muncul di daftar tapi petanya kosong dan legendanya salah.

**`run_time` jadi label "Last update" di layar.** Itu jam inisiasi model, bukan
jam situs diperbarui. Kalau salah isi, pengunjung membaca ramalan basi sebagai
ramalan baru, dan tidak ada tanda apa pun yang memberi tahu.

**`bounds` menentukan tempat gambarnya ditempel.** Gambar ditempel apa adanya
ke kotak itu. Salah `bounds` berarti petanya melenceng, dan melencengnya halus,
tidak kelihatan seperti kerusakan.

**Jumlah frame menentukan panjang slider.** Layer dengan jumlah frame berbeda
di satu model itu wajar, `rain_accum_surface` memang cuma 3, tampilannya sudah
menanganinya.

Dua hal yang **jangan diputuskan sendiri**, tanyakan dulu.

- **Menyalakan model yang sekarang mati.** Itu keputusan produk, bukan teknis,
  dan saklarnya ada di dua tempat yang harus cocok. Kalau cuma sisi data yang
  dinyalakan, pilihannya tidak muncul. Kalau cuma sisi tampilan, pilihannya
  muncul tapi petanya kosong.
- **Mengganti atau menambah id layer.** Boleh, tapi sisi tampilan harus tahu di
  saat yang sama.

---

## 13. Yang JANGAN dilakukan

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

## 14. Yang kami butuhkan darimu

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

**Nanti**, kalau tahap 1 di bagian 5 sudah jalan dan `catalog.json` buatan
kalian sudah ada, kirim itu. Bukan untuk kami pakai, tapi untuk diadu dengan
yang sedang tersaji, memastikan bentuknya cocok sebelum kiriman pertama.
