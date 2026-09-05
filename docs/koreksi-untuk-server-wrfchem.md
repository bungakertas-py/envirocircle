# Koreksi untuk sistem WRF-Chem, dari sisi frontend

Balasan atas `DARI-SERVER-untuk-frontend-model-wrfchem.md`. Ditulis 5 September
2026 sesudah dokumen itu dicocokkan baris per baris ke kode frontend.

Sebagian besar rancangan kalian **cocok apa adanya**. Yang di bawah ini cuma
yang perlu diubah, plus jawaban atas pertanyaan kalian.

Frontend-nya **sudah disiapkan dan sudah tayang**. Begitu kiriman kalian
mendarat di folder yang benar, petanya langsung berisi tanpa perlu deploy lagi.

---

## 1. KOREKSI PALING PENTING, folder tujuannya

Dokumen kalian bagian 6 menulis folder tujuan seperti ini.

```
public_html/backend/atmosight/data/output/
public_html/backend/smokewatch/data/output/
```

**Jangan pakai itu.** Folder akar sekarang sengaja dibiarkan KOSONG. Kalau
`catalog.json` kalian mendarat di akar, dia menimpa catalog model yang sudah
jalan, dan yang hilang justru model yang sudah hidup.

Yang benar, tiap model punya sub-foldernya sendiri.

| keluaran kalian | folder tujuan |
|---|---|
| meteorologi | `public_html/backend/atmosight/data/output/wrfchem_9km_meteo/` |
| kimia | `public_html/backend/smokewatch/data/output/wrfchem_9km_kimia/` |

Semua isinya masuk ke sub-folder itu, bukan cuma `catalog.json`. Termasuk
gambar preview, `velocity_json`, `point_meta.json`, `point_data.bin.gz`, dan
`city_data.json`.

Namanya sengaja sebapak, `wrfchem_9km_meteo` dan `wrfchem_9km_kimia`, supaya
terbaca jelas bahwa dua duanya berasal dari SATU run yang sama.

### Susunan lengkapnya sekarang

Biar kalian punya gambaran utuh dan tidak salah taruh.

```
atmosight/data/output/gfs/                    GFS 28 km
atmosight/data/output/wrfchem_9km_meteo/      PUNYA KALIAN, meteorologi
atmosight/data/output/wrf_citarum/            arsip, belum dinyalakan

smokewatch/data/output/cams/                  CAMS 44 km
smokewatch/data/output/wrfchem_9km_kimia/     PUNYA KALIAN, kimia
```

---

## 2. Nama model di tampilan, sudah diputuskan

Kalian menanyakan mau dinamai apa. Ini jawabannya, dan dua duanya sudah
terpasang.

| app | label di dropdown |
|---|---|
| AtmoSight | **WRF - 9 km** |
| SmokeWatch | **WRFCHEM - 9 km** |

Perhatikan, di AtmoSight namanya **bukan lagi "Private Model"**. Nama itu
diganti hari ini atas keputusan pemilik. Kalau di dokumen atau skrip kalian ada
yang menyebut Private Model, itu boleh diabaikan, tidak ada akibatnya ke data.

Ejaan `WRFCHEM` tanpa hubung itu memang disengaja, jangan dirapikan.

---

## 3. Flag keandalan, DIAMBIL

Usulan kalian di bagian 5 diterima. Kirim saja `reliability` per layer di
`catalog.json`.

```json
"o3": { "kind": "scalar", "reliability": "terbatas", "frames": [] }
```

Frontend mengabaikan field yang belum dipakai, jadi mengirimnya sekarang tidak
merusak apa pun walaupun tandanya belum digambar di tampilan.

Nilai yang dipakai ikut istilah kalian sendiri, `andal`, `terbatas`, `mentah`.

---

## 4. Layer opsional, tidak usah dipaksakan

`aod`, `paparan`, dan keempat `dt_*` **tidak wajib**. Kalau tidak dikirim,
tombolnya mati sendiri dan tidak ada yang rusak. Penjagaannya sudah ada.

Kirim kalau memang sudah siap, jangan ditahan demi kelengkapan.

---

## 5. SATU PERTANYAAN BALIK, dan ini penting

**Satuan parameter kimia kalian sama persis dengan CAMS atau tidak?**

Alasannya begini. Frontend memakai **palet dan ambang warna yang sama** untuk
id layer yang sama, tidak peduli modelnya apa. Ambang itu diturunkan dari
pipeline CAMS.

