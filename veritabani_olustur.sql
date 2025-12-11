--CREATE DATABASE kutuphane_db = NOT direkt localhosttan new database dedim


-- Şehirler tablosu (İl bilgileri)
CREATE TABLE sehirler (
    plaka_kodu INTEGER PRIMARY KEY,              --PK ( OTOMOTİK NOT NULL VE UNİQUE OLUR)
    il_adi VARCHAR(50) NOT NULL UNIQUE,   -- EN FAZLA 50 KARAKTER ,İkinci bir "İstanbul" eklenemez
    bolge VARCHAR(30) NOT NULL,		
    nufus INTEGER,
    CONSTRAINT chk_plaka CHECK (plaka_kodu BETWEEN 1 AND 81),  -- CONSTRAINT = KURAL
    CONSTRAINT chk_bolge CHECK (bolge IN ('Marmara', 'Ege', 'Akdeniz', 'İç Anadolu', 'Karadeniz', 'Doğu Anadolu', 'Güneydoğu Anadolu'))
);







-- Adresler tablosunu oluştur (Şehirlere foreign key ile bağlı)
CREATE TABLE adresler (
    adres_id SERIAL PRIMARY KEY,          
    --SERİAL = HER YENİ SAYI EKLENDİĞİNDE OTOMOTİK ARTAR BİZİM DEĞER VERMEMİZE GEREK YOK SERİAL DA
    plaka_kodu INTEGER NOT NULL,	
    ilce VARCHAR(50) NOT NULL,
    mahalle VARCHAR(100),
    cadde_sokak VARCHAR(150),
    bina_no VARCHAR(10),
    daire_no VARCHAR(10),
    posta_kodu VARCHAR(10),
    tam_adres_metni TEXT,               -- SINIRSIZ UZUNLUK
    CONSTRAINT fk_adres_sehir FOREIGN KEY (plaka_kodu) 
        REFERENCES sehirler(plaka_kodu) ON DELETE RESTRICT  
        -- Şehir silinemez (adresler varken)
        -- sehirde adres varsa o sehri silemezsin 	adresler tablosundaki plaka_kodu, sehirler tablosundaki plaka_kodu'na işaret eder eğer adres eklersem o plaka sehirler tablosunda mutlaka olmalı çünkü bağlantı var
);






-- Üyeler tablosu (Kütüphane üyeleri)
CREATE TABLE uyeler (
    uye_no SERIAL PRIMARY KEY,
    ad VARCHAR(50) NOT NULL,
    soyad VARCHAR(50) NOT NULL,
    tc_kimlik_no CHAR(11) UNIQUE,
    -- sabit uzunluklu karakter 11 olucak mecburi
    cinsiyet CHAR(1), -- e yada k
    dogum_tarihi DATE,
    kayit_tarihi DATE DEFAULT CURRENT_DATE, -- eğer dışarıdan girilmezse varsayılan değer bu günün tarihi yani mevcut tarih olur
    uyelik_durumu VARCHAR(20) DEFAULT 'aktif', -- değer verilmezse otomatik aktif olur
    uyelik_tipi VARCHAR(20) NOT NULL,
    adres_id INTEGER,
    CONSTRAINT chk_cinsiyet CHECK (cinsiyet IN ('E', 'K')),
    CONSTRAINT chk_uyelik_durumu CHECK (uyelik_durumu IN ('aktif', 'pasif')),
    CONSTRAINT chk_uyelik_tipi CHECK (uyelik_tipi IN ('öğrenci', 'akademisyen', 'standart')),
    CONSTRAINT fk_uye_adres FOREIGN KEY (adres_id) 
        REFERENCES adresler(adres_id) ON DELETE SET NULL
        -- Adres silinebilir (üyeler kalır, adres_id NULL olur)
        -- eğer bu adres silinirse o kişinin adresi null olur. yani adress id null olur
);






