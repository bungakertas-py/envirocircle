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

**Salinan ini tanpa data, dan itu disengaja.** Kalau `catalog.json` tidak ada,
Atmosight masuk `modeKosong()` dan Smokewatch masuk mode cangkang. Dua duanya
BUKAN kerusakan. Jangan "memperbaiki" mode itu.

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

Dua hal tentang server tujuannya yang sudah diketahui. **`rsync` TIDAK ada di
sana**, jadi kirim tarball lalu bongkar, jangan pakai rsync. Dan **disknya 96
persen penuh**, sisa sekitar 32 GB, jadi hati hati menaruh keluaran pipeline
yang besar. `node` juga tidak ada.

## Yang harus ditanya dulu, jangan diputuskan sendiri

- Menyalakan model yang sekarang mati. Itu keputusan produk, bukan teknis.
- Mengubah chip nama model di kartu Showcase landing page. Isinya sengaja
  melebihi yang sudah jalan, dan pemiliknya sudah tahu.
- Menghapus WRF Citarum atau Private Model dari Atmosight. Dua duanya lengkap
  dengan pipeline, cuma dimatikan.
