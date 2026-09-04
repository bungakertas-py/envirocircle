/* =====================================================================
   Envirocircle — animasi masuk hero (GSAP)

   Top bar dan tombol tetap pudar plus geser sedikit. Dua baris judulnya
   MELUNCUR MASUK dari luar bingkai, "Precise" dari kiri dan "Forecast." dari
   bawah. Keduanya tidak dipudarkan, sebab waktu masih di luar bingkai memang
   sudah tak terlihat, dan memudarkan sekalian malah bikin geraknya terasa
   ragu. Yang mengurung mereka `overflow: hidden` di .hero.

   GSAP dipasang lewat npm lalu berkas jadinya disalin ke vendor/, sebab
   halaman ini statis tanpa bundler. Lihat CARA-PASANG.md.
   ===================================================================== */
(function () {
  "use strict";

  var hero = document.querySelector(".hero");
  if (!hero) return;

  /* Semua sasaran animasi. Urutannya = urutan munculnya. */
  var sasaran = {
    top:    document.querySelectorAll(".hero-top [data-anim='top']"),
    baris:  hero.querySelectorAll(".hero-title .hl-in"),
    tbl:    hero.querySelectorAll(".hero-foot .pill"),
    kontur: hero.querySelector(".hero-contour")
  };

  /* Jaring pengaman. Kalau GSAP gagal dimuat, teksnya jangan ikut hilang,
     sebab keadaan awal opacity 0 dipasang dari CSS. */
  function tampilkanSaja() {
    /* Sejak top bar keluar dari .hero, selektornya TIDAK BOLEH lagi diawali
       .hero, kalau tidak jaring pengaman ini melewatkan seluruh isi bar. */
    /* WAJIB menyebut .pc, bukan .hl-in. Sejak judul dipecah jadi potongan,
       keadaan awal opacity 0 dipasang pada .pc. Sempat ketinggalan dan
       akibatnya SELURUH JUDUL tak terlihat kalau GSAP gagal dimuat. */
    var semua = document.querySelectorAll(
      "[data-anim], .hero .hero-title .pc, .hero .hero-contour, [data-sc]");
    for (var i = 0; i < semua.length; i++) {
      semua[i].style.opacity = "1";
      semua[i].style.transform = "none";
    }
    /* Tanpa animasi, titik tidak pernah berpindah ke slot i. Kalau dibiarkan,
       yang terbaca "Precıse" tanpa titik, kelihatan seperti salah ketik.
       Jadi batangnya dikembalikan jadi "i" bertitik apa adanya. */
    var bi = document.querySelector(".pc-i");
    if (bi) bi.textContent = "i";
  }

  /* Kotak TEKS, bukan kotak elemen. .hl-in itu display:block jadi kotaknya
     selebar judul. Kotak dari Range juga kotak FONT (ascent + descent), jadi
     baseline = kotak.atas + fontBoundingBoxAscent. Dua duanya jebakan yang
     sudah pernah kena. */
  function kotakTeks(el) {
    var r = document.createRange();
    r.selectNodeContents(el);
    var b = r.getBoundingClientRect();
    return b.width ? b : el.getBoundingClientRect();
  }

  /* Hitung ke mana titik harus mendarat supaya jadi titik huruf i yang benar.
     SEMUA dari metrik font, tidak ada angka karangan. */
  function ukurTitik() {
    var h1 = document.querySelector(".hero-title");
    var pcI = document.querySelector(".pc-i");
    var dot = document.querySelector(".fc-dot");
    if (!h1 || !pcI || !dot) return null;

    var cs = getComputedStyle(h1);
    var m = document.createElement("canvas").getContext("2d");
    m.font = cs.fontWeight + " " + cs.fontSize + " " + cs.fontFamily;
    var mi = m.measureText("i"), ms = m.measureText("\u0131"), mp = m.measureText(".");
    if (!mi.actualBoundingBoxAscent || !mi.fontBoundingBoxAscent) return null;

    /* Daerah titik "i" = antara puncak ink "i" dan puncak ink "ı". */
    var pusatTitik = mi.actualBoundingBoxAscent
                   - (mi.actualBoundingBoxAscent - ms.actualBoundingBoxAscent) / 2;
    /* Pusat ink titik "." kalau ia digambar duduk di baseline. */
    var pusatPeriod = mp.actualBoundingBoxAscent
                    - (mp.actualBoundingBoxAscent + mp.actualBoundingBoxDescent) / 2;
    var xDalamI  = (-mi.actualBoundingBoxLeft + mi.actualBoundingBoxRight) / 2;
    var xPeriod  = (-mp.actualBoundingBoxLeft + mp.actualBoundingBoxRight) / 2;

    var kI = kotakTeks(pcI), kD = kotakTeks(dot);
    var asc = mi.fontBoundingBoxAscent;
    var base1 = kI.top + asc;                  // baseline baris "Precise"
    var base2 = kD.top + asc;                  // baseline baris "Forecast"
    return {
      dx: (kI.left + xDalamI) - (kD.left + xPeriod),
      dy: (base1 - pusatTitik) - (base2 - pusatPeriod),
      /* "Lantai" tempat bola memantul, yaitu baseline baris Precise. Dihitung
         supaya SISI BAWAH ink titik yang menyentuhnya, bukan pusatnya. */
      dyLantai: base1 - (base2 + mp.actualBoundingBoxDescent),
      em: parseFloat(cs.fontSize),
      atasTitik: kD.top,
      poros: porosT(m, asc)
    };
  }

  /* Poros putar huruf t, di PERSILANGAN palang mendatar dan batang tegaknya.
     Mendatar diambil dari pusat ink huruf t, sebab palangnya memanjang kira
     kira sama ke kiri dan ke kanan batang. Menegak diambil dari TINGGI-X,
     yaitu tinggi huruf "x", sebab di situlah palang huruf t duduk.
     Dipulangkan relatif terhadap kotak elemen, bukan layar, sebab
     transform-origin dihitung dari situ. */
  function porosT(m, asc) {
    var fcT = document.querySelector(".fc-t");
    if (!fcT) return null;
    var mt = m.measureText("t"), mx = m.measureText("x");
    var kT = kotakTeks(fcT);                 // kotak FONT
    var rT = fcT.getBoundingClientRect();    // kotak ELEMEN
    var pusatInk = (-mt.actualBoundingBoxLeft + mt.actualBoundingBoxRight) / 2;
    return {
      x: (kT.left + pusatInk) - rT.left,
      y: (kT.top + asc - mx.actualBoundingBoxAscent) - rT.top
    };
  }

  if (!window.gsap) { tampilkanSaja(); return; }

  var diam = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (diam) { tampilkanSaja(); return; }

  showcase();

  function jalan() {
    var tl = window.gsap.timeline({ defaults: { ease: "power3.out" } });

    /* WAJIB fromTo, bukan from. Keadaan awal opacity 0 sudah dipasang dari CSS
       biar teksnya tidak berkedip sebelum GSAP siap. Kalau pakai from(), GSAP
       membaca nilai sekarang sebagai TUJUAN, jadi dia beranimasi dari 0 ke 0
       dan teksnya tidak pernah muncul. */
    /* Tombol punya `transition: transform .1s` di CSS buat efek ditekan.
       Kalau dibiarkan, tiap frame yang ditulis GSAP kena eased ULANG oleh CSS
       dan geraknya jadi lembek serta telat. Transisinya dimatikan selama
       animasi masuk, lalu dikembalikan setelah selesai. */
    function masuk(el, y, dur, geser, jeda) {
      tl.fromTo(el,
        { opacity: 0, y: y },
        {
          opacity: 1, y: 0, duration: dur, stagger: geser,
          onStart: function () { window.gsap.set(this.targets(), { transition: "none" }); },
          onComplete: function () { window.gsap.set(this.targets(), { clearProps: "transition,transform" }); }
        },
        jeda);
    }

    var pcA = hero.querySelector(".pc-a");     // "Prec"
    var pcI = hero.querySelector(".pc-i");     // batang i tanpa titik
    var pcB = hero.querySelector(".pc-b");     // "se"
    var fcA = hero.querySelector(".fc-a");     // "Foreca"
    var fcT = hero.querySelector(".fc-t");     // "t", yang menendang
    var dot = hero.querySelector(".fc-dot");   // titik, jadi titik i di akhir
    var baris = hero.querySelectorAll(".hero-title .hl-in");

    var b1 = kotakTeks(baris[0]);
    var b2 = kotakTeks(baris[1]);
    var keluarKiri = -(b1.right + 60);         // +60 supaya benar benar lewat tepi
    var keluarBawah = (window.innerHeight - b2.top) + 60;

    var BUMP = "back.out(1.9)";                // rasa "bump", melewati lalu balik

    masuk(sasaran.top, -10, 0.5, 0.06, 0);

    /* ---- 1. "Precise" masuk DUA TAHAP dari kiri.
       "se" duluan, menyisakan rongga selebar "Prec" dan slot i. Baru "Prec"
       menyusul. Slot i sengaja dibiarkan kosong, titik dan batangnya datang
       jauh belakangan. */
    tl.fromTo(pcB, { opacity: 1, x: keluarKiri },
                   { x: 0, duration: 0.85, ease: BUMP, clearProps: "transform" }, 0.12);
    tl.fromTo(pcA, { opacity: 1, x: keluarKiri },
                   { x: 0, duration: 0.85, ease: BUMP, clearProps: "transform" }, 0.34);

    /* ---- 2. "Forecast" naik dari bawah, TANPA huruf s dan TANPA titiknya.
       Huruf s menyusul paling akhir dengan gerakan stempel, dan slotnya
       sengaja dibiarkan menganga sampai saat itu. */
    tl.fromTo([fcA, fcT], { opacity: 1, y: keluarBawah },
                          { y: 0, duration: 0.9, ease: "back.out(1.7)" }, 0.62);

    masuk(sasaran.tbl, 18, 0.6, 0, 1.05);

    koreografiTitik(tl, {
      pcI: pcI, fcT: fcT, dot: dot,
      fcS: hero.querySelector(".fc-s"),
      dot2: hero.querySelector(".fc-dot2")
    });

    /* Kontur PM2.5 muncul setelah DUA KATA-nya mendarat, bukan menunggu
       seluruh urusan titik yang berlangsung sampai detik ke-4. Kalau menunggu
       itu, latarnya kosong terlalu lama.
       Yang dipudarkan kanvasnya, bukan isinya, jadi tak ada ongkos tambahan
       di gelung gambar. Keadaan awal opacity 0 dipasang dari CSS. */
    if (sasaran.kontur) {
      tl.fromTo(sasaran.kontur,
        { opacity: 0 },
        { opacity: 1, duration: 1.1, ease: "power2.out" },
        1.60);
    }

    /* Dipakai waktu verifikasi headless. Chrome headless tidak menjalankan
       animasi sampai selesai, jadi keadaan akhir diperiksa lewat progress(1). */
    window.__heroTl = tl;
    return tl;
  }

  /* ---- Koreografi titik ----
     Urutan yang diminta user:
     1. Titik JATUH dari luar layar atas, mendarat seperti stempel (menggepeng
        sesaat lalu balik).
     2. Huruf t MENENDANG titik itu. Titik melesat ke arah slot i di "Precise",
        singgah dulu di BAWAH teks.
     3. Batang i MUNCUL DARI BAWAH seperti keluar dari tanah, dengan bump.
     4. Titik bereaksi, memantul naik, lalu hinggap bump tepat di posisi titik
        huruf i.

     Titik ini SENGAJA tidak di-clearProps di akhir. Dia harus tetap tinggal
     di posisi barunya, sebab sejak saat itu dialah titik huruf i. */
  function koreografiTitik(tl, el) {
    var pcI = el.pcI, fcT = el.fcT, dot = el.dot, fcS = el.fcS, dot2 = el.dot2;
    if (!pcI || !fcT || !dot) return;
    var u = ukurTitik();
    if (!u) { pcI.textContent = "i"; window.gsap.set(dot, { opacity: 1 }); return; }

    var g = window.gsap;
    var jatuhDari = -(u.atasTitik + 1.1 * u.em);   // berangkat dari LUAR bingkai atas
    var puncak    = u.dy - 0.75 * u.em;            // puncak lambungan melengkung
    var puncak2   = u.dy - 0.80 * u.em;            // puncak pentalan lurus

    /* Gerakan STEMPEL: datang besar dari depan, membanting mengecil, lalu
       menggepeng sesaat dan balik. Dipakai huruf s dan titik pengganti. */
    function stempel(e, mulai) {
      if (!e) return;
      tl.fromTo(e, { opacity: 1, scale: 2.6, rotation: -7 },
                   { scale: 1, rotation: 0, duration: 0.24, ease: "power4.in",
                     transformOrigin: "50% 100%", immediateRender: false }, mulai);
      tl.to(e, { scaleX: 1.18, scaleY: 0.84, duration: 0.07, ease: "power2.out" }, mulai + 0.24);
      tl.to(e, { scaleX: 1, scaleY: 1, duration: 0.30, ease: "back.out(3.2)",
                 clearProps: "transform" }, mulai + 0.31);
    }

    /* immediateRender WAJIB false. Bawaannya true, artinya keadaan awal
       dipasang SEKETIKA saat tween dibuat, bukan saat mulai, dan akibatnya
       elemennya sudah kelihatan sejak detik nol. */

    /* ---- 1. Titik jatuh dari luar bingkai, mendarat seperti stempel ---- */
    tl.fromTo(dot, { opacity: 1, y: jatuhDari },
                   { y: 0, duration: 0.44, ease: "power2.in",
                     immediateRender: false }, 1.50);
    tl.to(dot, { scaleX: 1.34, scaleY: 0.5, duration: 0.09, ease: "power2.out",
                 transformOrigin: "50% 100%" }, 1.94);
    tl.to(dot, { scaleX: 1, scaleY: 1, duration: 0.30, ease: "back.out(3.6)" }, 2.03);

    /* ---- 2. Huruf t MENGAYUN JAUH ke belakang, baru menendang ----
       50 derajat, diminta user. Poros di dasar huruf jadi terasa seperti kaki. */
    /* Poros di persilangan palang dan batang, jadi ayunannya seperti jarum jam
       yang berputar pada porosnya, bukan seperti tiang yang miring dari dasar. */
    var poros = u.poros ? (u.poros.x + "px " + u.poros.y + "px") : "50% 100%";
    tl.set(fcT, { transformOrigin: poros }, 2.28);
    tl.to(fcT, { rotation: 50, duration: 0.34, ease: "power2.out" }, 2.28);
    tl.to(fcT, { rotation: -24, duration: 0.10, ease: "power3.in" }, 2.62);
    tl.to(fcT, { rotation: 0, duration: 0.48, ease: "back.out(2.4)",
                 clearProps: "transform" }, 2.74);

    /* ---- 3. Lambungan melengkung, lalu pantulan LURUS DI TEMPAT ----
       Sumbu x diselesaikan TEPAT saat bola menyentuh lantai. Dulu x masih
       berjalan selama memantul, jadi tiap pantulan bolanya menggeser ke
       samping dan terlihat seperti glitch. Pantulannya juga tidak lagi
       memakai ease bounce, tapi hop naik turun tegak yang tingginya mengecil,
       supaya lintasannya benar benar lurus. */
    var LAJU = 0.55;
    /* Poros dikembalikan ke tengah. Gerakan stempel tadi menyetelnya ke dasar
       bawah, dan warisan itu merusak apa pun yang memutar atau menyekala
       sesudahnya. Aman disetel di sini sebab pada detik ini skala dan
       rotasinya sudah kembali normal, jadi tidak ada lompatan tampilan. */
    tl.set(dot, { transformOrigin: "50% 50%" }, 2.68);
    tl.to(dot, { x: u.dx, duration: LAJU, ease: "none" }, 2.70);
    tl.to(dot, { y: puncak, duration: 0.24, ease: "power2.out" }, 2.70);
    tl.to(dot, { y: u.dyLantai, duration: LAJU - 0.24, ease: "power2.in" }, 2.94);

    var tPantul = 2.70 + LAJU;               // saat menyentuh lantai
    [[0.30, 0.17], [0.13, 0.115], [0.05, 0.075]].forEach(function (h) {
      var naik = h[0] * u.em, lama = h[1];
      tl.to(dot, { y: u.dyLantai - naik, duration: lama, ease: "power2.out" }, tPantul);
      tl.to(dot, { y: u.dyLantai, duration: lama, ease: "power2.in" }, tPantul + lama);
      tPantul += lama * 2;
    });

    /* ---- 4. Batang i naik dari bawah baseline, titik TERPENTAL LURUS ----
       Pentalannya sengaja lurus, tanpa lengkung, sebab x sudah di tempat dan
       yang digerakkan hanya y. Titik MENGGANTUNG di atas selama batang i
       menyelesaikan bump-nya, baru turun setelah itu. */
    tl.fromTo(pcI, { opacity: 1, y: 0.62 * u.em },
                   { y: 0, duration: 0.55, ease: "back.out(2.4)",
                     clearProps: "transform", immediateRender: false }, 4.02);
    tl.to(dot, { y: puncak2, duration: 0.30, ease: "power2.out" }, 4.04);
    /* Turun ke posisinya, lalu bump memantul KE ATAS.
       Dulu memakai ease back.out, dan itu MELEWATI sasaran dulu baru balik,
       jadi titiknya sempat turun sampai ke badan huruf i. Batas bawah
       penurunan HARUS posisi titik i yang sebenarnya, tidak boleh lebih.
       Jadi bump-nya dibuat sebagai pantulan kecil ke atas setelah mendarat,
       bukan sebagai lewatan ke bawah.

       TANPA rotation juga. Titik masih memakai transform-origin warisan
       gerakan stempel, dan rotasi di poros dasar memutarinya mengelilingi
       poros itu, bukan berputar di tempat, sehingga posisinya terlempar ke
       samping. Lagipula titik ini bundar, diputar berapa pun sama saja. */
    var tTurun = 4.57;                    // 4.02 + 0.55, tepat saat i selesai bump
    tl.to(dot, { y: u.dy, duration: 0.28, ease: "power2.in" }, tTurun);
    [[0.100, 0.11, 0.14], [0.032, 0.06, 0.06]].forEach(function (h) {
      var naik = h[0] * u.em, atas = h[1], bawah = h[2];
      tl.to(dot, { y: u.dy - naik, duration: atas, ease: "power2.out" }, tTurun + 0.28);
      tl.to(dot, { y: u.dy, duration: bawah, ease: "power2.in" }, tTurun + 0.28 + atas);
      tTurun += atas + bawah;
    });

    /* ---- 5. Huruf s dan titik pengganti, dua duanya di-stamp ----
       Titik aslinya sudah pergi jadi titik huruf i, jadi tanpa ini "Forecast"
       berakhir tanpa titik. */
    stempel(fcS, 5.28);
    stempel(dot2, 5.56);

    window.addEventListener("resize", function () {
      if (tl.progress() < 1) return;
      var v = ukurTitik();
      if (v) g.set(dot, { x: v.dx, y: v.dy });
    });
  }

  /* ---- Showcase, muncul saat digulir ----
     Ini pemakaian pertama ScrollTrigger, berkasnya sudah nongkrong di vendor/
     sejak 2 September tanpa pernah dipanggil.
     `once: true` disengaja. Bagian ini isinya kartu produk, bukan pertunjukan,
     jadi tidak perlu memudar lagi tiap kali digulir bolak balik.
     Kalau ScrollTrigger gagal dimuat, elemennya ditampilkan apa adanya, sebab
     keadaan awal opacity 0 dipasang dari CSS. */
  function showcase() {
    ["#showcase", "#team"].forEach(bagianGulir);
  }

  function bagianGulir(pilih) {
    var sec = document.querySelector(pilih);
    if (!sec) return;
    var sasaranSc = sec.querySelectorAll("[data-sc]");
    if (!sasaranSc.length) return;

    if (!window.gsap || !window.ScrollTrigger) {
      for (var i = 0; i < sasaranSc.length; i++) {
        sasaranSc[i].style.opacity = "1";
        sasaranSc[i].style.transform = "none";
      }
      return;
    }
    window.gsap.registerPlugin(window.ScrollTrigger);
    window.gsap.fromTo(sasaranSc,
      { opacity: 0, y: 34 },
      {
        opacity: 1, y: 0, duration: 0.7, stagger: 0.11, ease: "power3.out",
        clearProps: "transform",
        scrollTrigger: { trigger: sec, start: "top 78%", once: true }
      });
  }

  /* Tunggu Archivo Black selesai dimuat dulu. Kalau tidak, huruf tulisannya
     sempat berganti di tengah animasi dan barisnya kelihatan meloncat. */
  if (document.fonts && document.fonts.ready) {
    document.fonts.ready.then(jalan);
    /* Kalau fontnya lama sekali, jangan biarkan hero kosong menganga. */
    setTimeout(function () { if (!window.__heroTl) jalan(); }, 1500);
  } else {
    jalan();
  }
})();

/* =====================================================================
   Saklar latar top bar DIBUANG 4 Sep.

   Dulu di sini ada IIFE yang memasang kelas .padat pada .hero-top begitu
   hero terlewat, supaya bar tembus pandang selagi masih di atas kontur lalu
   memadat waktu melintas di atas Showcase dan bagian tim yang hitam.

   User minta bar SELALU padat, jadi saklarnya tidak ada gunanya lagi dan
   kelas .padat ikut dibuang dari style.css. Kalau suatu saat bar tembus
   pandang dipakai lagi, yang dibutuhkan cuma satu pendengar scroll yang
   membandingkan hero.getBoundingClientRect().bottom dengan bar.offsetHeight,
   digandeng requestAnimationFrame.
   ===================================================================== */
