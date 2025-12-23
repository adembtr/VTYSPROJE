-- =============================================================================
-- KÜTÜPHANE YÖNETİM SİSTEMİ
-- FONKSİYON VE TETİKLEYİCİ TEST DOSYASI
-- =============================================================================
-- Bu dosyayı Valentina Studio'da çalıştırarak trigger ve fonksiyonları test et
-- ÖNEMLİ: Her test senaryosunu AYRI AYRI çalıştır (blok blok seç ve çalıştır)
-- =============================================================================



-- =============================================================================
-- BÖLÜM 1: FONKSİYON TESTLERİ
-- =============================================================================


-- ---------------------------------------------------------------------------
-- TEST 1: uye_odunc_sayisi FONKSIYONU
-- ---------------------------------------------------------------------------
-- Bu fonksiyon bir üyenin elinde kaç kitap olduğunu döndürür
-- ---------------------------------------------------------------------------

SELECT '=== FONKSİYON 1: uye_odunc_sayisi ===' AS test_adi;

-- 1.1 Önce mevcut ödünç durumunu manuel olarak görelim
SELECT 
    uye_no, 
    COUNT(*) AS odunc_sayisi 
FROM odunc_islemleri 
WHERE durum = 'ödünçte' 
GROUP BY uye_no
ORDER BY uye_no;

-- 1.2 Fonksiyonu 1 numaralı üye için test et
SELECT uye_odunc_sayisi(1) AS "1 No'lu Üyenin Ödünç Sayısı";

-- 1.3 Fonksiyonu 2 numaralı üye için test et
SELECT uye_odunc_sayisi(2) AS "2 No'lu Üyenin Ödünç Sayısı";

-- 1.4 Hiç ödüncü olmayan üye için test (0 dönmeli)
SELECT uye_odunc_sayisi(5) AS "5 No'lu Üyenin Ödünç Sayısı";

-- BEKLENEN SONUÇ: Manuel sayım ile fonksiyon sonucu aynı olmalı


-- ---------------------------------------------------------------------------
-- TEST 2: kitap_musaitlik_kontrol FONKSIYONU
-- ---------------------------------------------------------------------------
-- Bu fonksiyon kitabın rafta olup olmadığını kontrol eder
-- TRUE = Rafta/Müsait, FALSE = Ödünçte
-- ---------------------------------------------------------------------------

SELECT '=== FONKSİYON 2: kitap_musaitlik_kontrol ===' AS test_adi;

-- 2.1 Önce kitapların mevcut durumunu görelim
SELECT 
    kitap_kodu, 
    baslik, 
    rafta_mi 
FROM kitaplar 
ORDER BY kitap_kodu
LIMIT 5;

-- 2.2 Rafta olan bir kitap için test (TRUE dönmeli)
SELECT kitap_musaitlik_kontrol(2) AS "2 No'lu Kitap Müsait mi?";

-- 2.3 Ödünçte olan bir kitap için test (FALSE dönmeli - eğer varsa)
SELECT kitap_musaitlik_kontrol(1) AS "1 No'lu Kitap Müsait mi?";

-- 2.4 Olmayan kitap için test (HATA vermeli)
-- Bu satırı çalıştırınca "Kitap bulunamadı" hatası almalısın
-- SELECT kitap_musaitlik_kontrol(9999) AS "Olmayan Kitap Testi";

-- BEKLENEN SONUÇ: Tablodaki rafta_mi değeri ile fonksiyon sonucu eşleşmeli


-- ---------------------------------------------------------------------------
-- TEST 3: gecikme_cezasi_hesapla FONKSIYONU
-- ---------------------------------------------------------------------------
-- Bu fonksiyon gecikme cezasını hesaplar (Günlük 5 TL)
-- ---------------------------------------------------------------------------

SELECT '=== FONKSİYON 3: gecikme_cezasi_hesapla ===' AS test_adi;

-- 3.1 Mevcut ödünç işlemlerini görelim
SELECT 
    islem_no, 
    uye_no,
    kitap_kodu,
    odunc_alma_tarihi, 
    teslim_tarihi_planlanan,
    gercek_teslim_tarihi,
    durum 
FROM odunc_islemleri 
ORDER BY islem_no;

-- 3.2 Belirli bir işlem için gecikme cezası hesapla
SELECT gecikme_cezasi_hesapla(1) AS "1 No'lu İşlemin Gecikme Cezası (TL)";

