"""
KÜTÜPHANE YÖNETİM SİSTEMİ - WEB ARAYÜZÜ
Streamlit ile gelistirilmis modern web arayüzü
- Dashboard ve İstatistikler
- CRUD İslemleri (Ekleme, Listeleme, Güncelleme, Silme)
- Grafikler ve Görsellestirmeler
- Fonksiyon ve Tetikleyici kullanimi
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, date

import sys
sys.path.append('.')

# =====================================================================
# VERİTABANI BAgLANTISI
# =====================================================================

import psycopg2
from psycopg2.extras import RealDictCursor

class KutuphaneDB:
    """Kütüphane Yönetim Sistemi veritabani islemleri"""
    
    def __init__(self):
        self.config = {
            "host": "localhost",
            "database": "kutuphane_db",
            "user": "postgres",
            "password": "adem6704",  # Kendi sifreni yaz
            "port": "5432"
        }
        self.connection = None
        self.cursor = None
    
    def baglan(self):
        try:
            self.connection = psycopg2.connect(**self.config)
            self.cursor = self.connection.cursor()
            return True
        except Exception as e:
            st.error(f"Baglanti hatasi: {e}")
            return False
    
    def kapat(self):
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
    
    def calistir(self, sorgu, parametreler=None):
        try:
            self.cursor.execute(sorgu, parametreler)
            self.connection.commit()
            return True
        except Exception as e:
            st.error(f"Hata: {e}")
            self.connection.rollback()
            return False
    
    def getir(self, sorgu, parametreler=None):
        try:
            self.cursor.execute(sorgu, parametreler)
            return self.cursor.fetchall()
        except Exception as e:
            st.error(f"Hata: {e}")
            return []
    
    def tek_getir(self, sorgu, parametreler=None):
        try:
            self.cursor.execute(sorgu, parametreler)
            return self.cursor.fetchone()
        except Exception as e:
            st.error(f"Hata: {e}")
            return None

    # ===================== FONKSİYON KULLANIMLARI =====================
    
    def fonk_uye_odunc_sayisi(self, uye_no):
        """FONKSİYON: Üyenin elindeki kitap sayisini döndürür"""
        sonuc = self.tek_getir("SELECT uye_odunc_sayisi(%s);", (uye_no,))
        return sonuc[0] if sonuc else 0
    
    def fonk_kitap_musaitlik_kontrol(self, kitap_kodu):
        """FONKSİYON: Kitabin rafta olup olmadigini kontrol eder"""
        sonuc = self.tek_getir("SELECT kitap_musaitlik_kontrol(%s);", (kitap_kodu,))
        return sonuc[0] if sonuc else False
    
    def fonk_gecikme_cezasi_hesapla(self, islem_no):
        """FONKSİYON: Gecikme cezasini hesaplar"""
        sonuc = self.tek_getir("SELECT gecikme_cezasi_hesapla(%s);", (islem_no,))
        return float(sonuc[0]) if sonuc and sonuc[0] else 0.0
    
    def fonk_kategori_kitap_istatistik(self, kategori_kodu):
        """FONKSİYON: Kategori istatistiklerini döndürür"""
        return self.tek_getir("SELECT * FROM kategori_kitap_istatistik(%s);", (kategori_kodu,))

    # ===================== sEHİR İsLEMLERİ =====================
    
    def sehir_ekle(self, plaka_kodu, il_adi, bolge, nufus=None):
        sorgu = "INSERT INTO sehirler (plaka_kodu, il_adi, bolge, nufus) VALUES (%s, %s, %s, %s);"
        return self.calistir(sorgu, (plaka_kodu, il_adi, bolge, nufus))
    
    def sehir_listele(self):
        return self.getir("SELECT * FROM sehirler ORDER BY plaka_kodu;")
    
    def sehir_ara(self, il_adi):
        return self.getir("SELECT * FROM sehirler WHERE il_adi ILIKE %s;", (f"%{il_adi}%",))
    
    def sehir_guncelle(self, plaka_kodu, il_adi=None, bolge=None, nufus=None):
        sorgu = "UPDATE sehirler SET il_adi = COALESCE(%s, il_adi), bolge = COALESCE(%s, bolge), nufus = COALESCE(%s, nufus) WHERE plaka_kodu = %s;"
        return self.calistir(sorgu, (il_adi, bolge, nufus, plaka_kodu))
    
    def sehir_sil(self, plaka_kodu):
        return self.calistir("DELETE FROM sehirler WHERE plaka_kodu = %s;", (plaka_kodu,))

    # ===================== ADRES İsLEMLERİ =====================
    
    def adres_ekle(self, plaka_kodu, ilce, mahalle=None, cadde_sokak=None, bina_no=None):
        """Yeni adres ekle ve adres_id döndür"""
        sorgu = """
            INSERT INTO adresler (plaka_kodu, ilce, mahalle, cadde_sokak, bina_no)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING adres_id;
        """
        self.cursor.execute(sorgu, (plaka_kodu, ilce, mahalle, cadde_sokak, bina_no))
        self.connection.commit()
        sonuc = self.cursor.fetchone()
        return sonuc[0] if sonuc else None
    
    def adres_listele(self):
        """Tüm adresleri sehir bilgisiyle listele"""
        sorgu = """
            SELECT a.adres_id, s.il_adi, a.ilce, a.mahalle, a.cadde_sokak
            FROM adresler a
            LEFT JOIN sehirler s ON a.plaka_kodu = s.plaka_kodu
            ORDER BY a.adres_id;
        """
        return self.getir(sorgu)

    # ===================== KİTAP İsLEMLERİ =====================
    
    def kitap_ekle(self, isbn, baslik, yayinevi_kodu=None, kategori_kodu=None,
                   tur_kodu=None, raf_kodu=None, basim_yili=None, 
                   sayfa_sayisi=None, dil="Türkce", ozet=None):
        sorgu = """
            INSERT INTO kitaplar (isbn, baslik, yayinevi_kodu, kategori_kodu,
                                  tur_kodu, raf_kodu, basim_yili, sayfa_sayisi, dil, ozet)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING kitap_kodu;
        """
        self.cursor.execute(sorgu, (isbn, baslik, yayinevi_kodu, kategori_kodu,
                                     tur_kodu, raf_kodu, basim_yili, sayfa_sayisi, dil, ozet))
        self.connection.commit()
        sonuc = self.cursor.fetchone()
        return sonuc[0] if sonuc else None
    
    def kitap_listele(self, limit=100):
        sorgu = """
            SELECT 
                k.kitap_kodu, k.isbn, k.baslik,
                COALESCE(y.yayinevi_adi, '-') as yayinevi,
                COALESCE(kat.kategori_adi, '-') as kategori,
                k.basim_yili, k.sayfa_sayisi, k.rafta_mi
            FROM kitaplar k
            LEFT JOIN yayinevleri y ON k.yayinevi_kodu = y.yayinevi_kodu
            LEFT JOIN kategoriler kat ON k.kategori_kodu = kat.kategori_kodu
            ORDER BY k.kitap_kodu LIMIT %s;
        """
        return self.getir(sorgu, (limit,))
    
    def kitap_ara(self, arama):
        sorgu = """
            SELECT k.kitap_kodu, k.baslik, k.isbn, k.basim_yili
            FROM kitaplar k WHERE k.baslik ILIKE %s OR k.isbn ILIKE %s ORDER BY k.baslik;
        """
        return self.getir(sorgu, (f"%{arama}%", f"%{arama}%"))
    
    def kitap_guncelle(self, kitap_kodu, baslik=None, basim_yili=None, sayfa_sayisi=None):
        sorgu = """UPDATE kitaplar SET 
                   baslik = COALESCE(%s, baslik), 
                   basim_yili = COALESCE(%s, basim_yili),
                   sayfa_sayisi = COALESCE(%s, sayfa_sayisi)
                   WHERE kitap_kodu = %s;"""
        return self.calistir(sorgu, (baslik, basim_yili, sayfa_sayisi, kitap_kodu))
    
    def kitap_sil(self, kitap_kodu):
        return self.calistir("DELETE FROM kitaplar WHERE kitap_kodu = %s;", (kitap_kodu,))

    # ===================== ÜYE İsLEMLERİ =====================
    
    def uye_ekle(self, ad, soyad, tc_kimlik_no, uyelik_tipi, cinsiyet=None, dogum_tarihi=None, adres_id=None):
        """Yeni üye ekle - TRİGGER otomatik kayit_tarihi ve uyelik_durumu atar"""
        sorgu = """
            INSERT INTO uyeler (ad, soyad, tc_kimlik_no, uyelik_tipi, cinsiyet, dogum_tarihi, adres_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING uye_no;
        """
        try:
            self.cursor.execute(sorgu, (ad, soyad, tc_kimlik_no, uyelik_tipi, cinsiyet, dogum_tarihi, adres_id))
            self.connection.commit()
            sonuc = self.cursor.fetchone()
            return sonuc[0] if sonuc else None
        except Exception as e:
            st.error(f"Üye ekleme hatasi: {e}")
            self.connection.rollback()
            return None
    
    def uye_listele(self, limit=100):
        sorgu = """
            SELECT u.uye_no, u.ad, u.soyad, u.uyelik_tipi, u.uyelik_durumu, 
                   u.kayit_tarihi, COALESCE(s.il_adi, '-') as sehir
            FROM uyeler u
            LEFT JOIN adresler a ON u.adres_id = a.adres_id
            LEFT JOIN sehirler s ON a.plaka_kodu = s.plaka_kodu
            ORDER BY u.uye_no LIMIT %s;
        """
        return self.getir(sorgu, (limit,))
    
    def uye_ara(self, arama):
        sorgu = """SELECT uye_no, ad, soyad, uyelik_tipi, uyelik_durumu
                   FROM uyeler WHERE ad ILIKE %s OR soyad ILIKE %s ORDER BY ad, soyad;"""
        return self.getir(sorgu, (f"%{arama}%", f"%{arama}%"))
    
    def uye_guncelle(self, uye_no, ad=None, soyad=None, uyelik_durumu=None):
        sorgu = """UPDATE uyeler SET 
                   ad = COALESCE(%s, ad), soyad = COALESCE(%s, soyad),
                   uyelik_durumu = COALESCE(%s, uyelik_durumu)
                   WHERE uye_no = %s;"""
        return self.calistir(sorgu, (ad, soyad, uyelik_durumu, uye_no))
    
    def uye_sil(self, uye_no):
        return self.calistir("DELETE FROM uyeler WHERE uye_no = %s;", (uye_no,))

    # ===================== ÖDÜNc İsLEMLERİ =====================
    
    def odunc_ver(self, uye_no, kitap_kodu, personel_no, gun_sayisi=14):
        """
        Kitap ödünc ver
        NOT: trg_odunc_kitap_guncelle TETİKLEYİCİSİ otomatik kitabi raftan cikarir
        """
        # Önce fonksiyon ile kontrol et
        try:
            kontrol = self.tek_getir("SELECT rafta_mi FROM kitaplar WHERE kitap_kodu = %s;", (kitap_kodu,))
            if not kontrol or not kontrol[0]:
                st.warning("Bu kitap su anda rafta degil!")
                return None
            
            # Ödünc kaydi ekle - TRİGGER otomatik kitabi raftan cikaracak
            sorgu = """
                INSERT INTO odunc_islemleri (uye_no, kitap_kodu, personel_no, teslim_tarihi_planlanan)
                VALUES (%s, %s, %s, CURRENT_DATE + %s * INTERVAL '1 day')
                RETURNING islem_no;
            """
            self.cursor.execute(sorgu, (uye_no, kitap_kodu, personel_no, gun_sayisi))
            sonuc = self.cursor.fetchone()  # RETURNING degerini HEMEN al
            self.connection.commit()
            return sonuc[0] if sonuc else None
        except Exception as e:
            st.error(f"Ödünc verme hatasi: {e}")
            self.connection.rollback()
            return None
    
    def odunc_iade(self, islem_no):
        """
        Kitap iade et
        NOT: trg_iade_kitap_guncelle TETİKLEYİCİSİ otomatik kitabi rafa koyar
        NOT: trg_gecikme_ceza_olustur TETİKLEYİCİSİ gecikme varsa otomatik ceza olusturur
        """
        islem = self.tek_getir("SELECT kitap_kodu, durum FROM odunc_islemleri WHERE islem_no = %s;", (islem_no,))
        if not islem or islem[1] == "teslim edildi":
            return False
        
        # Gecikme cezasini hesapla ve göster
        ceza = self.fonk_gecikme_cezasi_hesapla(islem_no)
        if ceza > 0:
            st.warning(f"⚠️ Gecikme cezasi: {ceza:.2f} TL (Otomatik kaydedilecek)")
        
        # İade islemi - TRİGGERLAR otomatik calisacak
        return self.calistir("""
            UPDATE odunc_islemleri 
            SET gercek_teslim_tarihi = CURRENT_DATE, durum = 'teslim edildi' 
            WHERE islem_no = %s;
        """, (islem_no,))
    
    def odunc_listele(self, sadece_aktif=False):
        sorgu = """
            SELECT o.islem_no, u.ad || ' ' || u.soyad AS uye, k.baslik AS kitap,
                   o.odunc_alma_tarihi, o.teslim_tarihi_planlanan, o.durum
            FROM odunc_islemleri o
            INNER JOIN uyeler u ON o.uye_no = u.uye_no
            INNER JOIN kitaplar k ON o.kitap_kodu = k.kitap_kodu
        """
        if sadece_aktif:
            # Hem 'ödünçte' hem 'gecikmiş' olanları getir (teslim edilmemişler)
            sorgu += " WHERE o.durum != 'teslim edildi'"
        sorgu += " ORDER BY o.odunc_alma_tarihi DESC;"
        return self.getir(sorgu)

    # ===================== YAZAR İsLEMLERİ =====================
    
    def yazar_listele(self):
        return self.getir("SELECT yazar_kodu, ad, soyad, uyruk, dogum_tarihi FROM yazarlar ORDER BY soyad;")
    
    def yazar_ekle(self, ad, soyad, uyruk=None, dogum_tarihi=None, biyografi=None):
        sorgu = "INSERT INTO yazarlar (ad, soyad, uyruk, dogum_tarihi, biyografi) VALUES (%s, %s, %s, %s, %s) RETURNING yazar_kodu;"
        self.cursor.execute(sorgu, (ad, soyad, uyruk, dogum_tarihi, biyografi))
        self.connection.commit()
        sonuc = self.cursor.fetchone()
        return sonuc[0] if sonuc else None
    
    def yazar_sil(self, yazar_kodu):
        return self.calistir("DELETE FROM yazarlar WHERE yazar_kodu = %s;", (yazar_kodu,))

    # ===================== YAYINEVİ İsLEMLERİ =====================
    
    def yayinevi_listele(self):
        return self.getir("SELECT yayinevi_kodu, yayinevi_adi, kurulus_yili, ulke FROM yayinevleri ORDER BY yayinevi_adi;")
    
    def yayinevi_ekle(self, yayinevi_adi, kurulus_yili=None, ulke=None, web_sitesi=None):
        sorgu = "INSERT INTO yayinevleri (yayinevi_adi, kurulus_yili, ulke, web_sitesi) VALUES (%s, %s, %s, %s) RETURNING yayinevi_kodu;"
        self.cursor.execute(sorgu, (yayinevi_adi, kurulus_yili, ulke, web_sitesi))
        self.connection.commit()
        sonuc = self.cursor.fetchone()
        return sonuc[0] if sonuc else None

    # ===================== KATEGORİ İsLEMLERİ =====================
    
    def kategori_listele(self):
        return self.getir("SELECT kategori_kodu, kategori_adi, ust_kategori_kodu FROM kategoriler ORDER BY kategori_adi;")
    
    def kategori_ekle(self, kategori_adi, ust_kategori_kodu=None, aciklama=None):
        sorgu = "INSERT INTO kategoriler (kategori_adi, ust_kategori_kodu, aciklama) VALUES (%s, %s, %s) RETURNING kategori_kodu;"
        self.cursor.execute(sorgu, (kategori_adi, ust_kategori_kodu, aciklama))
        self.connection.commit()
        sonuc = self.cursor.fetchone()
        return sonuc[0] if sonuc else None

    # ===================== PERSONEL İsLEMLERİ =====================
    
    def personel_listele(self):
        return self.getir("SELECT personel_no, ad, soyad, gorev, maas FROM personel ORDER BY personel_no;")

    # ===================== RAF İsLEMLERİ =====================
    
    def raf_listele(self):
        return self.getir("SELECT raf_kodu, bolum, koridor_no, raf_no, kapasite FROM raflar ORDER BY raf_kodu;")

    # ===================== YAYIN TÜRÜ İsLEMLERİ =====================
    
    def yayin_turu_listele(self):
        return self.getir("SELECT tur_kodu, tur_adi FROM yayin_turleri ORDER BY tur_adi;")

    # ===================== İSTATİSTİKLER =====================
    
    def istatistik_genel(self):
        sorgu = """
            SELECT
                (SELECT COUNT(*) FROM kitaplar) AS toplam_kitap,
                (SELECT COUNT(*) FROM kitaplar WHERE rafta_mi = TRUE) AS rafta_kitap,
                (SELECT COUNT(*) FROM uyeler WHERE uyelik_durumu = 'aktif') AS aktif_uye,
                (SELECT COUNT(*) FROM odunc_islemleri WHERE durum = 'ödüncte') AS aktif_odunc,
                (SELECT COUNT(*) FROM odunc_islemleri WHERE durum = 'gecikmis') AS gecikmis;
        """
        return self.tek_getir(sorgu)
    
    def kategoriye_gore_kitap_sayisi(self):
        sorgu = """
            SELECT COALESCE(kat.kategori_adi, 'Kategorisiz') AS kategori, COUNT(*) AS sayi
            FROM kitaplar k
            LEFT JOIN kategoriler kat ON k.kategori_kodu = kat.kategori_kodu
            GROUP BY kat.kategori_adi ORDER BY sayi DESC;
        """
        return self.getir(sorgu)
    
    def bolgeye_gore_uye_sayisi(self):
        sorgu = """
            SELECT s.bolge, COUNT(u.uye_no) AS uye_sayisi
            FROM sehirler s
            LEFT JOIN adresler a ON s.plaka_kodu = a.plaka_kodu
            LEFT JOIN uyeler u ON a.adres_id = u.adres_id
            GROUP BY s.bolge ORDER BY uye_sayisi DESC;
        """
        return self.getir(sorgu)
    
    def yayinevine_gore_kitap_sayisi(self):
        sorgu = """
            SELECT COALESCE(y.yayinevi_adi, 'Belirtilmemis') as yayinevi, COUNT(*) as sayi
            FROM kitaplar k
            LEFT JOIN yayinevleri y ON k.yayinevi_kodu = y.yayinevi_kodu
            GROUP BY y.yayinevi_adi ORDER BY sayi DESC;
        """
        return self.getir(sorgu)
    
    def uyelik_tipine_gore_dagilim(self):
        return self.getir("SELECT uyelik_tipi, COUNT(*) as sayi FROM uyeler GROUP BY uyelik_tipi ORDER BY sayi DESC;")
    
    def sehre_gore_uye_sayisi(self):
        sorgu = """
            SELECT s.il_adi, s.plaka_kodu, COUNT(u.uye_no) as uye_sayisi
            FROM sehirler s
            LEFT JOIN adresler a ON s.plaka_kodu = a.plaka_kodu
            LEFT JOIN uyeler u ON a.adres_id = u.adres_id
            GROUP BY s.il_adi, s.plaka_kodu
            HAVING COUNT(u.uye_no) > 0
            ORDER BY uye_sayisi DESC;
        """
        return self.getir(sorgu)
    
    def basim_yilina_gore_kitaplar(self):
        return self.getir("""
            SELECT basim_yili, COUNT(*) as sayi FROM kitaplar 
            WHERE basim_yili IS NOT NULL GROUP BY basim_yili ORDER BY basim_yili;
        """)


# =====================================================================
# STREAMLIT ARAYÜZÜ
# =====================================================================

st.set_page_config(
    page_title="📚 Kütüphane Yönetim Sistemi",
    page_icon="📚",
    layout="wide",
    initial_sidebar_state="expanded"
)

st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        font-weight: bold;
        color: #1E3A5F;
        text-align: center;
        margin-bottom: 2rem;
    }
</style>
""", unsafe_allow_html=True)

