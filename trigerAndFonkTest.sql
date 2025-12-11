
-- FONKSİYON VE TETİKLEYİCİ TEST DOSYASI


-- FONKSİYON TESTLERİ


-- TEST 1: uye_odunc_sayisi fonksiyonu
-- Bu fonksiyon bir üyenin elinde kaç kitap olduğunu döndürür

SELECT '=== FONKSİYON 1: uye_odunc_sayisi ===' AS test;

-- Önce mevcut ödünç durumunu görelim
SELECT uye_no, COUNT(*) as odunc_sayisi 
FROM odunc_islemleri 
WHERE durum = 'ödünçte' 
GROUP BY uye_no;

-- Fonksiyonu test et (1 numaralı üye için)
SELECT uye_odunc_sayisi(1) AS "1 No'lu Üyenin Ödünç Sayısı";

-- Başka üye için test
SELECT uye_odunc_sayisi(2) AS "2 No'lu Üyenin Ödünç Sayısı";


-----------------------------------------------------------------------------
-- TEST 2: kitap_musaitlik_kontrol fonksiyonu
-- Bu fonksiyon kitabın rafta olup olmadığını kontrol eder

SELECT '=== FONKSİYON 2: kitap_musaitlik_kontrol ===' AS test;

-- Önce kitapların durumunu görelim
SELECT kitap_kodu, baslik, rafta_mi FROM kitaplar LIMIT 5;

-- Fonksiyonu test et
SELECT kitap_musaitlik_kontrol(1) AS "1 No'lu Kitap Müsait mi?";
SELECT kitap_musaitlik_kontrol(2) AS "2 No'lu Kitap Müsait mi?";


-- -----------------------------------------------------------------------------
-- TEST 3: gecikme_cezasi_hesapla fonksiyonu
-- Bu fonksiyon gecikme cezasını hesaplar (günlük 5 TL)

SELECT '=== FONKSİYON 3: gecikme_cezasi_hesapla ===' AS test;

-- Mevcut ödünç işlemlerini görelim
SELECT islem_no, odunc_alma_tarihi, teslim_tarihi_planlanan, durum 
FROM odunc_islemleri 
LIMIT 5;

-- Fonksiyonu test et (varsa bir işlem için)
SELECT gecikme_cezasi_hesapla(1) AS "1 No'lu İşlemin Gecikme Cezası";


 -----------------------------------------------------------------------------
-- TEST 4: kategori_kitap_istatistik fonksiyonu--
-- Bu fonksiyon kategori bazlı istatistik döndürür

SELECT '=== FONKSİYON 4: kategori_kitap_istatistik ===' AS test;

-- Önce kategorileri görelim
SELECT kategori_kodu, kategori_adi FROM kategoriler;

-- Fonksiyonu test et (Roman kategorisi için - genelde 6 numara)
SELECT * FROM kategori_kitap_istatistik(6);

-- Başka kategori için
SELECT * FROM kategori_kitap_istatistik(7);


-- =============================================================================
-- TETİKLEYİCİ TESTLERİ
-- 

SELECT '=== TETİKLEYİCİ TESTLERİ ===' AS test;

-- TEST: Tetikleyicilerin varlığını kontrol et

SELECT 
    trigger_name AS "Tetikleyici Adı",
    event_manipulation AS "Olay",
    event_object_table AS "Tablo",
    action_timing AS "Zamanlama"
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
ORDER BY trigger_name;



-----------------------------------------------------------------
-- TETİKLEYİCİ 1 TESTİ: trg_odunc_kitap_guncelle
-- Ödünç verildiğinde kitap otomatik raftan çıkar


SELECT '=== TETİKLEYİCİ 1: Ödünç Verince Kitap Raftan Çıkar ===' AS test;

-- ADIM 1: Rafta olan bir kitap bul
SELECT kitap_kodu, baslik, rafta_mi FROM kitaplar WHERE rafta_mi = TRUE LIMIT 1;




-- -----------------------------------------------------------------------------
-- TETİKLEYİCİ 2 TESTİ: trg_iade_kitap_guncelle
-- İade edildiğinde kitap otomatik rafa döner


SELECT '=== TETİKLEYİCİ 2: İade Edilince Kitap Rafa Döner ===' AS test;

SELECT islem_no, kitap_kodu, durum FROM odunc_islemleri WHERE durum = 'ödünçte' LIMIT 1;



-----------------------------------------------------------------------------
-- TETİKLEYİCİ 3 TESTİ: trg_gecikme_ceza_olustur


SELECT '=== TETİKLEYİCİ 3: Gecikmiş İadede Otomatik Ceza ===' AS test;

SELECT * FROM cezalar;




------------------------------------------------------------------------------------
-- TETİKLEYİCİ 4 TESTİ: trg_uye_kayit_log


SELECT '=== TETİKLEYİCİ 4: Üye Kayıt Otomatik Ayarlama ===' AS test;




-- ÖZET: TÜM FONKSİYONLARI TEK SEFERDE TEST ET


SELECT '=== ÖZET: TÜM FONKSİYONLAR ===' AS test;

SELECT 
    'uye_odunc_sayisi(1)' AS fonksiyon,
    uye_odunc_sayisi(1)::TEXT AS sonuc
UNION ALL
SELECT 
    'kitap_musaitlik_kontrol(1)',
    kitap_musaitlik_kontrol(1)::TEXT
UNION ALL
SELECT 
    'gecikme_cezasi_hesapla(1)',
    gecikme_cezasi_hesapla(1)::TEXT
UNION ALL
SELECT 
    'kategori_kitap_istatistik(6) - toplam',
    (SELECT toplam_kitap::TEXT FROM kategori_kitap_istatistik(6));


