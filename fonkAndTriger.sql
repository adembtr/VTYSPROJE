-- KÜTÜPHANE YÖNETİM SİSTEMİ
-- FONKSİYONLAR VE TETİKLEYİCİLER (TRIGGERS)



-- BÖLÜM 1: FONKSİYONLAR (4 ADET)


-- -----------------------------------------------------------------------------
-- FONKSİYON 1: uye_odunc_sayisi
-- AÇIKLAMA: Bir üyenin elinde şu anda kaç kitap olduğunu döndürür
-- PARAMETRE: p_uye_no (INTEGER) - Üye numarası
-- DÖNDÜRÜR: INTEGER - Ödünçteki kitap sayısı
-- KULLANIM: SELECT uye_odunc_sayisi(1);
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION uye_odunc_sayisi(p_uye_no INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_sayi INTEGER;
BEGIN
    -- Üyenin 'ödünçte' durumundaki kitaplarını say
    SELECT COUNT(*) INTO v_sayi
    FROM odunc_islemleri
    WHERE uye_no = p_uye_no 
      AND durum = 'ödünçte';
    
    RETURN v_sayi;
END;
$$ LANGUAGE plpgsql;

-- YORUM: Bu fonksiyon, bir üyenin ödünç limit kontrolü için kullanılabilir.
-- Örneğin öğrenci max 3 kitap alabilir kuralı varsa bu fonksiyonla kontrol edilir.





-- -----------------------------------------------------------------------------
-- FONKSİYON 2: kitap_musaitlik_kontrol
-- AÇIKLAMA: Bir kitabın rafta (müsait) olup olmadığını kontrol eder
-- PARAMETRE: p_kitap_kodu (INTEGER) - Kitap kodu
-- DÖNDÜRÜR: BOOLEAN - TRUE: Rafta/Müsait, FALSE: Ödünçte
-- KULLANIM: SELECT kitap_musaitlik_kontrol(1);
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION kitap_musaitlik_kontrol(p_kitap_kodu INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    v_rafta BOOLEAN;
BEGIN
    -- Kitabın rafta_mi durumunu al
    SELECT rafta_mi INTO v_rafta
    FROM kitaplar
    WHERE kitap_kodu = p_kitap_kodu;
    
    -- Kitap bulunamazsa hata fırlat
    IF v_rafta IS NULL THEN
        RAISE EXCEPTION 'Kitap bulunamadı! Kitap kodu: %', p_kitap_kodu;
    END IF;
    
    RETURN v_rafta;
END;
$$ LANGUAGE plpgsql;

-- YORUM: Ödünç verme işleminden önce kitabın müsait olup olmadığı kontrol edilir.
-- Uygulama tarafında bu fonksiyon çağrılarak kullanıcıya bilgi verilebilir.


-- -----------------------------------------------------------------------------
-- FONKSİYON 3: gecikme_cezasi_hesapla
-- AÇIKLAMA: Bir ödünç işlemi için gecikme cezasını hesaplar
-- PARAMETRE: p_islem_no (INTEGER) - Ödünç işlem numarası
-- DÖNDÜRÜR: DECIMAL(10,2) - Ceza tutarı (TL)
-- KURAL: Günlük 5 TL gecikme cezası
-- KULLANIM: SELECT gecikme_cezasi_hesapla(1);

CREATE OR REPLACE FUNCTION gecikme_cezasi_hesapla(p_islem_no INTEGER)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    v_planlanan DATE;
    v_gercek DATE;
    v_gecikme_gun INTEGER;
    v_gunluk_ceza DECIMAL(10,2) := 5.00;  -- Günlük ceza tutarı
BEGIN
    -- İşlem bilgilerini al
    SELECT teslim_tarihi_planlanan, gercek_teslim_tarihi 
    INTO v_planlanan, v_gercek
    FROM odunc_islemleri
    WHERE islem_no = p_islem_no;
    
    -- Henüz iade edilmediyse bugünün tarihini kullan
    IF v_gercek IS NULL THEN 
        v_gercek := CURRENT_DATE; 
    END IF;
    
    -- Gecikme gün sayısını hesapla
    v_gecikme_gun := v_gercek - v_planlanan;
    
    -- Gecikme varsa ceza hesapla, yoksa 0 döndür
    IF v_gecikme_gun > 0 THEN 
        RETURN v_gecikme_gun * v_gunluk_ceza;
    ELSE 
        RETURN 0.00;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- YORUM: Bu fonksiyon hem iade sırasında hem de rapor için kullanılabilir.
-- Trigger ile otomatik ceza oluşturmada da benzer mantık kullanılır.


-- -----------------------------------------------------------------------------
-- FONKSİYON 4: kategori_kitap_istatistik
-- AÇIKLAMA: Bir kategorideki kitapların istatistiklerini döndürür
-- PARAMETRE: p_kategori_kodu (INTEGER) - Kategori kodu
-- DÖNDÜRÜR: TABLE - toplam_kitap, rafta_kitap, oduncte_kitap
-- KULLANIM: SELECT * FROM kategori_kitap_istatistik(6);
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION kategori_kitap_istatistik(p_kategori_kodu INTEGER)
RETURNS TABLE(
    toplam_kitap INTEGER, 
    rafta_kitap INTEGER, 
    oduncte_kitap INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER AS toplam_kitap,
        COUNT(*) FILTER (WHERE rafta_mi = TRUE)::INTEGER AS rafta_kitap,
        COUNT(*) FILTER (WHERE rafta_mi = FALSE)::INTEGER AS oduncte_kitap
    FROM kitaplar
    WHERE kategori_kodu = p_kategori_kodu;
END;
$$ LANGUAGE plpgsql;

-- YORUM: Bu fonksiyon TABLE döndürür (çoklu değer).
-- Dashboard'da kategori bazlı istatistik göstermek için kullanılır.
-- FILTER (WHERE ...) PostgreSQL'e özgü gelişmiş bir özelliktir.













-- =============================================================================
-- BÖLÜM 2: TETİKLEYİCİLER / TRIGGERS (4 ADET)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TETİKLEYİCİ 1: trg_odunc_kitap_guncelle
-- -----------------------------------------------------------------------------
-- AÇIKLAMA: Kitap ödünç verildiğinde otomatik olarak rafta_mi = FALSE yapar
-- OLAY: odunc_islemleri tablosuna INSERT yapıldığında
-- ZAMANLAMA: AFTER INSERT (işlem sonrası)
-- -----------------------------------------------------------------------------

-- Önce trigger fonksiyonunu oluştur
CREATE OR REPLACE FUNCTION fn_odunc_kitap_guncelle() 
RETURNS TRIGGER AS $$
BEGIN
    -- Ödünç verilen kitabı raftan çıkar
    UPDATE kitaplar 
    SET rafta_mi = FALSE 
    WHERE kitap_kodu = NEW.kitap_kodu;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Varsa eski trigger'ı sil ve yenisini oluştur
DROP TRIGGER IF EXISTS trg_odunc_kitap_guncelle ON odunc_islemleri;

CREATE TRIGGER trg_odunc_kitap_guncelle 
    AFTER INSERT ON odunc_islemleri
    FOR EACH ROW 
    EXECUTE FUNCTION fn_odunc_kitap_guncelle();

-- YORUM: NEW keyword'ü eklenen yeni satırı temsil eder.
-- Bu trigger sayesinde manuel UPDATE yapmaya gerek kalmaz.


















-- -----------------------------------------------------------------------------
-- TETİKLEYİCİ 2: trg_iade_kitap_guncelle
-- AÇIKLAMA: Kitap iade edildiğinde otomatik olarak rafta_mi = TRUE yapar
-- OLAY: odunc_islemleri tablosunda durum 'teslim edildi' olarak UPDATE edildiğinde
-- ZAMANLAMA: AFTER UPDATE (güncelleme sonrası)

CREATE OR REPLACE FUNCTION fn_iade_kitap_guncelle() 
RETURNS TRIGGER AS $$
BEGIN
    -- Sadece durum 'teslim edildi' olarak değiştiyse çalış
    IF NEW.durum = 'teslim edildi' AND OLD.durum != 'teslim edildi' THEN
        -- Kitabı rafa geri koy
        UPDATE kitaplar 
        SET rafta_mi = TRUE 
        WHERE kitap_kodu = NEW.kitap_kodu;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_iade_kitap_guncelle ON odunc_islemleri;

CREATE TRIGGER trg_iade_kitap_guncelle 
    AFTER UPDATE ON odunc_islemleri
    FOR EACH ROW 
    EXECUTE FUNCTION fn_iade_kitap_guncelle();

-- YORUM: OLD ve NEW karşılaştırması yapılır.
-- OLD = güncelleme öncesi değer, NEW = güncelleme sonrası değer
-- Bu sayede sadece gerçekten iade edilen kitaplar için çalışır.










-- -----------------------------------------------------------------------------
-- TETİKLEYİCİ 3: trg_gecikme_ceza_olustur
-- AÇIKLAMA: Gecikmiş iade yapıldığında otomatik ceza kaydı oluşturur
-- OLAY: odunc_islemleri tablosunda iade yapıldığında (durum = 'teslim edildi')
-- KURAL: Planlanan tarihten sonra iade edilirse, gecikme başına 5 TL ceza
-- ZAMANLAMA: AFTER UPDATE

CREATE OR REPLACE FUNCTION fn_gecikme_ceza_olustur() 
RETURNS TRIGGER AS $$
DECLARE 
    v_ceza_tutari DECIMAL(10,2);
BEGIN
    -- Sadece teslim edildi durumuna geçişte ve gerçek teslim tarihi varsa
    IF NEW.durum = 'teslim edildi' AND NEW.gercek_teslim_tarihi IS NOT NULL THEN
        -- Gecikme var mı kontrol et
        IF NEW.gercek_teslim_tarihi > NEW.teslim_tarihi_planlanan THEN
            -- Gecikme cezasını hesapla (gün x 5 TL)
            v_ceza_tutari := (NEW.gercek_teslim_tarihi - NEW.teslim_tarihi_planlanan) * 5.00;
            
            -- Ceza kaydı oluştur
            INSERT INTO cezalar (uye_no, islem_no, ceza_tipi, ceza_tutari)
            VALUES (NEW.uye_no, NEW.islem_no, 'gecikme', v_ceza_tutari);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_gecikme_ceza_olustur ON odunc_islemleri;

CREATE TRIGGER trg_gecikme_ceza_olustur 
    AFTER UPDATE ON odunc_islemleri
    FOR EACH ROW 
    EXECUTE FUNCTION fn_gecikme_ceza_olustur();

-- YORUM: Bu trigger Trigger 2 ile aynı anda çalışır (ikisi de AFTER UPDATE).
-- PostgreSQL'de bir tablo üzerinde birden fazla trigger olabilir.










-- -----------------------------------------------------------------------------
-- TETİKLEYİCİ 4: trg_uye_kayit_kontrol
-- AÇIKLAMA: Yeni üye eklenirken otomatik kontrol ve varsayılan değer ataması yapar
-- OLAY: uyeler tablosuna INSERT yapılmadan önce
-- ZAMANLAMA: BEFORE INSERT (işlem öncesi)
-- KONTROLLER:
--   1. kayit_tarihi NULL ise bugünün tarihini ata
--   2. uyelik_durumu NULL ise 'aktif' ata
--   3. TC Kimlik No 11 haneli değilse hata ver

CREATE OR REPLACE FUNCTION fn_uye_kayit_kontrol() 
RETURNS TRIGGER AS $$
BEGIN
    -- Kayıt tarihi boşsa bugünün tarihini ata
    IF NEW.kayit_tarihi IS NULL THEN 
        NEW.kayit_tarihi := CURRENT_DATE; 
    END IF;
    
    -- Üyelik durumu boşsa 'aktif' yap
    IF NEW.uyelik_durumu IS NULL THEN 
        NEW.uyelik_durumu := 'aktif'; 
    END IF;
    
    -- TC Kimlik No kontrolü (11 haneli olmalı)
    IF NEW.tc_kimlik_no IS NOT NULL AND LENGTH(NEW.tc_kimlik_no) != 11 THEN
        RAISE EXCEPTION 'TC Kimlik No 11 haneli olmalıdır! Girilen: %', NEW.tc_kimlik_no;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_uye_kayit_kontrol ON uyeler;

CREATE TRIGGER trg_uye_kayit_kontrol 
    BEFORE INSERT ON uyeler
    FOR EACH ROW 
    EXECUTE FUNCTION fn_uye_kayit_kontrol();

-- YORUM: BEFORE trigger'da NEW değerlerini değiştirebiliriz.
-- AFTER trigger'da değiştirmek mümkün değildir.
-- RAISE EXCEPTION ile işlemi iptal edebiliriz.











-- =============================================================================
-- DOĞRULAMA: Oluşturulan nesneleri kontrol et
-- =============================================================================

-- Fonksiyonları listele
SELECT 
    routine_name AS "Fonksiyon Adı",
    routine_type AS "Tip"
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_type = 'FUNCTION'
  AND routine_name IN ('uye_odunc_sayisi', 'kitap_musaitlik_kontrol', 
                       'gecikme_cezasi_hesapla', 'kategori_kitap_istatistik')
ORDER BY routine_name;

-- Tetikleyicileri listele
SELECT 
    trigger_name AS "Tetikleyici Adı",
    event_manipulation AS "Olay",
    event_object_table AS "Tablo",
    action_timing AS "Zamanlama"
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
ORDER BY trigger_name;