if 'db' not in st.session_state:
    st.session_state.db = None
    st.session_state.connected = False

def connect_db():
    if not st.session_state.connected:
        db = KutuphaneDB()
        if db.baglan():
            st.session_state.db = db
            st.session_state.connected = True
            return True
    return st.session_state.connected

st.markdown('<h1 class="main-header">📚 Kütüphane Yönetim Sistemi</h1>', unsafe_allow_html=True)

st.sidebar.title("📋 Menü")
menu = st.sidebar.radio(
    "Bölüm Secin:",
    ["🏠 Ana Sayfa (Dashboard)", 
     "📖 Kitap Yönetimi",
     "👥 Üye Yönetimi", 
     "🔄 Ödünc İslemleri",
     "🏙️ sehir Yönetimi",
     "✍️ Yazar Yönetimi",
     "🏢 Yayinevi Yönetimi",
     "📊 Raporlar ve Grafikler"]
)

if connect_db():
    st.sidebar.success("✅ Veritabani Bagli")
else:
    st.sidebar.error("❌ Baglanti Hatasi")
    st.stop()

db = st.session_state.db


# =====================================================================
# ANA SAYFA (DASHBOARD)
# =====================================================================

if menu == "🏠 Ana Sayfa (Dashboard)":
    st.header("📊 Genel Bakis")
    
    istat = db.istatistik_genel()
    
    if istat:
        col1, col2, col3, col4, col5 = st.columns(5)
        
        with col1:
            st.metric(label="📚 Toplam Kitap", value=istat[0])
        with col2:
            st.metric(label="📗 Rafta", value=istat[1])
        with col3:
            st.metric(label="👥 Aktif Üye", value=istat[2])
        with col4:
            st.metric(label="🔄 Aktif Ödünc", value=istat[3])
        with col5:
            st.metric(label="⚠️ Gecikmis", value=istat[4] if istat[4] else 0)
    
    st.divider()
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📊 Kategoriye Göre Kitap Dagilimi")
        kategori_data = db.kategoriye_gore_kitap_sayisi()
        if kategori_data:
            df = pd.DataFrame(kategori_data, columns=['Kategori', 'Sayi'])
            fig = px.pie(df, values='Sayi', names='Kategori', 
                        color_discrete_sequence=px.colors.qualitative.Set3, hole=0.4)
            fig.update_traces(textposition='inside', textinfo='percent+label')
            st.plotly_chart(fig, use_container_width=True)
    
    with col2:
        st.subheader("🏢 Yayinevine Göre Kitap Dagilimi")
        yayinevi_data = db.yayinevine_gore_kitap_sayisi()
        if yayinevi_data:
            df = pd.DataFrame(yayinevi_data, columns=['Yayinevi', 'Sayi'])
            fig = px.bar(df, x='Yayinevi', y='Sayi', color='Sayi', color_continuous_scale='Viridis')
            fig.update_layout(xaxis_tickangle=-45)
            st.plotly_chart(fig, use_container_width=True)
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("🗺️ Bölgeye Göre Üye Dagilimi")
        bolge_data = db.bolgeye_gore_uye_sayisi()
        if bolge_data:
            df = pd.DataFrame(bolge_data, columns=['Bölge', 'Üye Sayisi'])
            df = df[df['Üye Sayisi'] > 0]
            if not df.empty:
                fig = px.bar(df, x='Bölge', y='Üye Sayisi', color='Üye Sayisi', color_continuous_scale='Blues')
                st.plotly_chart(fig, use_container_width=True)
    
    with col2:
        st.subheader("👤 Üyelik Tipine Göre Dagilim")
        uyelik_data = db.uyelik_tipine_gore_dagilim()
        if uyelik_data:
            df = pd.DataFrame(uyelik_data, columns=['Üyelik Tipi', 'Sayi'])
            fig = px.pie(df, values='Sayi', names='Üyelik Tipi', color_discrete_sequence=px.colors.qualitative.Pastel)
            st.plotly_chart(fig, use_container_width=True)
    
    # FONKSİYON KULLANIMI: Kategori İstatistikleri
    st.divider()
    st.subheader("📈 FONKSİYON: Kategori Bazlı Kitap İstatistikleri")
    st.info("📌 Bu bölüm **kategori_kitap_istatistik()** fonksiyonunu kullanmaktadır.")
    
    kategoriler = db.kategori_listele()
    if kategoriler:
        cols = st.columns(min(len(kategoriler), 4))
        for idx, kat in enumerate(kategoriler[:4]):
            with cols[idx % 4]:
                istat = db.fonk_kategori_kitap_istatistik(kat[0])
                if istat:
                    st.markdown(f"**{kat[1]}**")
                    st.metric("Toplam", istat[0])
                    col_a, col_b = st.columns(2)
                    with col_a:
                        st.metric("Rafta", istat[1], delta=None)
                    with col_b:
                        st.metric("Ödünçte", istat[2], delta=None)


