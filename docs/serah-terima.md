# Serah terima Envirocircle

Ditulis 5 September 2026, waktu seluruh pekerjaan dipindah dari laptop ke
server. Ditujukan untuk **Claude yang bekerja di server**, dan untuk siapa pun
yang melanjutkan.

Baca `CLAUDE.md` di akar dulu. Berkas itu isinya aturan dan jebakan kode.
Berkas ini isinya **keadaan proyek**, apa yang sudah jadi, apa yang belum, dan
apa yang sudah diputuskan supaya tidak dibongkar ulang.

> **Repo ini PUBLIK.** Tidak ada satu pun kredensial di sini, dan jangan
> pernah ditambahkan. Nama server, nama pengguna, password, kunci, dan nomor
> tagihan sengaja TIDAK ditulis. Semuanya ada di bundel pribadi yang dikirim
> terpisah, di luar git.

## Apa ini

Envirocircle, platform dua peta untuk Indonesia, dari model atmosfer yang
terbuka dan gratis.

| bagian | isinya |
|---|---|
| akar | landing page, statis polos tanpa bundler |
| `atmosight/` | peta cuaca, sumber datanya GFS |
| `smokewatch/` | peta kualitas udara, sumber datanya CAMS |
| `backend/atmosight/pipeline/` | pipeline GFS, Python |
| `backend/smokewatch/pipeline/` | pipeline CAMS, Python |
| `deploy/` | skrip kirim ke server dan skrip survei |

Backend sengaja **tidak dilebur**, cuma berdampingan. Beda sumber data, beda
cara masak, meleburnya cuma menambah risiko.

## Keadaan sekarang

Ketiganya **hidup di GitHub Pages** dan diperbarui tiap hari.

Petanya berisi **tanpa pohon ini menjalankan pipeline sama sekali**. Ada
konstanta `DATA_JAUH` di kedua `app.js` yang menunjuk keluaran pipeline dua
repo lama di GitHub Pages. Dua repo itu masih hidup, masih menjalankan
pipeline-nya, dan pohon ini menumpang ke sana.

**Itu tambalan, dan menjaganya adalah beban.** Selama `DATA_JAUH` masih terisi,
mematikan repo lama membuat peta di sini ikut kosong. Kosongkan `DATA_JAUH`
begitu pipeline jalan di server sendiri, dua duanya otomatis balik ke path
relatif dan tidak ada lagi yang perlu diubah.

`backend/*/data/output` dan `raw` di pohon ini **kosong betulan, nol berkas**.
Itu wajar, bukan kerusakan. Isinya dibuat oleh pipeline.

## Keputusan pemilik, JANGAN dibongkar sendiri

Ini yang sudah dipatok. Kalau menurutmu salah, tanya dulu, jangan langsung
diubah.

1. **Bentuk pindahannya "situs plus datanya sekalian".** Bukan cuma
   memindahkan halaman. Keluaran pipeline ikut naik ke hostingan lalu
   `DATA_JAUH` dikosongkan, sehingga hostingan berdiri sendiri lepas dari
   GitHub Pages.
2. **Automasi dikerjakan di server, bukan di GitHub Actions.** Itu sebabnya
   pohon ini tidak punya workflow sama sekali.
3. **Alamat berbasis folder**, `<akar>/atmosight` dan `<akar>/smokewatch`.
   Bukan subdomain. Alasannya di `CLAUDE.md`, tautan di pohon ini semuanya
   relatif dan akan putus kalau dipecah.
4. **Daftar model dipatok pemiliknya.** Atmosight punya GFS hidup, plus ECMWF,
   WRF, dan WRFDA sebagai pajangan. Smokewatch punya CAMS hidup, plus
   WRFCHEM, CAMx, CMAQ, dan Flexpart sebagai pajangan. Ejaan "WRFCHEM" tanpa
   hubung itu memang maunya pemilik, walaupun chip di kartu Showcase menulis
   "WRF-Chem". Jangan diseragamkan sendiri.
5. **WRF Citarum dan Private Model lengkap dengan pipeline-nya, cuma
   dimatikan.** Jangan dihapus. Menyalakannya keputusan produk, bukan teknis,
   dan butuh dua tempat yang cocok, dropdown di `app.js` dan langkah memasak
   di pipeline.
6. **Kartu Showcase di landing memuat kedua app SUNGGUHAN** lewat iframe
   `?embed=1`, bukan tangkapan layar. Jangan dikembalikan jadi gambar diam
   dengan alasan berat, sudah pernah dicoba dan ditolak.