-- İletişim bilgileri tablosu(Üyelerin telefon ve email bilgileri)
CREATE TABLE iletisim_bilgileri (
    iletisim_id SERIAL PRIMARY KEY,
    uye_no INTEGER NOT NULL,
    iletisim_tipi VARCHAR(20) NOT NULL,
    iletisim_degeri VARCHAR(100) NOT NULL,
    birincil_mi BOOLEAN DEFAULT FALSE, 
    --bir kisinin birden çok iletişim bilgisi olabilir o nedenle bu en birincil iletisim bilgisi mi diye kaydeder. 1 tane birincil olabilir. eğer birincil kaydedilmezse otomatik ikincil olur
    CONSTRAINT chk_iletisim_tipi CHECK (iletisim_tipi IN ('cep telefonu', 'ev telefonu', 'iş telefonu', 'eposta')),
    CONSTRAINT fk_iletisim_uye FOREIGN KEY (uye_no) 
        REFERENCES uyeler(uye_no) ON DELETE CASCADE
-- üye silinirse iletişim bilgisiini de sil 
        --3 tane var
        /*
        ! restrict
        burda pk silinirse bu fk silinmesini engeller 
        ! set null
        eğer ssilinirse null ayarla
        ! cascade
        eğer üstü yani fk olduğu yer silinirse buda silinir
        */
);







-- Personel tablosu (Kütüphane çalışanları)
CREATE TABLE personel (
    personel_no SERIAL PRIMARY KEY,
    ad VARCHAR(50) NOT NULL,
    soyad VARCHAR(50) NOT NULL,
    tc_kimlik_no CHAR(11) UNIQUE NOT NULL,
    gorev VARCHAR(30) NOT NULL,
    ise_baslama_tarihi DATE DEFAULT CURRENT_DATE,
    maas DECIMAL(10, 2), -- virgulden sonra 2 basamak toplam 10 basamak al
    telefon VARCHAR(15),
    eposta VARCHAR(100),
    adres_id INTEGER,
    CONSTRAINT chk_gorev CHECK (gorev IN ('kütüphaneci', 'müdür', 'teknisyen')),
    CONSTRAINT fk_personel_adres FOREIGN KEY (adres_id) 
        REFERENCES adresler(adres_id) ON DELETE SET NULL
);
/*
! integer
tam sayı
!decimal
ondalıklı ama az değer alır
!float 
bilimsel değerler
*/







-- Yayınevleri tablosunu oluştur
CREATE TABLE yayinevleri (
    yayinevi_kodu SERIAL PRIMARY KEY,
    yayinevi_adi VARCHAR(100) NOT NULL UNIQUE,
    kurulus_yili INTEGER,
    ulke VARCHAR(50),
    web_sitesi VARCHAR(150),
    telefon VARCHAR(15),
    eposta VARCHAR(100),
    CONSTRAINT chk_kurulus_yili CHECK (kurulus_yili > 1400 AND kurulus_yili <= EXTRACT(YEAR FROM CURRENT_DATE))

    -- kurulus yili bu günden kucuk 1400 den büyük olmalı.
    --extract parçala demek tarihi parçala yılı al
);


-- Kategoriler tablosunu oluştur (Kitap kategorileri - hiyerarşik yapı)
CREATE TABLE kategoriler (
    kategori_kodu SERIAL PRIMARY KEY,
    kategori_adi VARCHAR(100) NOT NULL UNIQUE,
    ust_kategori_kodu INTEGER,
    aciklama TEXT,
    CONSTRAINT fk_kategori_ust FOREIGN KEY (ust_kategori_kodu) 
        REFERENCES kategoriler(kategori_kodu) ON DELETE SET NULL
);

/*
referencess sayesinde kategoriler arasında referans kurabiliyorum 
kategori_kodu | kategori_adi    | ust_kategori_kodu
--------------|-----------------|-------------------
1             | Edebiyat        | NULL        ⬅ Ana
2             | Roman           | 1           ⬅ Edebiyat'ın altı
3             | Polisiye Roman  | 2           ⬅ Roman'ın altı
5             | Şiir            | 1           ⬅ Edebiyat'ın altı
6             | Bilim           | NULL        ⬅ Ana
Ana Kategoriler (ust_kategori_kodu = NULL)
│
├─ Edebiyat (ID: 1, ust: NULL)
│  ├─ Roman (ID: 2, ust: 1)
│  │  ├─ Polisiye Roman (ID: 3, ust: 2)
│  │  └─ Bilim Kurgu (ID: 4, ust: 2)
│  └─ Şiir (ID: 5, ust: 1)
│
└─ Bilim (ID: 6, ust: NULL)
   ├─ Fizik (ID: 7, ust: 6)
   └─ Biyoloji (ID: 8, ust: 6)

   bu sekilde bir hiyerarsi kurabilmemi sağlıyor
*/



