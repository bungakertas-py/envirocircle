# Envirocircle, tambahan untuk sisi server

**Susulan dari berkas `untuk-server-itera.md` yang sudah dikirim sebelumnya.**
Isinya cuma tiga hal yang belum ada di sana. Sisanya tidak berubah, tidak perlu
dibaca ulang.

Ditulis 5 September 2026, sesudah situsnya dipasang di hostingan dan cara dia
memilih sumber data diubah.

> Repo ini publik. Alamat server, nama pengguna, dan kunci tidak ada di sini,
> semuanya lewat environment.

---

## 1. Persisnya data itu mendarat di mana

Ini koordinat yang paling penting dan kemarin cuma tersirat. Sekarang ditulis
apa adanya.

Isi kedua folder keluaran kalian harus berakhir di sini.

```
/home/<pengguna>/public_html/backend/atmosight/data/output/
/home/<pengguna>/public_html/backend/smokewatch/data/output/
```

**Dua folder itu SUDAH ADA di hostingan.** Dibuat waktu situsnya dipasang, jadi
kalian tinggal mengisinya, tidak perlu membuat apa apa.

Jadi `catalog.json` buatan kalian mendarat sebagai
`public_html/backend/atmosight/data/output/catalog.json`, dan semua gambar yang
disebut di dalamnya duduk sebagai tetangganya di folder yang sama.

**Jangan menyentuh apa pun di luar dua folder itu.** Sisi situsnya salinan
kerja git, dan apa pun yang kalian taruh di sana akan tertimpa waktu situsnya
diperbarui.

---

## 2. PERINGATAN, kiriman pertama LANGSUNG dipakai

Ini yang paling penting di berkas tambahan ini, dan aturannya baru berlaku
sejak 5 September. Belum ada waktu berkas sebelumnya ditulis.

Situsnya sekarang **memilih sumber datanya sendiri saat dimuat**. Urutannya
begini.

```
1. coba  <situs>/backend/<app>/data/output/catalog.json
   ada   -> pakai itu, selesai
   404   -> lanjut

2. coba  keluaran yang tersaji di GitHub Pages
   ada   -> menumpang ke situ
```

Yang di langkah 2 itu hasil pipeline yang sama, cuma dijalankan di runner
GitHub. Selama data lokal belum ada, situsnya tetap berisi karena menumpang ke
sana.

**Artinya, detik kalian menaruh `catalog.json` di hostingan, situsnya berhenti
menumpang dan langsung memakai punya kalian.** Tidak ada tombol, tidak ada
pengumuman, tidak ada persetujuan siapa pun. Muat ulang berikutnya sudah pakai
data kalian.

### Akibatnya, dan tolong dibaca dua kali

**Jangan menaruh keluaran yang belum utuh di hostingan.**

Kalau `catalog.json` sudah ada tapi gambar gambarnya belum, atau layernya baru
sebagian, situsnya akan memakai yang setengah itu dan **berhenti memakai data
lengkap yang sebelumnya tersaji**. Dari sisi pengunjung itu terlihat seperti
situsnya rusak, padahal cadangannya masih hidup dan baik baik saja.

Tukar atomik melindungi dari kiriman yang **setengah tertulis**. Dia TIDAK
melindungi dari kiriman yang **utuh tapi isinya belum benar**. Dua hal yang
berbeda, dan yang kedua tanggung jawab kalian.

Jadi berlatihnya di tempat lain dulu. Kirim ke hostingan baru kalau
keluarannya sudah lengkap dan sudah diadu dengan pembanding yang tersaji di
GitHub Pages.

---

## 3. Cara memeriksa sesudah mengirim

Situsnya menulis sumber yang sedang dipakai ke atribut `data-sumber` pada
elemen `<html>`. Isinya `dekat` kalau memakai data kalian, `jauh` kalau masih
menumpang.

**Jebakannya, itu ditulis JavaScript sesudah halaman dimuat**, jadi `curl`
biasa tidak akan pernah melihatnya. Kalau dicoba, yang keluar kosong dan itu
bukan berarti gagal.

Yang bisa dipakai dari terminal, tembak berkasnya langsung.

```
curl -s -o /dev/null -w "%{http_code}\n" \
  <alamat-situs>/backend/atmosight/data/output/catalog.json
```

| jawaban | artinya |
|---|---|
| `200` | data kalian sudah ada dan sudah dipakai situsnya |
| `404` | belum ada, situsnya masih menumpang |

Kalau mau memastikan lewat mata, buka situsnya lalu lihat Console di
Developer Tools. Ada salah satu dari dua baris ini.

```
[data] sumber LOKAL, ../backend/atmosight/data/output/
[data] sumber menumpang, https://bungakertas-py.github.io/...
```

---

## Ringkasnya

1. Datanya mendarat di `public_html/backend/<app>/data/output/`, dan foldernya
   sudah ada.
2. Begitu `catalog.json` kalian ada di sana, situsnya **langsung** memakainya.
   Jadi jangan kirim yang belum utuh.
3. Periksanya dengan menembak `catalog.json` lokal, `200` berarti sudah dipakai.
