# Envirocircle, kunci API yang dibutuhkan

Susulan untuk `untuk-server-itera.md`. Daftar lengkap kredensial yang perlu ada
di server supaya pipeline jalan penuh.

Didata dengan menyisir seluruh kode dan workflow, bukan dari ingatan.

> **Tidak ada satu pun nilainya di berkas ini.** Repo ini publik. Yang ada cuma
> nama variabel, cara mendapatkannya, dan cara mengujinya.

---

## Ringkasnya

| variabel | untuk | wajib | kalau tidak ada |
|---|---|---|---|
| `ADS_KEY` | Copernicus ADS, data CAMS | **YA** | pipeline Smokewatch mati total |
| `FIRMS_KEY` | NASA FIRMS, titik api | tidak | layer titik api dilewati, sisanya jalan |
| `GH_TOKEN` | unggah nc ke GitHub Release | **jadi tidak perlu** | lihat bagian 3 |

**Cuma satu yang benar benar wajib**, yaitu `ADS_KEY`.

Dan satu kabar bagus, **GFS tidak butuh kunci apa pun.** NOAA NOMADS terbuka
untuk umum. Sudah dicek ke workflow Atmosight, tidak memakai satu pun secret.
Jadi seluruh peta cuaca, termasuk WRF, bisa jalan tanpa kredensial.

---

## 1. `ADS_KEY`, wajib

Kunci Copernicus Atmosphere Data Store. Dipakai pipeline Smokewatch untuk
menarik data CAMS, dan tanpa dia seluruh peta kualitas udara tidak bisa dimasak.

### Mengambilnya

Masuk ke `https://ads.atmosphere.copernicus.eu/`, buat akun kalau belum punya,
lalu buka **halaman profil**. Di situ ada **Personal Access Token**. Bisa
dilihat kapan saja, jadi tidak perlu takut hilang.

Gratis, cuma perlu mendaftar dan menyetujui lisensi datasetnya. Lisensi itu
perlu diklik sekali di halaman dataset, kalau belum, permintaan ditolak
walaupun kuncinya benar.

### Cara kode membacanya

Dari env `ADS_KEY`, dikirim sebagai header `PRIVATE-TOKEN`.

Kalau env kosong, dia mundur mencari berkas `~/.cdsapirc` lalu mengambil baris
yang diawali `key:`. Ada juga jalur cadangan ke sebuah path Windows, itu sisa
dari laptop dan **tidak relevan di server**, abaikan saja.

### Memasangnya

```
export ADS_KEY="isi-token-nya"
```

Atau lewat berkas, kalau lebih suka tidak menaruhnya di env.

```
printf 'url: https://ads.atmosphere.copernicus.eu/api\nkey: isi-token-nya\n' \
  > ~/.cdsapirc
chmod 600 ~/.cdsapirc
```

### Mengujinya

```
curl -s -o /dev/null -w "%{http_code}\n" \
  -H "PRIVATE-TOKEN: $ADS_KEY" \
  https://ads.atmosphere.copernicus.eu/api/retrieve/v1/jobs
```

`200` berarti kuncinya diterima. `401` atau `403` berarti ditolak.

### Yang perlu diketahui soal ADS

ADS **kadang membalas job dengan status `failed`** padahal permintaannya benar
dan kuncinya benar. Itu terjadi di sisi mereka, bukan sisi kita, dan mengirim
ulang tidak dipungut apa apa.

Kode di repo ini sudah menanganinya, dia mengirim ulang sampai 3 kali dengan
jeda 60 detik. Kalau kalian menulis sendiri, **tirukan itu**. Tanpa pengiriman
ulang, satu balasan `failed` membunuh seluruh deploy dan data sehari hilang.
Ini sudah pernah terjadi.

---

## 2. `FIRMS_KEY`, tidak wajib

Kunci NASA FIRMS, di dokumentasi mereka namanya **MAP_KEY**. Dipakai untuk
overlay titik panas VIIRS di Smokewatch.

**Ini pengamatan satelit, bukan ramalan.** Kalau kuncinya tidak ada, layer titik
apinya dilewati dan pipeline tetap selesai. Tidak ada yang rusak.

### Mengambilnya

Buka `https://firms.modaps.eosdis.nasa.gov/api/area/`, isi email di formulir
Get MAP_KEY. Gratis, kuncinya dikirim ke email dalam hitungan menit.

### Cara kode membacanya

Dari env `FIRMS_KEY`, kalau kosong mundur ke berkas `~/.firms_key` yang isinya
kuncinya saja satu baris.

### Memasangnya

