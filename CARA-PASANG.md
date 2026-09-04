# Envirocircle landing, cara pasang GSAP

Halaman ini statis polos. Tidak ada bundler, tidak ada langkah build, isinya
langsung disajikan apa adanya oleh GitHub Pages. Jadi `import { gsap } from "gsap"`
TIDAK bisa dipakai di sini.

Alurnya begini.

```bash
npm i gsap
cp node_modules/gsap/dist/gsap.min.js vendor/
cp node_modules/gsap/dist/ScrollTrigger.min.js vendor/
```

Yang di-commit cuma isi `vendor/`. Folder `node_modules` sudah masuk `.gitignore`.

Di `index.html` dipanggil sebagai script biasa, sebelum `anim.js`.

```html
<script src="vendor/gsap.min.js"></script>
<script src="anim.js"></script>
```

`gsap` jadi variabel global, jadi `anim.js` tinggal memakainya.

## Kenapa tidak dari CDN saja

Bisa, dan itu cara yang dipakai Leaflet di Atmos dan Plume. Tapi landing ini
berkasnya cuma segelintir dan enak kalau tidak bergantung jaringan pihak lain.
Ukurannya juga kecil, `gsap.min.js` 71 KB.

## ScrollTrigger

Sudah ikut disalin ke `vendor/` tapi BELUM dipanggil di `index.html`, sebab
sekarang yang beranimasi baru hero. Nanti waktu bagian Tentang, Katalog, dan
Footer dibuka, tambahkan satu baris script sebelum `anim.js` lalu daftarkan.

```html
<script src="vendor/ScrollTrigger.min.js"></script>
```
```js
gsap.registerPlugin(ScrollTrigger);
```

## Versi

GSAP 3.15.0. Kalau menaikkan versi, jalankan `npm i gsap@latest` lalu ulangi
dua perintah `cp` di atas. Jangan mengedit isi `vendor/` dengan tangan.