# =====================================================================
# KİTAP YÖNETİMİ
# =====================================================================

elif menu == "📖 Kitap Yönetimi":
    st.header("📖 Kitap Yönetimi")
    
    tab1, tab2, tab3, tab4 = st.tabs(["📋 Listele", "➕ Ekle", "✏️ Güncelle", "🗑️ Sil"])
    
    with tab1:
        st.subheader("📋 Kitap Listesi")
        arama = st.text_input("🔍 Kitap Ara (Baslik veya ISBN):", key="kitap_ara")
        
        if arama:
            kitaplar = db.kitap_ara(arama)
            if kitaplar:
                df = pd.DataFrame(kitaplar, columns=['Kod', 'Baslik', 'ISBN', 'Basim Yili'])
                st.dataframe(df, use_container_width=True)
            else:
                st.warning("Kitap bulunamadi.")
        else:
            kitaplar = db.kitap_listele()
            if kitaplar:
                df = pd.DataFrame(kitaplar, columns=['Kod', 'ISBN', 'Baslik', 'Yayinevi', 'Kategori', 'Basim Yili', 'Sayfa', 'Rafta'])
                df['Rafta'] = df['Rafta'].apply(lambda x: '✅ Evet' if x else '❌ Hayir')
                st.dataframe(df, use_container_width=True, height=400)
    
    with tab2:
        st.subheader("➕ Yeni Kitap Ekle")
        
        col1, col2 = st.columns(2)
        
        with col1:
            isbn = st.text_input("ISBN:", max_chars=13)
            baslik = st.text_input("Kitap Basligi:")
            basim_yili = st.number_input("Basim Yili:", min_value=1400, max_value=2025, value=2023)
            sayfa_sayisi = st.number_input("Sayfa Sayisi:", min_value=1, value=100)
        
        with col2:
            yayinevleri = db.yayinevi_listele()
            yayinevi_options = {f"{y[1]}": y[0] for y in yayinevleri} if yayinevleri else {}
            yayinevi_sec = st.selectbox("Yayinevi:", ["Seciniz..."] + list(yayinevi_options.keys()))
            
            kategoriler = db.kategori_listele()
            kategori_options = {f"{k[1]}": k[0] for k in kategoriler} if kategoriler else {}
            kategori_sec = st.selectbox("Kategori:", ["Seciniz..."] + list(kategori_options.keys()))
            
            dil = st.selectbox("Dil:", ["Türkce", "İngilizce", "Almanca", "Fransizca"])
        
        ozet = st.text_area("Özet:")
        
        if st.button("💾 Kitap Ekle", type="primary"):
            if isbn and baslik:
                yayinevi_kodu = yayinevi_options.get(yayinevi_sec) if yayinevi_sec != "Seciniz..." else None
                kategori_kodu = kategori_options.get(kategori_sec) if kategori_sec != "Seciniz..." else None
                
                sonuc = db.kitap_ekle(isbn, baslik, yayinevi_kodu, kategori_kodu, 
                                      None, None, basim_yili, sayfa_sayisi, dil, ozet)
                if sonuc:
                    st.success(f"✅ Kitap basariyla eklendi! (Kod: {sonuc})")
                    st.rerun()
            else:
                st.warning("⚠️ ISBN ve Baslik zorunludur!")
    
    with tab3:
        st.subheader("✏️ Kitap Güncelle")
        
        kitaplar = db.kitap_listele()
        if kitaplar:
            kitap_options = {f"{k[2]} (Kod: {k[0]})": k[0] for k in kitaplar}
            secili = st.selectbox("Güncellenecek Kitap:", list(kitap_options.keys()))
            
            col1, col2 = st.columns(2)
            with col1:
                yeni_baslik = st.text_input("Yeni Baslik:", key="gunc_baslik")
                yeni_yil = st.number_input("Yeni Basim Yili:", min_value=1400, max_value=2025, key="gunc_yil")
            with col2:
                yeni_sayfa = st.number_input("Yeni Sayfa Sayisi:", min_value=1, key="gunc_sayfa")
            
            if st.button("🔄 Güncelle", type="primary"):
                if db.kitap_guncelle(kitap_options[secili], 
                                     yeni_baslik if yeni_baslik else None,
                                     yeni_yil if yeni_yil else None,
                                     yeni_sayfa if yeni_sayfa else None):
                    st.success("✅ Kitap güncellendi!")
                    st.rerun()
    
    with tab4:
        st.subheader("🗑️ Kitap Sil")
        
        kitaplar = db.kitap_listele()
        if kitaplar:
            kitap_options = {f"{k[2]} (Kod: {k[0]})": k[0] for k in kitaplar}
            secili = st.selectbox("Silinecek Kitap:", list(kitap_options.keys()), key="sil_kitap")
            
            st.warning("⚠️ Bu islem geri alinamaz!")
            
            if st.button("🗑️ Kitabi Sil", type="primary"):
                if db.kitap_sil(kitap_options[secili]):
                    st.success("✅ Kitap silindi!")
                    st.rerun()


