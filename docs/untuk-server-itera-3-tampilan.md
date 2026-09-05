# Envirocircle, konteks tampilan

Untuk **yang memegang server ITERA**, dan untuk **Claude yang bekerja di server
itu**. Ditulis 5 September 2026.

Bukan pekerjaan kalian. Ditulis supaya pilihan di sisi data konsisten dengan sisi tampilan.

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

## 1. Sisi tampilan, konteks tambahan


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