-- Yayın türleri tablosunu oluştur (Roman, araştırma, dergi vb.)
CREATE TABLE yayin_turleri (
    tur_kodu SERIAL PRIMARY KEY,
    tur_adi VARCHAR(50) NOT NULL UNIQUE,
    aciklama TEXT
);





-- Raflar tablosunu oluştur (Kütüphanedeki fiziksel raflar)
CREATE TABLE raflar (
    raf_kodu SERIAL PRIMARY KEY,
    bolum VARCHAR(50) NOT NULL,
    koridor_no INTEGER NOT NULL,
    raf_no INTEGER NOT NULL,
    kapasite INTEGER DEFAULT 100,
    dolu_mu BOOLEAN DEFAULT FALSE,
    CONSTRAINT chk_bolum CHECK (bolum IN ('çocuk', 'yetişkin', 'referans', 'dergi', 'arşiv')),
    CONSTRAINT unique_raf UNIQUE (koridor_no, raf_no)
    -- koridor ve raf no beraber unique olmalı 
    /*
    Her koridorda aynı numaralı raf olabilir
    Ama aynı koridorda aynı numara 2 kez olamaz
    */
);







-- Yazarlar tablosunu oluştur
CREATE TABLE yazarlar (
    yazar_kodu SERIAL PRIMARY KEY,
    ad VARCHAR(50) NOT NULL,
    soyad VARCHAR(50) NOT NULL,
    dogum_tarihi DATE,
    olum_tarihi DATE,
    uyruk VARCHAR(50),
    biyografi TEXT,
    fotograf VARCHAR(255),
    CONSTRAINT chk_tarih CHECK (olum_tarihi IS NULL OR olum_tarihi > dogum_tarihi)
-- yazarın olum tarihi ya null olucak yada dogum tarihinden buyuk olucak 
--"chk_tarih" sayesinde hata verirse chk_tarih diye vericek hemen yerini bulabilecez
);



------------------------------------------------------------

-- Kitaplar tablosunu oluştur (Ana kitap bilgileri)
CREATE TABLE kitaplar (
    kitap_kodu SERIAL PRIMARY KEY,
    isbn VARCHAR(13) UNIQUE,
    baslik VARCHAR(200) NOT NULL,
    yayinevi_kodu INTEGER,
    kategori_kodu INTEGER,
    tur_kodu INTEGER,
    raf_kodu INTEGER,
    basim_yili INTEGER,
    sayfa_sayisi INTEGER,
    dil VARCHAR(30) DEFAULT 'Türkçe',
    ozet TEXT,
    kapak_resmi VARCHAR(255),
    rafta_mi BOOLEAN DEFAULT TRUE,
    eklenme_tarihi DATE DEFAULT CURRENT_DATE,
    CONSTRAINT chk_basim_yili CHECK (basim_yili > 1400 AND basim_yili <= EXTRACT(YEAR FROM CURRENT_DATE)),
    CONSTRAINT chk_sayfa_sayisi CHECK (sayfa_sayisi > 0),
    CONSTRAINT fk_kitap_yayinevi FOREIGN KEY (yayinevi_kodu) 
        REFERENCES yayinevleri(yayinevi_kodu) ON DELETE SET NULL,
    CONSTRAINT fk_kitap_kategori FOREIGN KEY (kategori_kodu) 
        REFERENCES kategoriler(kategori_kodu) ON DELETE SET NULL,
    CONSTRAINT fk_kitap_tur FOREIGN KEY (tur_kodu) 
        REFERENCES yayin_turleri(tur_kodu) ON DELETE SET NULL,
    CONSTRAINT fk_kitap_raf FOREIGN KEY (raf_kodu) 
        REFERENCES raflar(raf_kodu) ON DELETE SET NULL
);