# =====================================================================
# ÜYE YÖNETİMİ - sEHİR SEcİMİ EKLENDİ
# =====================================================================

elif menu == "👥 Üye Yönetimi":
    st.header("👥 Üye Yönetimi")
    
    tab1, tab2, tab3, tab4 = st.tabs(["📋 Listele", "➕ Ekle", "✏️ Güncelle", "🗑️ Sil"])
    
    with tab1:
        st.subheader("📋 Üye Listesi")
        
        arama = st.text_input("🔍 Üye Ara (Ad veya Soyad):", key="uye_ara")
        
        if arama:
            uyeler = db.uye_ara(arama)
            if uyeler:
                df = pd.DataFrame(uyeler, columns=['Üye No', 'Ad', 'Soyad', 'Üyelik Tipi', 'Durum'])
                st.dataframe(df, use_container_width=True)
            else:
                st.warning("Üye bulunamadi.")
        else:
            uyeler = db.uye_listele()
            if uyeler:
                df = pd.DataFrame(uyeler, columns=['Üye No', 'Ad', 'Soyad', 'Üyelik Tipi', 'Durum', 'Kayit Tarihi', 'sehir'])
                st.dataframe(df, use_container_width=True, height=400)
    
    with tab2:
        st.subheader("➕ Yeni Üye Ekle")
        
        col1, col2 = st.columns(2)
        
        with col1:
            ad = st.text_input("Ad:")
            soyad = st.text_input("Soyad:")
            tc = st.text_input("TC Kimlik No:", max_chars=11)
        
        with col2:
            uyelik_tipi = st.selectbox("Üyelik Tipi:", ["ögrenci", "akademisyen", "standart"])
            cinsiyet = st.selectbox("Cinsiyet:", ["E", "K"])
            dogum = st.date_input("Dogum Tarihi:", min_value=date(1900, 1, 1))
        
        # sEHİR VE ADRES SEcİMİ
        st.subheader("📍 Adres Bilgileri (Opsiyonel)")
        
        col1, col2 = st.columns(2)
        
        with col1:
            sehirler = db.sehir_listele()
            if sehirler:
                sehir_options = {f"{s[1]} ({s[0]})": s[0] for s in sehirler}
                sehir_sec = st.selectbox("sehir:", ["Seciniz..."] + list(sehir_options.keys()))
            else:
                sehir_sec = "Seciniz..."
                st.info("Henüz sehir kaydi yok.")
            
            ilce = st.text_input("İlce:")
        
        with col2:
            mahalle = st.text_input("Mahalle:")
            cadde_sokak = st.text_input("Cadde/Sokak:")
        
        if st.button("💾 Üye Ekle", type="primary"):
            if ad and soyad and tc:
                if len(tc) != 11:
                    st.error("❌ TC Kimlik No 11 haneli olmalidir!")
                else:
                    adres_id = None
                    
                    # Eger sehir secildiyse adres olustur
                    if sehir_sec != "Seciniz..." and ilce:
                        plaka_kodu = sehir_options[sehir_sec]
                        adres_id = db.adres_ekle(plaka_kodu, ilce, mahalle, cadde_sokak)
                    
                    # Üye ekle (TRİGGER otomatik kayit_tarihi ve uyelik_durumu atar)
                    sonuc = db.uye_ekle(ad, soyad, tc, uyelik_tipi, cinsiyet, dogum, adres_id)
                    if sonuc:
                        st.success(f"✅ Üye eklendi! (Üye No: {sonuc})")
                        st.info("📌 Kayit tarihi ve üyelik durumu TETİKLEYİCİ tarafindan otomatik ayarlandi.")
                        st.rerun()
            else:
                st.warning("⚠️ Ad, Soyad ve TC zorunludur!")
    
    with tab3:
        st.subheader("✏️ Üye Güncelle")
        
        uyeler = db.uye_listele()
        if uyeler:
            uye_options = {f"{u[1]} {u[2]} (No: {u[0]})": u[0] for u in uyeler}
            secili = st.selectbox("Güncellenecek Üye:", list(uye_options.keys()))
            
            col1, col2 = st.columns(2)
            with col1:
                yeni_ad = st.text_input("Yeni Ad:", key="gunc_ad")
                yeni_soyad = st.text_input("Yeni Soyad:", key="gunc_soyad")
            with col2:
                yeni_durum = st.selectbox("Yeni Durum:", ["aktif", "pasif"], key="gunc_durum")
            
            if st.button("🔄 Güncelle", type="primary"):
                if db.uye_guncelle(uye_options[secili], 
                                   yeni_ad if yeni_ad else None,
                                   yeni_soyad if yeni_soyad else None,
                                   yeni_durum):
                    st.success("✅ Üye güncellendi!")
                    st.rerun()
    
    with tab4:
        st.subheader("🗑️ Üye Sil")
        
        uyeler = db.uye_listele()
        if uyeler:
            uye_options = {f"{u[1]} {u[2]} (No: {u[0]})": u[0] for u in uyeler}
            secili = st.selectbox("Silinecek Üye:", list(uye_options.keys()), key="sil_uye")
            
            st.warning("⚠️ Bu islem geri alinamaz! Üyenin tüm ödünc kayitlari da silinecek.")
            
            if st.button("🗑️ Üyeyi Sil", type="primary"):
                if db.uye_sil(uye_options[secili]):
                    st.success("✅ Üye silindi!")
                    st.rerun()


