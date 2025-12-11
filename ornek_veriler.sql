-- =============================================================================
-- KÜTÜPHANE YÖNETİM SİSTEMİ - ÖRNEK VERİLER
-- =============================================================================
-- Bu dosyayı Valentina Studio'da çalıştır
-- Sıralama önemli! (Foreign Key bağımlılıkları)
-- =============================================================================


-- 1. ŞEHİRLER (Önce şehirler olmalı - adresler buna bağlı)
INSERT INTO sehirler (plaka_kodu, il_adi, bolge, nufus) VALUES
(1, 'Adana', 'Akdeniz', 2274106),
(6, 'Ankara', 'İç Anadolu', 5747325),
(7, 'Antalya', 'Akdeniz', 2619832),
(16, 'Bursa', 'Marmara', 3147818),
(27, 'Gaziantep', 'Güneydoğu Anadolu', 2130432),
(34, 'İstanbul', 'Marmara', 15840900),
(35, 'İzmir', 'Ege', 4425789),
(41, 'Kocaeli', 'Marmara', 2033441),
(42, 'Konya', 'İç Anadolu', 2277017),
(54, 'Sakarya', 'Marmara', 1060000),
(55, 'Samsun', 'Karadeniz', 1371000),
(61, 'Trabzon', 'Karadeniz', 818000),
(25, 'Erzurum', 'Doğu Anadolu', 762000)
ON CONFLICT (plaka_kodu) DO NOTHING;


-- 2. KATEGORİLER (Hiyerarşik yapı)
INSERT INTO kategoriler (kategori_adi, ust_kategori_kodu, aciklama) VALUES
('Edebiyat', NULL, 'Edebi eserler'),
('Bilim', NULL, 'Bilimsel kitaplar'),
('Tarih', NULL, 'Tarih kitapları'),
('Felsefe', NULL, 'Felsefe kitapları'),
('Çocuk', NULL, 'Çocuk kitapları')
ON CONFLICT (kategori_adi) DO NOTHING;