-- Kitap-Yazar ilişki tablosunu oluştur (Bir kitabın birden fazla yazarı olabilir)
CREATE TABLE kitap_yazarlar (
    kitap_kodu INTEGER NOT NULL,
    yazar_kodu INTEGER NOT NULL,
    yazar_sirasi INTEGER DEFAULT 1,
    PRIMARY KEY (kitap_kodu, yazar_kodu),
    CONSTRAINT fk_kyazar_kitap FOREIGN KEY (kitap_kodu) 
        REFERENCES kitaplar(kitap_kodu) ON DELETE CASCADE,
    CONSTRAINT fk_kyazar_yazar FOREIGN KEY (yazar_kodu) 
        REFERENCES yazarlar(yazar_kodu) ON DELETE CASCADE
);






-- Bağışlar tablosunu oluştur (Kütüphaneye yapılan kitap bağışları)
CREATE TABLE bagislar (
    bagis_no SERIAL PRIMARY KEY,
    bagis_tarihi DATE DEFAULT CURRENT_DATE,
    bagisci_adi VARCHAR(100) NOT NULL,
    bagisci_telefon VARCHAR(15),
    bagis_edilen_kitap_sayisi INTEGER DEFAULT 1,
    notlar TEXT,
    CONSTRAINT chk_kitap_sayisi CHECK (bagis_edilen_kitap_sayisi > 0)
);



-- Ödünç işlemleri tablosunu oluştur (Kitap ödünç alma kayıtları)
CREATE TABLE odunc_islemleri (
    islem_no SERIAL PRIMARY KEY,
    uye_no INTEGER NOT NULL,
    kitap_kodu INTEGER NOT NULL,
    personel_no INTEGER,
    odunc_alma_tarihi DATE DEFAULT CURRENT_DATE,
    teslim_tarihi_planlanan DATE NOT NULL,
    gercek_teslim_tarihi DATE,
    durum VARCHAR(20) DEFAULT 'ödünçte',
    yenileme_sayisi INTEGER DEFAULT 0,
    CONSTRAINT chk_durum CHECK (durum IN ('ödünçte', 'teslim edildi', 'gecikmiş')),
    CONSTRAINT chk_teslim CHECK (teslim_tarihi_planlanan > odunc_alma_tarihi),
    CONSTRAINT fk_odunc_uye FOREIGN KEY (uye_no) 
        REFERENCES uyeler(uye_no) ON DELETE CASCADE,
    CONSTRAINT fk_odunc_kitap FOREIGN KEY (kitap_kodu) 
        REFERENCES kitaplar(kitap_kodu) ON DELETE CASCADE,
    CONSTRAINT fk_odunc_personel FOREIGN KEY (personel_no) 
        REFERENCES personel(personel_no) ON DELETE SET NULL
);




-- Rezervasyonlar tablosunu oluştur (Kitap rezervasyon kayıtları)
CREATE TABLE rezervasyonlar (
    rezervasyon_no SERIAL PRIMARY KEY,
    uye_no INTEGER NOT NULL,
    kitap_kodu INTEGER NOT NULL,
    rezervasyon_tarihi DATE DEFAULT CURRENT_DATE,
    gecerlilik_suresi DATE NOT NULL,
    durum VARCHAR(20) DEFAULT 'beklemede',
    oncelik_sirasi INTEGER DEFAULT 1,
    CONSTRAINT chk_rez_durum CHECK (durum IN ('beklemede', 'tamamlandı', 'iptal')),
    CONSTRAINT chk_gecerlilik CHECK (gecerlilik_suresi > rezervasyon_tarihi),
    CONSTRAINT fk_rezervasyon_uye FOREIGN KEY (uye_no) 
        REFERENCES uyeler(uye_no) ON DELETE CASCADE,
    CONSTRAINT fk_rezervasyon_kitap FOREIGN KEY (kitap_kodu) 
        REFERENCES kitaplar(kitap_kodu) ON DELETE CASCADE
);