```
export FIRMS_KEY="isi-map-key-nya"
```

### Mengujinya

```
curl -s "https://firms.modaps.eosdis.nasa.gov/api/area/csv/$FIRMS_KEY/VIIRS_SNPP_NRT/100,-10,110,0/1" \
  | head -3
```

Kalau benar, keluar baris judul CSV. Kalau salah, keluar pesan galat berupa
teks biasa.

**Jebakan.** FIRMS kadang membalas **HTTP 200 tapi isinya pesan galat**, bukan
data. Jadi jangan cuma memeriksa kode HTTP-nya, periksa juga isinya.

---

## 3. `GH_TOKEN`, dan kenapa nanti tidak perlu lagi

Sekarang `driver.sh` di server memakai `gh release upload` untuk menaruh berkas
nc WRF ke GitHub Release, dan itu butuh token GitHub.

**Setelah pipeline pindah ke server, langkah itu hilang.**

Alasannya, nc-nya dinaikkan ke Release cuma karena yang memasak berada di runner
GitHub, jadi berkasnya harus keluar dulu supaya bisa diambil dari sana. Begitu
yang memasak ada di mesin yang sama, `wrf_itera_run.py` tinggal menunjuk
berkasnya di disk.

```
python wrf_itera_run.py ~/wrf_post/wrf_itera_<tanggal>00.nc
```

Jadi `GH_TOKEN` **boleh dilepas** kalau langkah unggah Release dimatikan.

**Satu pengecualian.** Kalau ternyata port 22 dari server ke hostingan buntu,
rencana cadangannya memakai GitHub Release sebagai tempat singgah. Kalau jalur
itu yang dipakai, `GH_TOKEN` tetap perlu. Jadi jangan buru buru menghapus
tokennya sebelum uji port 22 dijawab.

---

## 4. Yang TIDAK butuh kunci

Ini menghemat waktu kalian, jadi disebut sekalian.

| sumber | kunci |
|---|---|
| NOAA NOMADS, GFS | **tidak perlu**, terbuka untuk umum |
| GFS sebagai syarat batas WRF | **tidak perlu**, sumber yang sama |
| Basemap peta, Esri World Dark Gray | **tidak perlu**, sudah dipilih yang keyless |

Soal basemap itu sengaja. Dulu pakai CARTO dan mereka menghentikan akses tanpa
kunci, ubinnya jadi bertempel watermark. Sudah dipindah ke Esri yang gratis
tanpa kunci. Jangan diganti balik.

---

## 5. Bukan kunci API, tapi tetap kredensial

**Kunci SSH untuk mengirim ke hostingan.** Ini yang kalian bikin sendiri di
server, lalu publiknya dikirim ke pemilik hostingan. Caranya ada di
`untuk-server-itera.md` bagian Cara dapat akses.

**Dua sandi gerbang di frontend**, `WRF_SANDI` dan `DT_SANDI`. Itu tertulis
apa adanya di JavaScript, jadi memang sudah terbaca publik sejak dulu. Bukan
pengaman sungguhan dan bukan urusan kalian, disebut cuma supaya tidak dikira
kebocoran waktu ketemu di kode.

---

## 6. Cara menyimpannya di server

**Jangan pernah menaruh nilainya di repo.** Repo ini publik.

Cara yang rapi, satu berkas env di luar repo, lalu dipanggil dari skrip cron.

```
cat > ~/.envirocircle.env <<'EOF'
ADS_KEY=isi-token-ads
FIRMS_KEY=isi-map-key-firms
EOF
chmod 600 ~/.envirocircle.env
```

Lalu di skrip yang dipanggil cron, muat dulu sebelum menjalankan pipeline.

```
set -a; . "$HOME/.envirocircle.env"; set +a
cd ~/envirocircle/backend/smokewatch/pipeline && python run.py
```

`chmod 600` itu bukan formalitas. Server ini dipakai bersama, dan tanpa itu
pengguna lain di mesin yang sama bisa membacanya.

**Jangan menaruh kunci langsung di baris crontab.** Isi crontab terbaca oleh
`ps` waktu jobnya jalan.

---

## Ringkasan tindakan

1. Ambil `ADS_KEY` di halaman profil Copernicus ADS. **Ini yang wajib.**
2. Ambil `FIRMS_KEY` di formulir NASA FIRMS kalau mau layer titik api.
3. Simpan dua duanya di `~/.envirocircle.env` dengan `chmod 600`.
4. Uji dua duanya dengan perintah `curl` di atas sebelum menjalankan pipeline.
5. `GH_TOKEN` biarkan dulu apa adanya sampai uji port 22 dijawab.