-- Alt kategoriler (üst kategori ID'lerini al)
INSERT INTO kategoriler (kategori_adi, ust_kategori_kodu, aciklama) VALUES
('Roman', (SELECT kategori_kodu FROM kategoriler WHERE kategori_adi = 'Edebiyat'), 'Roman türü'),
('Şiir', (SELECT kategori_kodu FROM kategoriler WHERE kategori_adi = 'Edebiyat'), 'Şiir kitapları'),
('Hikaye', (SELECT kategori_kodu FROM kategoriler WHERE kategori_adi = 'Edebiyat'), 'Hikaye kitapları'),
('Fizik', (SELECT kategori_kodu FROM kategoriler WHERE kategori_adi = 'Bilim'), 'Fizik bilimi'),
('Matematik', (SELECT kategori_kodu FROM kategoriler WHERE kategori_adi = 'Bilim'), 'Matematik kitapları'),
('Biyoloji', (SELECT kategori_kodu FROM kategoriler WHERE kategori_adi = 'Bilim'), 'Biyoloji kitapları')
ON CONFLICT (kategori_adi) DO NOTHING;


-- 3. YAYIN TÜRLERİ
INSERT INTO yayin_turleri (tur_adi, aciklama) VALUES
('Roman', 'Kurgu edebi eser'),
('Şiir', 'Dizeli edebi eser'),
('Deneme', 'Düşünce yazısı'),
('Araştırma', 'Bilimsel araştırma'),
('Biyografi', 'Yaşam öyküsü'),
('Ansiklopedi', 'Başvuru kaynağı'),
('Ders Kitabı', 'Eğitim materyali')
ON CONFLICT (tur_adi) DO NOTHING;


-- 4. YAYINEVLERİ
INSERT INTO yayinevleri (yayinevi_adi, kurulus_yili, ulke, web_sitesi, eposta) VALUES
('Yapı Kredi Yayınları', 1992, 'Türkiye', 'www.ykykultur.com.tr', 'info@yky.com.tr'),
('Can Yayınları', 1981, 'Türkiye', 'www.canyayinlari.com', 'info@can.com.tr'),
('İletişim Yayınları', 1983, 'Türkiye', 'www.iletisim.com.tr', 'info@iletisim.com.tr'),
('Doğan Kitap', 1998, 'Türkiye', 'www.dogankitap.com.tr', 'info@dogan.com.tr'),
('İş Bankası Kültür Yayınları', 1930, 'Türkiye', 'www.iskultur.com.tr', 'info@iskultur.com.tr'),
('İnkılap Kitabevi', 1928, 'Türkiye', 'www.inkilap.com', 'info@inkilap.com'),
('Everest Yayınları', 2002, 'Türkiye', 'www.everestyayinlari.com', 'info@everest.com.tr')
ON CONFLICT (yayinevi_adi) DO NOTHING;


-- 5. RAFLAR
INSERT INTO raflar (bolum, koridor_no, raf_no, kapasite) VALUES
('yetişkin', 1, 1, 100),
('yetişkin', 1, 2, 100),
('yetişkin', 2, 1, 100),
('yetişkin', 2, 2, 100),
('çocuk', 3, 1, 50),
('çocuk', 3, 2, 50),
('referans', 4, 1, 30),
('dergi', 5, 1, 200),
('arşiv', 6, 1, 500)
ON CONFLICT (koridor_no, raf_no) DO NOTHING;


-- 6. YAZARLAR
INSERT INTO yazarlar (ad, soyad, dogum_tarihi, olum_tarihi, uyruk, biyografi) VALUES
('Orhan', 'Pamuk', '1952-06-07', NULL, 'Türk', 'Nobel ödüllü Türk yazar'),
('Yaşar', 'Kemal', '1923-10-06', '2015-02-28', 'Türk', 'İnce Memed yazarı'),
('Sabahattin', 'Ali', '1907-02-25', '1948-04-02', 'Türk', 'Kürk Mantolu Madonna yazarı'),
('Oğuz', 'Atay', '1934-10-12', '1977-12-13', 'Türk', 'Tutunamayanlar yazarı'),
('Elif', 'Şafak', '1971-10-25', NULL, 'Türk', 'Çağdaş Türk yazarı'),
('Ahmet Hamdi', 'Tanpınar', '1901-06-23', '1962-01-24', 'Türk', 'Huzur romanının yazarı'),
('Nazım', 'Hikmet', '1902-01-15', '1963-06-03', 'Türk', 'Türk şiirinin ustası'),
('Halide Edip', 'Adıvar', '1884-01-01', '1964-01-09', 'Türk', 'Sinekli Bakkal yazarı'),
('Reşat Nuri', 'Güntekin', '1889-11-25', '1956-12-07', 'Türk', 'Çalıkuşu yazarı'),
('Peyami', 'Safa', '1899-04-02', '1961-06-15', 'Türk', 'Fatih-Harbiye yazarı')
ON CONFLICT DO NOTHING;


-- 7. ADRESLER
INSERT INTO adresler (plaka_kodu, ilce, mahalle, cadde_sokak, bina_no) VALUES
(34, 'Kadıköy', 'Caferağa', 'Moda Caddesi', '15'),
(34, 'Beşiktaş', 'Levent', 'Büyükdere Caddesi', '128'),
(6, 'Çankaya', 'Kızılay', 'Atatürk Bulvarı', '45'),
(35, 'Konak', 'Alsancak', 'Kıbrıs Şehitleri Caddesi', '88'),
(54, 'Adapazarı', 'Cumhuriyet', 'Sakarya Caddesi', '22'),
(16, 'Nilüfer', 'Özlüce', 'Bursa Caddesi', '100'),
(41, 'İzmit', 'Yahyakaptan', 'Ankara Caddesi', '56'),
(7, 'Muratpaşa', 'Lara', 'Akdeniz Bulvarı', '33')
ON CONFLICT DO NOTHING;


-- 8. KİTAPLAR
INSERT INTO kitaplar (isbn, baslik, yayinevi_kodu, kategori_kodu, tur_kodu, raf_kodu, basim_yili, sayfa_sayisi, dil, ozet) VALUES
('9789750826139', 'Kürk Mantolu Madonna', 
    (SELECT yayinevi_kodu FROM yayinevleri WHERE yayinevi_adi = 'Yapı Kredi Yayınları'),
    (SELECT kategori_kodu FROM kategoriler WHERE kategori_adi = 'Roman'),
    (SELECT tur_kodu FROM yayin_turleri WHERE tur_adi = 'Roman'),
    1, 2020, 160, 'Türkçe', 'Sabahattin Ali nin ölümsüz eseri'),

('9789750718533', 'İnce Memed',
    (SELECT yayinevi_kodu FROM yayinevleri WHERE yayinevi_adi = 'Yapı Kredi Yayınları'),
    (SELECT kategori_kodu FROM kategoriler WHERE kategori_adi = 'Roman'),
    (SELECT tur_kodu FROM yayin_turleri WHERE tur_adi = 'Roman'),
    1, 2019, 436, 'Türkçe', 'Yaşar Kemal in başyapıtı'),

('9789750802652', 'Tutunamayanlar',
    (SELECT yayinevi_kodu FROM yayinevleri WHERE yayinevi_adi = 'İletişim Yayınları'),
    (SELECT kategori_kodu FROM kategoriler WHERE kategori_adi = 'Roman'),
    (SELECT tur_kodu FROM yayin_turleri WHERE tur_adi = 'Roman'),
    2, 2018, 724, 'Türkçe', 'Oğuz Atay ın başyapıtı'),

('9789750738609', 'Huzur',
    (SELECT yayinevi_kodu FROM yayinevleri WHERE yayinevi_adi = 'Doğan Kitap'),
    (SELECT kategori_kodu FROM kategoriler WHERE kategori_adi = 'Roman'),
    (SELECT tur_kodu FROM yayin_turleri WHERE tur_adi = 'Roman'),
    2, 2021, 360, 'Türkçe', 'İstanbul romanı'),

('9789750845789', 'Çalıkuşu',
    (SELECT yayinevi_kodu FROM yayinevleri WHERE yayinevi_adi = 'İnkılap Kitabevi'),
    (SELECT kategori_kodu FROM kategoriler WHERE kategori_adi = 'Roman'),
    (SELECT tur_kodu FROM yayin_turleri WHERE tur_adi = 'Roman'),
    1, 2022, 512, 'Türkçe', 'Feride nin hikayesi'),

('9789750512345', 'Bütün Şiirleri',
    (SELECT yayinevi_kodu FROM yayinevleri WHERE yayinevi_adi = 'Yapı Kredi Yayınları'),
    (SELECT kategori_kodu FROM kategoriler WHERE kategori_adi = 'Şiir'),
    (SELECT tur_kodu FROM yayin_turleri WHERE tur_adi = 'Şiir'),
    3, 2020, 850, 'Türkçe', 'Nazım Hikmet şiirleri'),

('9789750867890', 'Sinekli Bakkal',
    (SELECT yayinevi_kodu FROM yayinevleri WHERE yayinevi_adi = 'Can Yayınları'),
    (SELECT kategori_kodu FROM kategoriler WHERE kategori_adi = 'Roman'),
    (SELECT tur_kodu FROM yayin_turleri WHERE tur_adi = 'Roman'),
    2, 2019, 304, 'Türkçe', 'Halide Edip Adıvar eseri'),

('9789750898765', 'Fatih-Harbiye',
    (SELECT yayinevi_kodu FROM yayinevleri WHERE yayinevi_adi = 'İş Bankası Kültür Yayınları'),
    (SELECT kategori_kodu FROM kategoriler WHERE kategori_adi = 'Roman'),
    (SELECT tur_kodu FROM yayin_turleri WHERE tur_adi = 'Roman'),
    1, 2021, 192, 'Türkçe', 'Doğu-Batı çatışması'),

('9789750823456', 'Masumiyet Müzesi',
    (SELECT yayinevi_kodu FROM yayinevleri WHERE yayinevi_adi = 'Yapı Kredi Yayınları'),
    (SELECT kategori_kodu FROM kategoriler WHERE kategori_adi = 'Roman'),
    (SELECT tur_kodu FROM yayin_turleri WHERE tur_adi = 'Roman'),
    2, 2018, 592, 'Türkçe', 'Orhan Pamuk romanı'),

('9789750834567', 'Aşk',
    (SELECT yayinevi_kodu FROM yayinevleri WHERE yayinevi_adi = 'Doğan Kitap'),
    (SELECT kategori_kodu FROM kategoriler WHERE kategori_adi = 'Roman'),
    (SELECT tur_kodu FROM yayin_turleri WHERE tur_adi = 'Roman'),
    3, 2022, 448, 'Türkçe', 'Elif Şafak romanı')
ON CONFLICT (isbn) DO NOTHING;


-- 9. KİTAP-YAZAR İLİŞKİSİ
INSERT INTO kitap_yazarlar (kitap_kodu, yazar_kodu, yazar_sirasi) 
SELECT k.kitap_kodu, y.yazar_kodu, 1
FROM kitaplar k, yazarlar y
WHERE k.baslik = 'Kürk Mantolu Madonna' AND y.soyad = 'Ali'
ON CONFLICT DO NOTHING;

INSERT INTO kitap_yazarlar (kitap_kodu, yazar_kodu, yazar_sirasi) 
SELECT k.kitap_kodu, y.yazar_kodu, 1
FROM kitaplar k, yazarlar y
WHERE k.baslik = 'İnce Memed' AND y.soyad = 'Kemal'
ON CONFLICT DO NOTHING;

INSERT INTO kitap_yazarlar (kitap_kodu, yazar_kodu, yazar_sirasi) 
SELECT k.kitap_kodu, y.yazar_kodu, 1
FROM kitaplar k, yazarlar y
WHERE k.baslik = 'Tutunamayanlar' AND y.soyad = 'Atay'
ON CONFLICT DO NOTHING;

INSERT INTO kitap_yazarlar (kitap_kodu, yazar_kodu, yazar_sirasi) 
SELECT k.kitap_kodu, y.yazar_kodu, 1
FROM kitaplar k, yazarlar y
WHERE k.baslik = 'Huzur' AND y.soyad = 'Tanpınar'
ON CONFLICT DO NOTHING;

INSERT INTO kitap_yazarlar (kitap_kodu, yazar_kodu, yazar_sirasi) 
SELECT k.kitap_kodu, y.yazar_kodu, 1
FROM kitaplar k, yazarlar y
WHERE k.baslik = 'Çalıkuşu' AND y.soyad = 'Güntekin'
ON CONFLICT DO NOTHING;

INSERT INTO kitap_yazarlar (kitap_kodu, yazar_kodu, yazar_sirasi) 
SELECT k.kitap_kodu, y.yazar_kodu, 1
FROM kitaplar k, yazarlar y
WHERE k.baslik = 'Bütün Şiirleri' AND y.soyad = 'Hikmet'
ON CONFLICT DO NOTHING;

INSERT INTO kitap_yazarlar (kitap_kodu, yazar_kodu, yazar_sirasi) 
SELECT k.kitap_kodu, y.yazar_kodu, 1
FROM kitaplar k, yazarlar y
WHERE k.baslik = 'Sinekli Bakkal' AND y.soyad = 'Adıvar'
ON CONFLICT DO NOTHING;

INSERT INTO kitap_yazarlar (kitap_kodu, yazar_kodu, yazar_sirasi) 
SELECT k.kitap_kodu, y.yazar_kodu, 1
FROM kitaplar k, yazarlar y
WHERE k.baslik = 'Fatih-Harbiye' AND y.soyad = 'Safa'
ON CONFLICT DO NOTHING;

INSERT INTO kitap_yazarlar (kitap_kodu, yazar_kodu, yazar_sirasi) 
SELECT k.kitap_kodu, y.yazar_kodu, 1
FROM kitaplar k, yazarlar y
WHERE k.baslik = 'Masumiyet Müzesi' AND y.soyad = 'Pamuk'
ON CONFLICT DO NOTHING;

INSERT INTO kitap_yazarlar (kitap_kodu, yazar_kodu, yazar_sirasi) 
SELECT k.kitap_kodu, y.yazar_kodu, 1
FROM kitaplar k, yazarlar y
WHERE k.baslik = 'Aşk' AND y.soyad = 'Şafak'
ON CONFLICT DO NOTHING;


-- 10. ÜYELER
INSERT INTO uyeler (ad, soyad, tc_kimlik_no, cinsiyet, dogum_tarihi, uyelik_tipi, adres_id) VALUES
('Ahmet', 'Yılmaz', '12345678901', 'E', '1995-03-15', 'öğrenci', 1),
('Ayşe', 'Kaya', '12345678902', 'K', '1988-07-22', 'standart', 2),
('Mehmet', 'Demir', '12345678903', 'E', '1975-11-30', 'akademisyen', 3),
('Fatma', 'Çelik', '12345678904', 'K', '2000-01-10', 'öğrenci', 4),
('Ali', 'Öztürk', '12345678905', 'E', '1992-05-25', 'standart', 5),
('Zeynep', 'Arslan', '12345678906', 'K', '1985-09-18', 'akademisyen', 6),
('Mustafa', 'Şahin', '12345678907', 'E', '1998-12-05', 'öğrenci', 7),
('Emine', 'Yıldız', '12345678908', 'K', '1990-04-12', 'standart', 8)
ON CONFLICT (tc_kimlik_no) DO NOTHING;


-- 11. PERSONEL
INSERT INTO personel (ad, soyad, tc_kimlik_no, gorev, maas, telefon, eposta, adres_id) VALUES
('Hasan', 'Avcı', '98765432101', 'müdür', 25000.00, '05551234567', 'hasan@kutuphane.com', 1),
('Elif', 'Korkmaz', '98765432102', 'kütüphaneci', 15000.00, '05559876543', 'elif@kutuphane.com', 2),
('Can', 'Yılmaz', '98765432103', 'kütüphaneci', 14500.00, '05554567890', 'can@kutuphane.com', 3),
('Seda', 'Aktaş', '98765432104', 'teknisyen', 12000.00, '05557891234', 'seda@kutuphane.com', 4)
ON CONFLICT (tc_kimlik_no) DO NOTHING;


-- 12. ÖDÜNÇ İŞLEMLERİ (Örnek)
INSERT INTO odunc_islemleri (uye_no, kitap_kodu, personel_no, teslim_tarihi_planlanan, durum)
SELECT 
    u.uye_no, 
    k.kitap_kodu, 
    p.personel_no,
    CURRENT_DATE + INTERVAL '14 days',
    'ödünçte'
FROM uyeler u, kitaplar k, personel p
WHERE u.ad = 'Ahmet' AND k.baslik = 'Kürk Mantolu Madonna' AND p.gorev = 'kütüphaneci'
LIMIT 1;

-- Bu kitabı raftan çıkar
UPDATE kitaplar SET rafta_mi = FALSE WHERE baslik = 'Kürk Mantolu Madonna';


-- 13. İLETİŞİM BİLGİLERİ
INSERT INTO iletisim_bilgileri (uye_no, iletisim_tipi, iletisim_degeri, birincil_mi)
SELECT uye_no, 'cep telefonu', '0555' || (1000000 + uye_no)::TEXT, TRUE
FROM uyeler;

INSERT INTO iletisim_bilgileri (uye_no, iletisim_tipi, iletisim_degeri, birincil_mi)
SELECT uye_no, 'eposta', LOWER(ad) || '.' || LOWER(soyad) || '@email.com', FALSE
FROM uyeler;


-- =============================================================================
-- VERİ KONTROL
-- =============================================================================
SELECT 'Şehirler:' AS tablo, COUNT(*) AS kayit_sayisi FROM sehirler
UNION ALL
SELECT 'Kategoriler:', COUNT(*) FROM kategoriler
UNION ALL
SELECT 'Yayın Türleri:', COUNT(*) FROM yayin_turleri
UNION ALL
SELECT 'Yayınevleri:', COUNT(*) FROM yayinevleri
UNION ALL
SELECT 'Raflar:', COUNT(*) FROM raflar
UNION ALL
SELECT 'Yazarlar:', COUNT(*) FROM yazarlar
UNION ALL
SELECT 'Kitaplar:', COUNT(*) FROM kitaplar
UNION ALL
SELECT 'Üyeler:', COUNT(*) FROM uyeler
UNION ALL
SELECT 'Personel:', COUNT(*) FROM personel
UNION ALL
SELECT 'Ödünç İşlemleri:', COUNT(*) FROM odunc_islemleri;