-- Cezalar tablosunu oluştur (Gecikme, kayıp, hasar cezaları)
CREATE TABLE cezalar (
    ceza_no SERIAL PRIMARY KEY,
    uye_no INTEGER NOT NULL,
    islem_no INTEGER,
    ceza_tipi VARCHAR(20) NOT NULL,
    ceza_tutari DECIMAL(10, 2) NOT NULL,
    olusturma_tarihi DATE DEFAULT CURRENT_DATE,
    odeme_durumu VARCHAR(20) DEFAULT 'ödenmedi',
    odeme_tarihi DATE,
    CONSTRAINT chk_ceza_tipi CHECK (ceza_tipi IN ('gecikme', 'kayıp', 'hasar')),
    CONSTRAINT chk_odeme_durumu CHECK (odeme_durumu IN ('ödenmedi', 'ödendi')),
    CONSTRAINT chk_tutar CHECK (ceza_tutari > 0),
    CONSTRAINT fk_ceza_uye FOREIGN KEY (uye_no) 
        REFERENCES uyeler(uye_no) ON DELETE CASCADE,
    CONSTRAINT fk_ceza_islem FOREIGN KEY (islem_no) 
        REFERENCES odunc_islemleri(islem_no) ON DELETE SET NULL
);









-- Talep listesi tablosunu oluştur (Üyelerin kitap satın alma talepleri)
CREATE TABLE talep_listesi (
    talep_no SERIAL PRIMARY KEY,
    uye_no INTEGER NOT NULL,
    kitap_kodu INTEGER,  -- bos olabilir
    kitap_adi VARCHAR(200),
    yazar_adi VARCHAR(100),
    talep_tarihi DATE DEFAULT CURRENT_DATE,
    durum VARCHAR(20) DEFAULT 'beklemede',
    aciliyet VARCHAR(20) DEFAULT 'orta',
    CONSTRAINT chk_talep_durum CHECK (durum IN ('beklemede', 'sipariş verildi', 'reddedildi', 'tamamlandı')),
    CONSTRAINT chk_aciliyet CHECK (aciliyet IN ('düşük', 'orta', 'yüksek')),
    CONSTRAINT fk_talep_uye FOREIGN KEY (uye_no) 
        REFERENCES uyeler(uye_no) ON DELETE CASCADE,
    CONSTRAINT fk_talep_kitap FOREIGN KEY (kitap_kodu) 
        REFERENCES kitaplar(kitap_kodu) ON DELETE SET NULL
);



-- Yorumlar tablosunu oluştur (Üyelerin kitaplar hakkındaki yorum ve puanları)
CREATE TABLE yorumlar (
    yorum_id SERIAL PRIMARY KEY,
    uye_no INTEGER NOT NULL,
    kitap_kodu INTEGER NOT NULL,
    puan INTEGER NOT NULL,
    yorum_metni TEXT,
    yorum_tarihi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- deger verilmezse su anki tarih+ saat otomatik ayarlanır
    onaylandi_mi BOOLEAN DEFAULT FALSE,
    CONSTRAINT chk_puan CHECK (puan BETWEEN 1 AND 5),
    -- puan 1-5 arasında olabilir
    CONSTRAINT fk_yorum_uye FOREIGN KEY (uye_no) 
        REFERENCES uyeler(uye_no) ON DELETE CASCADE,
    CONSTRAINT fk_yorum_kitap FOREIGN KEY (kitap_kodu) 
        REFERENCES kitaplar(kitap_kodu) ON DELETE CASCADE
);



-- Kitap-Bağış ilişki tablosunu oluştur (Hangi kitap hangi bağıştan geldi)
CREATE TABLE kitap_bagislar (
    kitap_kodu INTEGER NOT NULL,
    bagis_no INTEGER NOT NULL,
    PRIMARY KEY (kitap_kodu, bagis_no),
    CONSTRAINT fk_kbagis_kitap FOREIGN KEY (kitap_kodu) 
        REFERENCES kitaplar(kitap_kodu) ON DELETE CASCADE,
    CONSTRAINT fk_kbagis_bagis FOREIGN KEY (bagis_no) 
        REFERENCES bagislar(bagis_no) ON DELETE CASCADE
);