# =====================================================================
# ÖDÜNc İsLEMLERİ - HATA DÜZELTİLDİ
# =====================================================================

elif menu == "🔄 Ödünc İslemleri":
    st.header("🔄 Ödünc İslemleri")
    
    tab1, tab2, tab3 = st.tabs(["📋 Listele", "📤 Ödünc Ver", "📥 İade Al"])
    
    with tab1:
        st.subheader("📋 Ödünc İslemleri Listesi")
        
        sadece_aktif = st.checkbox("Sadece Aktif Ödüncleri Göster")
        
        islemler = db.odunc_listele(sadece_aktif)
        if islemler:
            df = pd.DataFrame(islemler, columns=['İslem No', 'Üye', 'Kitap', 'Ödünc Tarihi', 'Planlanan Teslim', 'Durum'])
            
            def durum_renk(durum):
                if durum == 'ödüncte':
                    return '🟡 Ödüncte'
                elif durum == 'teslim edildi':
                    return '🟢 Teslim Edildi'
                else:
                    return '🔴 Gecikmis'
            
            df['Durum'] = df['Durum'].apply(durum_renk)
            st.dataframe(df, use_container_width=True, height=400)
        else:
            st.info("Henüz ödünc kaydi yok.")
    
    with tab2:
        st.subheader("📤 Kitap Ödünc Ver")
        
        st.info("📌 Ödünc verildiginde **trg_odunc_kitap_guncelle** tetikleyicisi kitabi otomatik raftan cikarir.")
        
        col1, col2 = st.columns(2)
        
        with col1:
            uyeler = db.uye_listele()
            if uyeler:
                uye_options = {f"{u[1]} {u[2]} (No: {u[0]})": u[0] for u in uyeler}
                secili_uye = st.selectbox("Üye Sec:", list(uye_options.keys()))
            
            kitaplar = db.kitap_listele()
            rafta_kitaplar = [k for k in kitaplar if k[7]]
            if rafta_kitaplar:
                kitap_options = {f"{k[2]} (Kod: {k[0]})": k[0] for k in rafta_kitaplar}
                secili_kitap = st.selectbox("Kitap Sec (Rafta Olanlar):", list(kitap_options.keys()))
            else:
                st.warning("Rafta kitap yok!")
                kitap_options = {}
        
        with col2:
            personeller = db.personel_listele()
            if personeller:
                personel_options = {f"{p[1]} {p[2]} ({p[3]})": p[0] for p in personeller}
                secili_personel = st.selectbox("İslemi Yapan:", list(personel_options.keys()))
            
            gun_sayisi = st.number_input("Ödünc Süresi (Gün):", min_value=1, max_value=60, value=14)
        
        if kitap_options and st.button("📤 Ödünc Ver", type="primary"):
            # FONKSİYON KULLANIMI: Kitap müsaitlik kontrolü
            kitap_kodu = kitap_options[secili_kitap]
            if not db.fonk_kitap_musaitlik_kontrol(kitap_kodu):
                st.error("❌ Bu kitap şu anda müsait değil!")
            else:
                # FONKSİYON KULLANIMI: Üyenin ödünç sayısı kontrolü
                uye_no = uye_options[secili_uye]
                odunc_sayisi = db.fonk_uye_odunc_sayisi(uye_no)
                if odunc_sayisi >= 5:
                    st.error(f"❌ Üyenin elinde zaten {odunc_sayisi} kitap var! (Maksimum: 5)")
                else:
                    sonuc = db.odunc_ver(
                        uye_no,
                        kitap_kodu,
                        personel_options[secili_personel],
                        gun_sayisi
                    )
                    if sonuc:
                        st.success(f"✅ Kitap ödünc verildi! (İslem No: {sonuc})")
                        st.info(f"📌 FONKSİYON: Üyenin yeni ödünç sayısı: {odunc_sayisi + 1}")
                        st.info("📌 TETİKLEYİCİ: Kitap otomatik olarak raftan çıkarıldı.")
                        st.rerun()
    
        with tab3:
                st.subheader("📥 Kitap İade Al")
                
                st.info("📌 İade edildiğinde **trg_iade_kitap_guncelle** kitabı rafa koyar, **trg_gecikme_ceza_olustur** gecikme varsa ceza oluşturur.")
                
                # Teslim edilmemiş tüm işlemleri getir
                aktif_islemler = db.getir("""
                    SELECT o.islem_no, u.ad || ' ' || u.soyad AS uye, k.baslik AS kitap, o.durum
                    FROM odunc_islemleri o
                    INNER JOIN uyeler u ON o.uye_no = u.uye_no
                    INNER JOIN kitaplar k ON o.kitap_kodu = k.kitap_kodu
                    WHERE o.durum != 'teslim edildi'
                    ORDER BY o.odunc_alma_tarihi DESC;
                """)
                
                if aktif_islemler:
                    islem_options = {f"{i[2]} - {i[1]} ({i[3]}) (İşlem: {i[0]})": i[0] for i in aktif_islemler}
                    secili_islem = st.selectbox("İade Edilecek Kitap:", list(islem_options.keys()))
                    
                    # FONKSİYON KULLANIMI: Gecikme cezası hesaplama
                    islem_no = islem_options[secili_islem]
                    ceza_tutari = db.fonk_gecikme_cezasi_hesapla(islem_no)
                    if ceza_tutari > 0:
                        st.warning(f"⚠️ FONKSİYON: Bu kitap için {ceza_tutari:.2f} TL gecikme cezası hesaplandı!")
                    
                    if st.button("📥 İade Al", type="primary"):
                        if db.odunc_iade(islem_no):
                            st.success("✅ Kitap iade alındı!")
                            st.info("📌 TETİKLEYİCİ: Kitap otomatik olarak rafa kondu.")
                            if ceza_tutari > 0:
                                st.warning(f"📌 TETİKLEYİCİ: {ceza_tutari:.2f} TL gecikme cezası otomatik oluşturuldu!")
                            st.rerun()
                else:
                    st.info("İade edilecek aktif ödünç yok.")