-- 3.3 Hesaplama mantığını göster
SELECT 
    islem_no,
    teslim_tarihi_planlanan AS "Planlanan Tarih",
    COALESCE(gercek_teslim_tarihi, CURRENT_DATE) AS "Gerçek/Bugün",
    COALESCE(gercek_teslim_tarihi, CURRENT_DATE) - teslim_tarihi_planlanan AS "Gecikme (Gün)",
    CASE 
        WHEN COALESCE(gercek_teslim_tarihi, CURRENT_DATE) > teslim_tarihi_planlanan 
        THEN (COALESCE(gercek_teslim_tarihi, CURRENT_DATE) - teslim_tarihi_planlanan) * 5
        ELSE 0 
    END AS "Ceza (TL)"
FROM odunc_islemleri
WHERE islem_no = 1;

-- BEKLENEN SONUÇ: Gecikme günü x 5 TL


-- ---------------------------------------------------------------------------
-- TEST 4: kategori_kitap_istatistik FONKSIYONU
-- ---------------------------------------------------------------------------
-- Bu fonksiyon bir kategorideki kitap istatistiklerini döndürür
-- TABLE döndürür: toplam_kitap, rafta_kitap, oduncte_kitap
-- ---------------------------------------------------------------------------

SELECT '=== FONKSİYON 4: kategori_kitap_istatistik ===' AS test_adi;

-- 4.1 Önce kategorileri görelim
SELECT 
    kategori_kodu, 
    kategori_adi,
    ust_kategori_kodu
FROM kategoriler
ORDER BY kategori_kodu;

