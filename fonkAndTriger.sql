-- =============================================================================
-- KÜTÜPHANE YÖNETİM SİSTEMİ - FONKSİYONLAR VE TETİKLEYİCİLER
-- =============================================================================
-- Bu dosyayı Valentina Studio'da çalıştır
-- NOT: Önce veritabani_olustur.sql ve ornek_veriler.sql çalıştırılmış olmalı
-- =============================================================================


-- =============================================================================
-- FONKSİYONLAR / SAKLI YORDAMLAR (4 ADET)
-- =============================================================================


-- -----------------------------------------------------------------------------
-- FONKSİYON 1: uye_odunc_sayisi
-- -----------------------------------------------------------------------------
-- Açıklama: Bir üyenin şu anda elinde kaç kitap olduğunu döndürür.
-- Kullanım: SELECT uye_odunc_sayisi(1);
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION uye_odunc_sayisi(p_uye_no INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_sayi INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_sayi
    FROM odunc_islemleri
    WHERE uye_no = p_uye_no AND durum = 'ödünçte';
    
    RETURN v_sayi;
END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- FONKSİYON 2: kitap_musaitlik_kontrol
-- -----------------------------------------------------------------------------
-- Açıklama: Bir kitabın ödünç alınabilir durumda olup olmadığını kontrol eder.
-- Kullanım: SELECT kitap_musaitlik_kontrol(1);
-- Döndürür: TRUE (müsait) veya FALSE (müsait değil)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION kitap_musaitlik_kontrol(p_kitap_kodu INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    v_rafta BOOLEAN;
BEGIN
    SELECT rafta_mi INTO v_rafta
    FROM kitaplar
    WHERE kitap_kodu = p_kitap_kodu;
    
    IF v_rafta IS NULL THEN
        RAISE EXCEPTION 'Kitap bulunamadı: %', p_kitap_kodu;
    END IF;
    
    RETURN v_rafta;
END;
$$ LANGUAGE plpgsql;


-- -----------------------------------------------------------------------------
-- FONKSİYON 3: gecikme_cezasi_hesapla
-- -----------------------------------------------------------------------------
-- Açıklama: Geciken kitap için ceza tutarını hesaplar (günlük 5 TL).
-- Kullanım: SELECT gecikme_cezasi_hesapla(1);
-- Parametreler: islem_no (ödünç işlem numarası)
-- Döndürür: Ceza tutarı (DECIMAL) veya 0
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION gecikme_cezasi_hesapla(p_islem_no INTEGER)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    v_planlanan DATE;
    v_gercek DATE;
    v_gecikme_gun INTEGER;
    v_gunluk_ceza DECIMAL(10,2) := 5.00; -- Günlük 5 TL ceza
BEGIN
    SELECT teslim_tarihi_planlanan, gercek_teslim_tarihi 
    INTO v_planlanan, v_gercek
    FROM odunc_islemleri
    WHERE islem_no = p_islem_no;
    
    -- Henüz iade edilmediyse bugünü kullan
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


-- -----------------------------------------------------------------------------
-- FONKSİYON 4: kategori_kitap_istatistik
-- -----------------------------------------------------------------------------
-- Açıklama: Belirli bir kategorideki kitap sayısını ve ödünçte olan sayısını döndürür.
-- Kullanım: SELECT * FROM kategori_kitap_istatistik(1);
-- Döndürür: Tablo (toplam_kitap, rafta_kitap, oduncte_kitap)
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


-- =============================================================================
-- TETİKLEYİCİLER / TRIGGERS (4 ADET)
-- =============================================================================


-- -----------------------------------------------------------------------------
-- TETİKLEYİCİ 1: trg_odunc_kitap_guncelle
-- -----------------------------------------------------------------------------
-- Açıklama: Ödünç işlemi eklendiğinde kitabın rafta_mi durumunu FALSE yapar.
-- Tetikleme: odunc_islemleri tablosuna INSERT sonrası
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_odunc_kitap_guncelle()
RETURNS TRIGGER AS $$
BEGIN
    -- Kitabı raftan çıkar
    UPDATE kitaplar 
    SET rafta_mi = FALSE 
    WHERE kitap_kodu = NEW.kitap_kodu;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Eğer tetikleyici varsa sil
DROP TRIGGER IF EXISTS trg_odunc_kitap_guncelle ON odunc_islemleri;

-- Tetikleyiciyi oluştur
CREATE TRIGGER trg_odunc_kitap_guncelle
    AFTER INSERT ON odunc_islemleri
    FOR EACH ROW
    EXECUTE FUNCTION fn_odunc_kitap_guncelle();


-- -----------------------------------------------------------------------------
-- TETİKLEYİCİ 2: trg_iade_kitap_guncelle
-- -----------------------------------------------------------------------------
-- Açıklama: Kitap iade edildiğinde (durum='teslim edildi') rafta_mi'yi TRUE yapar.
-- Tetikleme: odunc_islemleri tablosunda UPDATE sonrası
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_iade_kitap_guncelle()
RETURNS TRIGGER AS $$
BEGIN
    -- Eğer durum 'teslim edildi' olarak güncellendiyse
    IF NEW.durum = 'teslim edildi' AND OLD.durum != 'teslim edildi' THEN
        -- Kitabı rafa koy
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


-- -----------------------------------------------------------------------------
-- TETİKLEYİCİ 3: trg_gecikme_ceza_olustur
-- -----------------------------------------------------------------------------
-- Açıklama: Gecikmiş kitap iade edildiğinde otomatik ceza kaydı oluşturur.
-- Tetikleme: odunc_islemleri tablosunda UPDATE sonrası
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_gecikme_ceza_olustur()
RETURNS TRIGGER AS $$
DECLARE
    v_ceza_tutari DECIMAL(10,2);
BEGIN
    -- Sadece teslim edildiğinde çalış
    IF NEW.durum = 'teslim edildi' AND NEW.gercek_teslim_tarihi IS NOT NULL THEN
        -- Gecikme kontrolü
        IF NEW.gercek_teslim_tarihi > NEW.teslim_tarihi_planlanan THEN
            -- Ceza tutarını hesapla
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


-- -----------------------------------------------------------------------------
-- TETİKLEYİCİ 4: trg_uye_kayit_log
-- -----------------------------------------------------------------------------
-- Açıklama: Yeni üye kaydında kayıt tarihini otomatik ayarlar ve doğrulama yapar.
-- Tetikleme: uyeler tablosuna INSERT öncesi
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_uye_kayit_kontrol()
RETURNS TRIGGER AS $$
BEGIN
    -- Kayıt tarihini bugün olarak ayarla (eğer boşsa)
    IF NEW.kayit_tarihi IS NULL THEN
        NEW.kayit_tarihi := CURRENT_DATE;
    END IF;
    
    -- Üyelik durumunu aktif yap (eğer boşsa)
    IF NEW.uyelik_durumu IS NULL THEN
        NEW.uyelik_durumu := 'aktif';
    END IF;
    
    -- TC Kimlik No kontrolü (11 haneli olmalı)
    IF NEW.tc_kimlik_no IS NOT NULL AND LENGTH(NEW.tc_kimlik_no) != 11 THEN
        RAISE EXCEPTION 'TC Kimlik No 11 haneli olmalıdır!';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_uye_kayit_log ON uyeler;

CREATE TRIGGER trg_uye_kayit_log
    BEFORE INSERT ON uyeler
    FOR EACH ROW
    EXECUTE FUNCTION fn_uye_kayit_kontrol();


-- =============================================================================
-- TEST SORGULARI
-- =============================================================================

-- Fonksiyon testleri:
-- SELECT uye_odunc_sayisi(1);                    -- 1 numaralı üyenin ödünç sayısı
-- SELECT kitap_musaitlik_kontrol(1);             -- 1 numaralı kitap müsait mi?
-- SELECT gecikme_cezasi_hesapla(1);              -- 1 numaralı işlemin cezası
-- SELECT * FROM kategori_kitap_istatistik(6);    -- Roman kategorisi istatistikleri

-- Tetikleyici testleri (otomatik çalışır):
-- INSERT ile ödünç işlemi eklendiğinde kitap raftan çıkar
-- UPDATE ile durum='teslim edildi' yapılınca kitap rafa döner
-- Gecikmiş iadede otomatik ceza oluşur
-- Yeni üye eklendiğinde kayıt tarihi ve durum otomatik ayarlanır


-- =============================================================================
-- ÖZET: FONKSİYON VE TETİKLEYİCİLER
-- =============================================================================
/*
FONKSİYONLAR (4 Adet):
1. uye_odunc_sayisi(p_uye_no) - Üyenin elindeki kitap sayısını döndürür
2. kitap_musaitlik_kontrol(p_kitap_kodu) - Kitabın rafta olup olmadığını kontrol eder
3. gecikme_cezasi_hesapla(p_islem_no) - Gecikme cezası tutarını hesaplar
4. kategori_kitap_istatistik(p_kategori_kodu) - Kategori bazlı kitap istatistiklerini döndürür

TETİKLEYİCİLER (4 Adet):
1. trg_odunc_kitap_guncelle - Ödünç verilince kitabı raftan çıkarır
2. trg_iade_kitap_guncelle - İade edilince kitabı rafa koyar
3. trg_gecikme_ceza_olustur - Gecikmiş iadede otomatik ceza kaydı oluşturur
4. trg_uye_kayit_log - Yeni üye kaydında otomatik tarih ve durum ataması yapar
*/