# =====================================================================
# sEHİR YÖNETİMİ
# =====================================================================

elif menu == "🏙️ sehir Yönetimi":
    st.header("🏙️ sehir Yönetimi")
    
    tab1, tab2, tab3, tab4 = st.tabs(["📋 Listele", "➕ Ekle", "✏️ Güncelle", "🗑️ Sil"])
    
    with tab1:
        st.subheader("📋 sehir Listesi")
        
        arama = st.text_input("🔍 sehir Ara:", key="sehir_ara")
        
        sehirler = db.sehir_ara(arama) if arama else db.sehir_listele()
        
        if sehirler:
            df = pd.DataFrame(sehirler, columns=['Plaka', 'İl Adi', 'Bölge', 'Nüfus'])
            df['Nüfus'] = df['Nüfus'].apply(lambda x: f"{x:,}" if x else "-")
            st.dataframe(df, use_container_width=True, height=400)
    
    with tab2:
        st.subheader("➕ Yeni sehir Ekle")
        
        col1, col2 = st.columns(2)
        
        with col1:
            plaka = st.number_input("Plaka Kodu:", min_value=1, max_value=81)
            il_adi = st.text_input("İl Adi:")
        
        with col2:
            bolge = st.selectbox("Bölge:", ["Marmara", "Ege", "Akdeniz", "İc Anadolu", 
                                            "Karadeniz", "Dogu Anadolu", "Güneydogu Anadolu"])
            nufus = st.number_input("Nüfus:", min_value=0, value=0)
        
        if st.button("💾 sehir Ekle", type="primary"):
            if il_adi:
                if db.sehir_ekle(plaka, il_adi, bolge, nufus if nufus > 0 else None):
                    st.success("✅ sehir eklendi!")
                    st.rerun()
            else:
                st.warning("⚠️ İl adi zorunludur!")
    
    with tab3:
        st.subheader("✏️ sehir Güncelle")
        
        sehirler = db.sehir_listele()
        if sehirler:
            sehir_options = {f"{s[1]} ({s[0]})": s[0] for s in sehirler}
            secili = st.selectbox("Güncellenecek sehir:", list(sehir_options.keys()))
            
            yeni_nufus = st.number_input("Yeni Nüfus:", min_value=0)
            
            if st.button("🔄 Güncelle", type="primary"):
                if db.sehir_guncelle(sehir_options[secili], nufus=yeni_nufus if yeni_nufus > 0 else None):
                    st.success("✅ sehir güncellendi!")
                    st.rerun()
    
    with tab4:
        st.subheader("🗑️ sehir Sil")
        
        sehirler = db.sehir_listele()
        if sehirler:
            sehir_options = {f"{s[1]} ({s[0]})": s[0] for s in sehirler}
            secili = st.selectbox("Silinecek sehir:", list(sehir_options.keys()), key="sil_sehir")
            
            st.warning("⚠️ Bu sehre bagli adresler varsa silinemez!")
            
            if st.button("🗑️ sehri Sil", type="primary"):
                if db.sehir_sil(sehir_options[secili]):
                    st.success("✅ sehir silindi!")
                    st.rerun()