-- 4.2 Roman kategorisi için istatistik (kategori_kodu'nu kontrol et)
SELECT * FROM kategori_kitap_istatistik(6);

-- 4.3 Başka bir kategori için test
SELECT * FROM kategori_kitap_istatistik(7);

-- 4.4 Manuel doğrulama - Roman kategorisi
SELECT 
    COUNT(*) AS toplam,
    COUNT(*) FILTER (WHERE rafta_mi = TRUE) AS rafta,
    COUNT(*) FILTER (WHERE rafta_mi = FALSE) AS oduncte
FROM kitaplar 
WHERE kategori_kodu = 6;

-- BEKLENEN SONUÇ: Fonksiyon sonucu ile manuel sorgu eşleşmeli



-- =============================================================================
-- BÖLÜM 2: TETİKLEYİCİ (TRIGGER) TESTLERİ
-- =============================================================================


-- ---------------------------------------------------------------------------
-- KONTROL: Mevcut Tetikleyicileri Listele
-- ---------------------------------------------------------------------------

SELECT '=== TETİKLEYİCİLER LİSTESİ ===' AS test_adi;

SELECT 
    trigger_name AS "Tetikleyici Adı",
    event_manipulation AS "Olay (INSERT/UPDATE)",
    event_object_table AS "Tablo",
    action_timing AS "Zamanlama (BEFORE/AFTER)"
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
ORDER BY trigger_name;

-- 4 adet trigger görmelisin:
-- 1. trg_gecikme_ceza_olustur - AFTER UPDATE - odunc_islemleri
-- 2. trg_iade_kitap_guncelle  - AFTER UPDATE - odunc_islemleri  
-- 3. trg_odunc_kitap_guncelle - AFTER INSERT - odunc_islemleri
-- 4. trg_uye_kayit_kontrol    - BEFORE INSERT - uyeler


-- ---------------------------------------------------------------------------
-- TETİKLEYİCİ 1 TESTİ: trg_odunc_kitap_guncelle
-- ---------------------------------------------------------------------------
-- Ödünç verildiğinde kitap otomatik olarak raftan çıkar (rafta_mi = FALSE)
-- ---------------------------------------------------------------------------

SELECT '=== TETİKLEYİCİ 1: Ödünç Verince Kitap Raftan Çıkar ===' AS test_adi;

-- ADIM 1: Rafta olan bir kitap bul
SELECT kitap_kodu, baslik, rafta_mi 
FROM kitaplar 
WHERE rafta_mi = TRUE 
LIMIT 1;
-- Örneğin kitap_kodu = 2 diyelim (İnce Memed)

-- ADIM 2: Bu kitabın durumunu kontrol et (TRUE olmalı)
SELECT kitap_kodu, baslik, rafta_mi FROM kitaplar WHERE kitap_kodu = 2;

-- ADIM 3: Kitabı ödünç ver (INSERT yap)
INSERT INTO odunc_islemleri (uye_no, kitap_kodu, personel_no, teslim_tarihi_planlanan, durum)
VALUES (2, 2, 2, CURRENT_DATE + INTERVAL '14 days', 'ödünçte');

-- ADIM 4: Kitabın durumunu tekrar kontrol et (FALSE olmalı - TRIGGER çalıştı!)
SELECT kitap_kodu, baslik, rafta_mi FROM kitaplar WHERE kitap_kodu = 2;

-- BEKLENEN SONUÇ: rafta_mi = TRUE'dan FALSE'a dönmüş olmalı


-- ---------------------------------------------------------------------------
-- TETİKLEYİCİ 2 TESTİ: trg_iade_kitap_guncelle
-- ---------------------------------------------------------------------------
-- İade edildiğinde kitap otomatik olarak rafa döner (rafta_mi = TRUE)
-- ---------------------------------------------------------------------------

SELECT '=== TETİKLEYİCİ 2: İade Edilince Kitap Rafa Döner ===' AS test_adi;

-- ADIM 1: Ödünçte olan bir işlem bul
SELECT islem_no, kitap_kodu, durum 
FROM odunc_islemleri 
WHERE durum = 'ödünçte' 
ORDER BY islem_no DESC
LIMIT 1;
-- Az önce eklediğimiz işlem olmalı

-- ADIM 2: İşlemi bul ve kitabın durumunu kontrol et (FALSE olmalı)
SELECT k.kitap_kodu, k.baslik, k.rafta_mi, o.islem_no, o.durum
FROM kitaplar k
JOIN odunc_islemleri o ON k.kitap_kodu = o.kitap_kodu
WHERE o.durum = 'ödünçte'
ORDER BY o.islem_no DESC
LIMIT 1;

-- ADIM 3: Kitabı iade et (UPDATE yap)
-- islem_no'yu yukarıdaki sorgudan al!
UPDATE odunc_islemleri 
SET durum = 'teslim edildi', 
    gercek_teslim_tarihi = CURRENT_DATE
WHERE islem_no = (SELECT MAX(islem_no) FROM odunc_islemleri WHERE durum = 'ödünçte');

-- ADIM 4: Kitabın durumunu kontrol et (TRUE olmalı - TRIGGER çalıştı!)
SELECT kitap_kodu, baslik, rafta_mi FROM kitaplar WHERE kitap_kodu = 2;

-- BEKLENEN SONUÇ: rafta_mi = FALSE'dan TRUE'ya dönmüş olmalı


-- ---------------------------------------------------------------------------
-- TETİKLEYİCİ 3 TESTİ: trg_gecikme_ceza_olustur
-- ---------------------------------------------------------------------------
-- Gecikmiş iade yapıldığında otomatik ceza kaydı oluşturur
-- ---------------------------------------------------------------------------

SELECT '=== TETİKLEYİCİ 3: Gecikmiş İadede Otomatik Ceza ===' AS test_adi;

-- ADIM 1: Önce mevcut cezaları kontrol et
SELECT * FROM cezalar ORDER BY ceza_no;

-- ADIM 2: Test için yeni bir ödünç oluştur (geçmiş tarihli)
INSERT INTO odunc_islemleri (uye_no, kitap_kodu, personel_no, odunc_alma_tarihi, teslim_tarihi_planlanan, durum)
VALUES (3, 3, 2, CURRENT_DATE - INTERVAL '20 days', CURRENT_DATE - INTERVAL '6 days', 'ödünçte');

-- ADIM 3: Bu kitabı GECİKMELİ olarak iade et (6 gün gecikmiş)
UPDATE odunc_islemleri 
SET durum = 'teslim edildi', 
    gercek_teslim_tarihi = CURRENT_DATE  -- Bugün iade ediliyor, 6 gün geç
WHERE islem_no = (SELECT MAX(islem_no) FROM odunc_islemleri WHERE durum = 'ödünçte');

-- ADIM 4: Cezalar tablosunu kontrol et (yeni ceza eklenmeli!)
SELECT * FROM cezalar ORDER BY ceza_no DESC LIMIT 3;

-- ADIM 5: Ceza tutarını kontrol et
-- 6 gün gecikme x 5 TL = 30 TL olmalı
SELECT 
    c.ceza_no,
    c.uye_no,
    c.ceza_tipi,
    c.ceza_tutari,
    o.teslim_tarihi_planlanan,
    o.gercek_teslim_tarihi,
    o.gercek_teslim_tarihi - o.teslim_tarihi_planlanan AS "Gecikme (Gün)"
FROM cezalar c
JOIN odunc_islemleri o ON c.islem_no = o.islem_no
ORDER BY c.ceza_no DESC
LIMIT 1;

-- BEKLENEN SONUÇ: Gecikme günü x 5 TL ceza kaydı oluşmuş olmalı


-- ---------------------------------------------------------------------------
-- TETİKLEYİCİ 4 TESTİ: trg_uye_kayit_kontrol
-- ---------------------------------------------------------------------------
-- Üye eklenirken:
-- 1. kayit_tarihi NULL ise bugünün tarihini atar
-- 2. uyelik_durumu NULL ise 'aktif' atar
-- 3. TC Kimlik No 11 haneli değilse HATA verir
-- ---------------------------------------------------------------------------

SELECT '=== TETİKLEYİCİ 4: Üye Kayıt Otomatik Kontrol ===' AS test_adi;

-- TEST 4.1: Kayıt tarihi vermeden üye ekle (otomatik bugünün tarihi atanmalı)
INSERT INTO uyeler (ad, soyad, tc_kimlik_no, cinsiyet, uyelik_tipi, adres_id)
VALUES ('Test', 'Kullanıcı', '99988877766', 'E', 'standart', 1);

-- Kontrol et
SELECT uye_no, ad, soyad, kayit_tarihi, uyelik_durumu 
FROM uyeler 
WHERE tc_kimlik_no = '99988877766';

-- BEKLENEN: kayit_tarihi = bugünün tarihi, uyelik_durumu = 'aktif'


-- TEST 4.2: Hatalı TC Kimlik No ile üye eklemeye çalış (HATA vermeli!)
-- Bu satırı çalıştırınca hata almalısın!
-- INSERT INTO uyeler (ad, soyad, tc_kimlik_no, cinsiyet, uyelik_tipi)
-- VALUES ('Hatalı', 'TC', '123', 'E', 'standart');

-- Hata mesajı: "TC Kimlik No 11 haneli olmalıdır!"


-- ---------------------------------------------------------------------------
-- TEMİZLİK: Test verilerini sil (opsiyonel)
-- ---------------------------------------------------------------------------

-- Test kullanıcısını sil
-- DELETE FROM uyeler WHERE tc_kimlik_no = '99988877766';



-- =============================================================================
-- BÖLÜM 3: ÖZET TEST - TÜM FONKSİYONLAR TEK SEFERDE
-- =============================================================================

SELECT '=== ÖZET: TÜM FONKSİYONLAR ===' AS test_adi;

SELECT 
    'uye_odunc_sayisi(1)' AS fonksiyon,
    uye_odunc_sayisi(1)::TEXT AS sonuc,
    'Üyenin elindeki kitap sayısı' AS aciklama
UNION ALL
SELECT 
    'kitap_musaitlik_kontrol(1)',
    kitap_musaitlik_kontrol(1)::TEXT,
    'Kitap rafta mı? (TRUE/FALSE)'
UNION ALL
SELECT 
    'gecikme_cezasi_hesapla(1)',
    gecikme_cezasi_hesapla(1)::TEXT || ' TL',
    'Gecikme cezası tutarı'
UNION ALL
SELECT 
    'kategori_kitap_istatistik(6)',
    (SELECT toplam_kitap::TEXT || ' kitap' FROM kategori_kitap_istatistik(6)),
    'Kategorideki toplam kitap';


-- =============================================================================
-- BÖLÜM 4: FONKSİYONLARIN YAZILIMDA KULLANIMI ÖRNEKLERİ
-- =============================================================================

SELECT '=== YAZILIMDA KULLANIM ÖRNEKLERİ ===' AS test_adi;

-- Örnek 1: Ödünç vermeden önce üyenin limit kontrolü
-- Python'da: cursor.execute("SELECT uye_odunc_sayisi(%s)", (uye_no,))
SELECT 
    CASE 
        WHEN uye_odunc_sayisi(1) >= 3 THEN 'UYARI: Üye limiti doldu!'
        ELSE 'Üye ödünç alabilir'
    END AS "Limit Kontrolü";

-- Örnek 2: Kitap ödünç vermeden önce müsaitlik kontrolü
-- Python'da: cursor.execute("SELECT kitap_musaitlik_kontrol(%s)", (kitap_kodu,))
SELECT 
    CASE 
        WHEN kitap_musaitlik_kontrol(2) = TRUE THEN 'Kitap müsait, ödünç verilebilir'
        ELSE 'Kitap şu anda ödünçte!'
    END AS "Müsaitlik Kontrolü";

-- Örnek 3: Dashboard için kategori istatistikleri
SELECT 
    k.kategori_adi,
    s.toplam_kitap,
    s.rafta_kitap,
    s.oduncte_kitap
FROM kategoriler k
CROSS JOIN LATERAL kategori_kitap_istatistik(k.kategori_kodu) s
WHERE k.ust_kategori_kodu IS NOT NULL  -- Sadece alt kategoriler
ORDER BY s.toplam_kitap DESC;


-- =============================================================================
-- SON: Tüm testler tamamlandı!
-- =============================================================================

SELECT '========================================' AS bilgi
UNION ALL SELECT 'TÜM TESTLER TAMAMLANDI!'
UNION ALL SELECT '4 Fonksiyon + 4 Tetikleyici başarıyla test edildi.'
UNION ALL SELECT '========================================';