Jadi kalau `pm25` kalian juga dalam mikrogram per meter kubik, warnanya berarti
hal yang sama dan tidak ada yang perlu diubah. Kalau skalanya beda, petanya
akan berwarna sangat meyakinkan tapi salah baca, dan itu jenis kesalahan yang
tidak pernah memunculkan pesan galat.

Cukup dipastikan sekali. Kalau jawabannya sama, tidak ada kode yang berubah.

---

## 6. Yang TERNYATA lebih besar dari dugaan kalian, tapi sudah beres

Dokumen kalian bagian 7 menulis untuk SmokeWatch cukup "tambah satu entri model
di samping CAMS".

Kenyataannya, **SmokeWatch belum punya mesin pemilih model sama sekali**.
Dropdown MODEL di panelnya murni hiasan, semua pilihan selain CAMS ditandai
`disabled` dan tidak ada satu baris JS pun yang menyentuhnya.

Itu sudah dibangun hari ini, meniru pola yang sudah ada di AtmoSight. Peta
model, pemilihan lewat `?model=`, sumber data per model, dan dropdown yang
betul betul menyambung.

**Tidak ada yang perlu kalian kerjakan untuk ini.** Ditulis supaya kalian tahu
kenapa dugaan "cukup satu entri" itu meleset, kalau nanti ada model lain lagi.

---

## 7. Bounds, rancangan kalian sudah benar

Bagian 4 dokumen kalian sudah tepat dan tidak perlu diubah. Kedua app sekarang
membaca kotak per model dari `catalog.json` masing masing.

| field | dibaca | gunanya |
|---|---|---|
| `region.bounds` | ya | domain data, batas geser peta |
| `region.image_bounds` | ya | tempat gambar ditempel |
| `region.view_core` | ya | kotak tampilan awal |
| `region.frame_bounds` | opsional | kalau tidak ada, mundur ke `bounds` |

`view_core` itu penting untuk kalian. Tanpa dia, model 9 km se-Indonesia akan
dibingkai kotak global 68 sampai 174 BT, dan data kalian jadi tempelan kecil di
tengah separuh Asia. Contoh yang kalian tulis di bagian 8 sudah membawanya,
jadi teruskan begitu.

---

## 8. Yang TIDAK perlu kalian ubah

Supaya tidak ada waktu terbuang membetulkan yang sudah benar.

- **Pola nama berkas frame bebas.** Frontend membacanya dari `catalog.json`,
  tidak pernah menebak dari pola.
- **Field `level`** seperti `"10 m"` dan `"permukaan"` tidak dibaca sama sekali.
  Aman, tidak perlu disamakan dengan model lain.
- **Field `model_label`** tidak dipakai, label datang dari daftar di frontend.
  Boleh tetap dikirim, tidak mengganggu.
- **Id layer kalian sudah dikenal semua.** Tidak ada yang perlu ditambahkan di
  sisi frontend, kecuali kalau nanti kalian menambah id yang betul betul baru.

---

## 9. Keadaan sekarang, dan apa yang terjadi waktu kalian kirim

Per 5 September 2026 sore, kedua folder tujuan itu **masih kosong**, isinya
cuma penanda folder dari repo. Belum ada kiriman yang mendarat.

Selama kosong, situsnya menumpang ke keluaran yang tersaji di GitHub Pages,
jadi peta tetap berisi dan tidak ada yang terlihat rusak.

Begitu `catalog.json` kalian mendarat, situs **langsung** memakainya dan
berhenti menumpang. Itu berlaku per model, jadi kiriman kalian tidak mengganggu
GFS dan CAMS yang masih menumpang.

Ingat peringatan yang sudah kalian sebut sendiri di bagian 6 dokumen kalian.
Jangan kirim sebelum keluarannya lengkap. Kiriman yang utuh tapi isinya belum
benar akan tetap dipakai, dan tukar atomik tidak melindungi dari itu.

---

## Ringkasan tindakan untuk kalian

1. **Ubah folder tujuan** ke dua sub-folder di bagian 1. Ini satu satunya yang
   wajib.
2. **Jawab pertanyaan satuan** di bagian 5.
3. Kirim `reliability` per layer kalau tidak merepotkan.
4. Sisanya jalan terus, tidak ada yang perlu diubah.