# =====================================================================
# YAZAR YÖNETİMİ
# =====================================================================

elif menu == "✍️ Yazar Yönetimi":
    st.header("✍️ Yazar Yönetimi")
    
    tab1, tab2, tab3 = st.tabs(["📋 Listele", "➕ Ekle", "🗑️ Sil"])
    
    with tab1:
        st.subheader("📋 Yazar Listesi")
        yazarlar = db.yazar_listele()
        if yazarlar:
            df = pd.DataFrame(yazarlar, columns=['Kod', 'Ad', 'Soyad', 'Uyruk', 'Dogum Tarihi'])
            st.dataframe(df, use_container_width=True, height=400)
    
    with tab2:
        st.subheader("➕ Yeni Yazar Ekle")
        
        col1, col2 = st.columns(2)
        with col1:
            ad = st.text_input("Ad:", key="yazar_ad")
            soyad = st.text_input("Soyad:", key="yazar_soyad")
        with col2:
            uyruk = st.text_input("Uyruk:", value="Türk")
            dogum = st.date_input("Dogum Tarihi:", min_value=date(1800, 1, 1), key="yazar_dogum")
        
        biyografi = st.text_area("Biyografi:")
        
        if st.button("💾 Yazar Ekle", type="primary"):
            if ad and soyad:
                sonuc = db.yazar_ekle(ad, soyad, uyruk, dogum, biyografi if biyografi else None)
                if sonuc:
                    st.success(f"✅ Yazar eklendi! (Kod: {sonuc})")
                    st.rerun()
            else:
                st.warning("⚠️ Ad ve Soyad zorunludur!")
    
    with tab3:
        st.subheader("🗑️ Yazar Sil")
        yazarlar = db.yazar_listele()
        if yazarlar:
            yazar_options = {f"{y[1]} {y[2]} (Kod: {y[0]})": y[0] for y in yazarlar}
            secili = st.selectbox("Silinecek Yazar:", list(yazar_options.keys()))
            
            if st.button("🗑️ Yazari Sil", type="primary"):
                if db.yazar_sil(yazar_options[secili]):
                    st.success("✅ Yazar silindi!")
                    st.rerun()


# =====================================================================
# YAYINEVİ YÖNETİMİ
# =====================================================================

