# Envirocircle, data dan cara memasaknya

Untuk **yang memegang server ITERA**, dan untuk **Claude yang bekerja di server
itu**. Ditulis 5 September 2026.

Bentuk berkas yang harus dihasilkan, pipeline yang sudah ada, dan batas domain unduhannya. Ini bagian yang paling teknis.

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

## 1. Kontrak keluaran, ini satu satunya yang mengikat


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

---

## 2. Pipeline yang ada di repo ini


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

---

## 3. Domain unduhan, ini yang paling mudah salah


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