## Penghalang yang belum selesai, dua duanya di luar teknis

1. **Domain resminya belum hidup.** Per 5 September 2026 dia belum ada di DNS
   sama sekali. Jangan menunggu, penyedia hostingan sudah memberi alamat
   sementara yang berjalan, dan pohon ini jalan apa adanya di bawah alamat
   mana pun sebab tautannya relatif.
2. **Status tagihan hostingan belum dipastikan.** Ini urusan pemilik, bukan
   urusan kode. Alamat sementara tetap bisa dipakai selagi itu beres.

## Urutan kerja yang disarankan

Disusun supaya tiap langkah bisa dibuktikan sendiri sebelum lanjut, dan supaya
tidak ada satu pun yang mematikan versi lama sebelum versi baru terbukti.

1. **Jalankan `deploy/survei-server-itera.sh` di server ini.** Dia hanya
   membaca. Yang paling menentukan bagian 3, apakah server ini boleh keluar
   ke hostingan di port 22. Kalau buntu, seluruh bentuk deploy harus diubah
   jadi hostingan yang menarik sendiri lewat `git pull`.
2. **Bikin kunci SSH BARU di server ini**, jangan menyalin kunci dari laptop.
   Publiknya ditempel ke `authorized_keys` hostingan.
3. **Pasang venv dan `requirements.txt`.** Buktikan pipeline jalan di sini
   dulu, sebelum menyentuh urusan deploy. Ingat dijalankan dari DALAM folder
   pipeline-nya, bukan `python -m`.
4. **Kirim situsnya saja dulu** ke alamat sementara, pakai
   `deploy/kirim-ke-server.sh`. `DATA_JAUH` masih terisi, jadi petanya sudah
   akan berisi walaupun datanya belum naik. Ini bukti paling cepat bahwa
   jalurnya benar.
5. **Baru naikkan datanya**, lalu kosongkan `DATA_JAUH`.
6. **Pasang penjadwal harian.**
7. **JANGAN matikan GitHub Pages** sampai versi hostingan terbukti benar
   berhari hari. Biarkan dua duanya jalan.

## Yang WAJIB ikut dikirim tiap deploy

Satu `.htaccess` berisi `Options -Indexes` dan aturan `cache-control`.
Hostingan tujuannya tidak memasang dua duanya sendiri, dan tanpa
`Options -Indexes` seluruh isi folder data terpajang ke publik.

Kompresi TIDAK perlu diurus, brotli sudah hidup bawaan di sana.
Alasan lengkapnya di `CLAUDE.md`.

## Jebakan yang sudah memakan waktu

Yang soal kode ada di `CLAUDE.md`. Yang di bawah ini soal proses.

**Symlink bocor.** Waktu pohon ini dirakit dari tiga repo, `backend/data/output`
di dua repo asal ternyata symlink ke proyek lain di laptop. Kalau ikut
terbungkus, di komputer lain jadi tautan menggantung DAN membocorkan isi
proyek lain. Sudah dibersihkan. **Jalankan `find . -type l` tiap kali
membungkus ulang.**

**Uji kompresi dengan berkas kecil menipu.** Berkas beberapa bita memang tidak
dikompresi, dan itu sempat dibaca sebagai kompresinya mati. Pakai berkas
ratusan KB.

**Tangkapan layar headless menipu untuk animasi.** Chrome headless tidak
menjalankan animasi sampai selesai. Verifikasi lewat DOM dan
`getBoundingClientRect`, bukan lewat memandang gambar.

**Jangan menukar rupa demi berat tanpa bertanya.** Partikel angin di kartu
Showcase pernah dibuang untuk memangkas 625 KB dan langsung ditegur. Kartu itu
tujuannya justru supaya orang melihat app yang asli.

## Yang masih menggantung, kecil kecil

- `og-image.png` di kedua app **masih berjudul Kertas Cuaca** dan berlambang
  bunga, sisa nama lama. Belum dibuat ulang.
- Bagian `#tentang` dan footer di landing masih `hidden`, markup dan
  fungsinya sengaja tidak dibuang.
- Chip model di kartu Showcase menyebut ECMWF, dan dropdown Atmosight juga.
  Dua tempat itu cocok. Tapi chip menulis "WRF-Chem" sedangkan dropdown
  menulis "WRFCHEM", dan itu memang tidak cocok, sesuai permintaan pemilik.