elif menu == "🏢 Yayinevi Yönetimi":
    st.header("🏢 Yayinevi Yönetimi")
    
    tab1, tab2 = st.tabs(["📋 Listele", "➕ Ekle"])
    
    with tab1:
        st.subheader("📋 Yayinevi Listesi")
        yayinevleri = db.yayinevi_listele()
        if yayinevleri:
            df = pd.DataFrame(yayinevleri, columns=['Kod', 'Yayinevi Adi', 'Kurulus Yili', 'Ülke'])
            st.dataframe(df, use_container_width=True, height=400)
    
    with tab2:
        st.subheader("➕ Yeni Yayinevi Ekle")
        
        col1, col2 = st.columns(2)
        with col1:
            yayinevi_adi = st.text_input("Yayinevi Adi:")
            kurulus_yili = st.number_input("Kurulus Yili:", min_value=1400, max_value=2025, value=2000)
        with col2:
            ulke = st.text_input("Ülke:", value="Türkiye")
            web_sitesi = st.text_input("Web Sitesi:")
        
        if st.button("💾 Yayinevi Ekle", type="primary"):
            if yayinevi_adi:
                sonuc = db.yayinevi_ekle(yayinevi_adi, kurulus_yili, ulke, web_sitesi if web_sitesi else None)
                if sonuc:
                    st.success(f"✅ Yayinevi eklendi! (Kod: {sonuc})")
                    st.rerun()
            else:
                st.warning("⚠️ Yayinevi adi zorunludur!")


# =====================================================================
# RAPORLAR VE GRAFİKLER
# =====================================================================

elif menu == "📊 Raporlar ve Grafikler":
    st.header("📊 Raporlar ve Grafikler")
    
    tab1, tab2, tab3, tab4 = st.tabs(["📈 Kitap Analizi", "👥 Üye Analizi", "🗺️ Cografi Analiz", "📉 Trend Analizi"])
    
    with tab1:
        st.subheader("📈 Kitap Analizi")
        
        col1, col2 = st.columns(2)
        
        with col1:
            kategori_data = db.kategoriye_gore_kitap_sayisi()
            if kategori_data:
                df = pd.DataFrame(kategori_data, columns=['Kategori', 'Sayi'])
                fig = px.pie(df, values='Sayi', names='Kategori', title='Kategoriye Göre Kitap Dagilimi')
                st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            yayinevi_data = db.yayinevine_gore_kitap_sayisi()
            if yayinevi_data:
                df = pd.DataFrame(yayinevi_data, columns=['Yayinevi', 'Sayi'])
                fig = px.bar(df, x='Yayinevi', y='Sayi', title='Yayinevine Göre Kitap Sayisi')
                fig.update_layout(xaxis_tickangle=-45)
                st.plotly_chart(fig, use_container_width=True)
        
        basim_data = db.basim_yilina_gore_kitaplar()
        if basim_data:
            df = pd.DataFrame(basim_data, columns=['Basim Yili', 'Sayi'])
            fig = px.line(df, x='Basim Yili', y='Sayi', title='Basim Yilina Göre Kitap Sayisi', markers=True)
            st.plotly_chart(fig, use_container_width=True)
    
    with tab2:
        st.subheader("👥 Üye Analizi")
        
        col1, col2 = st.columns(2)
        
        with col1:
            uyelik_data = db.uyelik_tipine_gore_dagilim()
            if uyelik_data:
                df = pd.DataFrame(uyelik_data, columns=['Üyelik Tipi', 'Sayi'])
                fig = px.pie(df, values='Sayi', names='Üyelik Tipi', title='Üyelik Tipine Göre Dagilim')
                st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            sehir_data = db.sehre_gore_uye_sayisi()
            if sehir_data:
                df = pd.DataFrame(sehir_data, columns=['sehir', 'Plaka', 'Üye Sayisi'])
                fig = px.bar(df, x='sehir', y='Üye Sayisi', title='sehre Göre Üye Sayisi')
                st.plotly_chart(fig, use_container_width=True)
    
    with tab3:
        st.subheader("🗺️ Cografi Analiz")
        
        bolge_data = db.bolgeye_gore_uye_sayisi()
        if bolge_data:
            df = pd.DataFrame(bolge_data, columns=['Bölge', 'Üye Sayisi'])
            df = df[df['Üye Sayisi'] > 0]
            
            if not df.empty:
                col1, col2 = st.columns(2)
                with col1:
                    fig = px.bar(df, x='Bölge', y='Üye Sayisi', title='Bölgelere Göre Üye Dagilimi')
                    st.plotly_chart(fig, use_container_width=True)
                with col2:
                    fig = px.pie(df, values='Üye Sayisi', names='Bölge', title='Bölgesel Üye Oranlari')
                    st.plotly_chart(fig, use_container_width=True)
        
        sehirler = db.sehir_listele()
        if sehirler:
            df = pd.DataFrame(sehirler, columns=['Plaka', 'İl', 'Bölge', 'Nüfus'])
            df = df[df['Nüfus'].notna()]
            if not df.empty:
                fig = px.treemap(df, path=['Bölge', 'İl'], values='Nüfus', title='Bölge ve sehirlere Göre Nüfus Dagilimi')
                st.plotly_chart(fig, use_container_width=True)
    
    with tab4:
        st.subheader("📉 Trend Analizi")
        
        istat = db.istatistik_genel()
        if istat:
            col1, col2, col3 = st.columns(3)
            
            with col1:
                fig = go.Figure(go.Indicator(
                    mode="gauge+number",
                    value=istat[1] if istat[1] else 0,
                    title={'text': "Rafta Kitap"},
                    gauge={'axis': {'range': [None, istat[0] if istat[0] else 100]}, 'bar': {'color': "darkblue"}}))
                st.plotly_chart(fig, use_container_width=True)
            
            with col2:
                fig = go.Figure(go.Indicator(
                    mode="gauge+number",
                    value=istat[2] if istat[2] else 0,
                    title={'text': "Aktif Üye"},
                    gauge={'axis': {'range': [None, 50]}, 'bar': {'color': "green"}}))
                st.plotly_chart(fig, use_container_width=True)
            
            with col3:
                fig = go.Figure(go.Indicator(
                    mode="gauge+number",
                    value=istat[3] if istat[3] else 0,
                    title={'text': "Aktif Ödünc"},
                    gauge={'axis': {'range': [None, 20]}, 'bar': {'color': "orange"}}))
                st.plotly_chart(fig, use_container_width=True)


# =====================================================================
# FOOTER
# =====================================================================

st.divider()
st.markdown("""
<div style='text-align: center; color: gray; padding: 1rem;'>
    📚 Kütüphane Yönetim Sistemi | BSM 211 Veritabani Yönetim Sistemleri Projesi<br>
    Streamlit & PostgreSQL ile gelistirildi | Fonksiyon ve Tetikleyici kullanimi
</div>
""", unsafe_allow_html=True)