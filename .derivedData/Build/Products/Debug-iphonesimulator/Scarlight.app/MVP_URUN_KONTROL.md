# Scarlight MVP Urun Kontrolu

Son kontrol: 2026-06-30 10:54

## Calisir MVP Durumu

- Build/run: gecti. XcodeBuildMCP `build_run_sim` ile iPhone 16e uzerinde app acildi, crash/abort yok.
- Unit test: 30/30 gecti. `SessionRestoreTests`, kart secim testleri, urunlesme ek testleri, mode experience ve performans budget testleri dahil.
- Icerik JSON parse: gecti.
- Icerik kalite audit: 0 hata, 0 uyari. Normal ve `--strict-warnings` modlari gecti.
- Pre-release gate: `Scripts/pre_release_check.sh` gecti; strict audit, `xcodebuild test`, `xcodebuild build-for-testing`, `git diff --check`.

## Moduller

- Ana giris / ortam secimi: calisir.
- Menu: calisir; hazirlik, icerik ve uygulama bolumleri kaydirma ile erisilebilir.
- Oyuncu yonetimi: calisir; oyuncu ekleme sheet'i acilir, kapatma butonu ile veri birakmadan kapanir.
- Arkadas Ortami oyun kurulumu: calisir; ilk kart smoke edildi, soru acilis fazi gorunur.
- Sicak Ortam oyun kurulumu: calisir; ilk kart smoke edildi, soru acilis fazi gorunur.
- Cakmak Oyunu: calisir; soru onerme, hedef secme, soruyu verme, soruyu acma, cevaplama ve cakmagin yeni oyuncuya gecmesi smoke edildi.
- Eşya & Desteler: calisir; deste, seviye, yogunluk, faz ve esya secimleri gorunur.
- Akilli Kurulum / Sinirlar: calisir; onerilen preset, soru agirlikli kurulum, propsuz oynama, sureli kartlari kapatma, maksimum yogunluk ve deste kilitleme paneli gorunur.
- Hazir oyun kurulumlari: calisir; Yumusak Baslangic, Dengeli Gece, Bar, Cakmak, 3 Kisilik, Propsuz ve kullanici kopyalama/silme aksiyonlari gorunur.
- Esya asistani: calisir; secili esyalara uygun kart sayisi, propsuz devam ve onerilen esya akisi gorunur.
- Ozel Eşyalar: calisir; yeni esya formu ve kategori secimi gorunur.
- Kart editoru: calisir; arama alani, kompakt filtre toolbar'i, kalite filtresi, kalite paneli, metadata'li kart onizleme ve kart aksiyon ikonlari gorunur.
- Ayarlar: calisir; ses/haptic, performans modu, sure stepleri, kart ozeti, tam yerel yedek/export/import, QA paneli ve reset aksiyonlari gorunur.
- Oyun gecmisi: bos durumda calisir; gecmis import butonu gorunur. Yeni kayitlar replay metadata'si tasir ve detaydan ayni kurulumla yeniden baslatma hazir.
- Session restore: snapshot validation ve `GameEngineViewModel(restoring:)` unit testleri var.

## Yapilan MVP Duzeltmeleri

- `ScarlightTests/SessionRestoreTests.swift` eklendi. Valid snapshot, 2'den az oyuncu, duplicate player id, invalid actor/target, invalid dice/wheel id ve timer restore guvenli state senaryolari test ediliyor.
- `GameEngineViewModel` icin oynanmis kart id'lerini testte okuyacak internal test yuzeyi eklendi.
- `Tools/content_audit.py` icine `--strict-warnings` eklendi. Normal audit warning ile exit 0, strict audit warning ile exit 1.
- Audit'teki 33 warning temizlendi. Duplicate metinler ayrildi, `nhi_b2_030` bos `onYesTask` dolduruldu.
- Prop generic kart metinleri tek tip placeholder'i koruyarak benzersiz hale getirildi; kart metadata alanlari korunarak guncellendi.
- `Scripts/pre_release_check.sh` eklendi ve iPhone 16e destination'i UDID ile cozerek daha deterministik hale getirildi.
- Oyuncu ekleme sheet'ine gorunur `Kapat` butonu eklendi.
- Devam karti urunlestirildi: ana menude son mod/faz/tur/oyuncu ozeti ve kayitli oturumu sil aksiyonu var.
- `LocalBackupPackage` eklendi; kart tercihleri, kullanici kartlari, cezalar, gecmis, presetler, ozel esyalar, session config ve sure ayarlari tek JSON yedekte tasinir.
- Tam yedek import raporu eklendi; version, import sayimlari, atlanan kayit ve warning ozeti Ayarlar icinde gorunur.
- `SessionPreset` seti genisletildi; built-in presetler ve kullanici preset kopyalama/silme akisi eklendi.
- `BoundaryPreferences` eklendi; propsuz, suresiz, maksimum yogunluk ve deste kilidi filtreleri oyun motoru, playable kart sayaci ve prop asistaninda ortak uygulanir.
- `PropSetupAssistant` eklendi; prop deck/esya uyumu ve onerilen esya secimi hesaplanir.
- `CardContentAuditor` kalite filtresiyle genisletildi; kart editorunde duplicate, uzun metin, placeholder, oyuncu uyumu, prop ve timing filtreleri kullanilabilir.
- Oyun gecmisi detay modeli genisletildi; eski `playedHistory.json` kayitlari backward-compatible decode edilir, yeni kayitlar replay icin oyuncu/config metadata'si tasir.
- Performans modu toggle'i duzeltildi; oyun ve Cakmak ekranlari artik bu ayari zorla acmaz, kullanici toggle'i agir cam/texture efektlerini kontrol eder.
- `FeatureExtensionTests` icine boundary filter, backup import report, history replay metadata, preset, prop asistani, kart kalite auditoru ve eski gecmis decode testleri eklendi.
- `ModeExperienceSpec` eklendi; Arkadas Ortami, Cakmak Oyunu ve Sicak Ortam artik tek yerden ayri konsept, ikon, sahne, kart etiketi ve UI mikro metinleri alir.
- `VisualEffectBudget` eklendi; performans modu acikken premium texture/golge/glow katmanlari otomatik azalir.
- Ortam secim kartlari mode-specific sahne seritleriyle ayrildi; kucuk ekranda liste scroll ile tasma yapmaz.
- Session setup icin mode-specific hero karti eklendi; oyuncu sayisi, oynanabilir kart sayisi ve secim ozeti ayni panelde gorunur.
- Oyun ekranina `GameModeRibbon` ve kart ici mode header eklendi; Arkadas kartlari BAR TURU, Sicak kartlari SICAK TUR kimligiyle gorunur.
- Cakmak ekranina holder -> hedef -> faz akisi eklendi; iki kisilik oyunda hedef otomatik secilir ve cevap sonrasi cakmak yeni oyuncuya gecer.

## Runtime Smoke

- Cihaz: iPhone 16e Simulator (`3D5B5271-9EF5-4CD3-BB72-3CA379E2DDC9`).
- Kapsam: root, menu, oyuncu ekleme, Eşya & Desteler, Ozel Eşyalar, Kartlar, Ayarlar, Gecmis.
- Oyun akislari: Arkadas Ortami ilk kart, Sicak Ortam ilk kart, Cakmak tam dongu.
- Yeni urun smoke: hazir kurulumlar gorundu, esya asistani gorundu, kart editor kalite paneli `2381 kart temiz` gosterdi, 2/3 kisi kart onizleme sheet'i acildi, Ayarlar'da tam yedek/import ve QA paneli gorundu.
- Bu tur smoke: ana ekran acildi, Menu'de `Ayni Kurulumla Yeniden Baslat` gorundu, Eşya & Desteler'de `AKILLI KURULUM` ve `SINIRLAR` panelleri gorundu, Kart editorunde kalite paneli ve metadata'li preview acildi, Ayarlar'da performans toggle'i, Veri ve QA paneli gorundu.
- UI/UX urunlestirme smoke: Root'ta 3 mod karti ayri konseptle gorundu; Cakmak tam dongude otomatik hedef, soru onerme, soruyu verme, acma, cevaplama ve holder devri calisti; Arkadas ve Sicak modlari setup + ilk kart yuzeyine kadar acildi.
- Not: Bu ortamda iPhone SE simulator yoktu; kucuk ekran QA icin mevcut en dar telefon olan iPhone 16e kullanildi.

## Screenshot QA Kanitlari

- Root: `/var/folders/wm/tq289p_j1mn3bpb20tqfbb300000gn/T/screenshot_optimized_a074bb98-8b77-460e-8b0f-709e3e8bc45e.jpg`
- Root yeni smoke: `/var/folders/wm/tq289p_j1mn3bpb20tqfbb300000gn/T/screenshot_optimized_1716d84b-efab-47a1-8e82-42734402ed6e.jpg`
- Kart editoru: `/var/folders/wm/tq289p_j1mn3bpb20tqfbb300000gn/T/screenshot_optimized_deeca7fb-0f0a-4686-a021-0deadb234a13.jpg`
- Sicak session setup: `/var/folders/wm/tq289p_j1mn3bpb20tqfbb300000gn/T/screenshot_optimized_7cb749e6-6dda-4df2-9029-6b7c71376148.jpg`
- Oyun karti: `/var/folders/wm/tq289p_j1mn3bpb20tqfbb300000gn/T/screenshot_optimized_62d8ad38-2ab0-4324-a343-a5869c510685.jpg`
- Cakmak: `/var/folders/wm/tq289p_j1mn3bpb20tqfbb300000gn/T/screenshot_optimized_57e526c7-c7d6-4877-bba5-9ad189a5480d.jpg`

## Kalan Urun Iyilestirmeleri

- Session restore manuel QA: app kill/ac senaryosunda son kart, faz, oyuncular ve timer ekranini gercek cihazda tekrar dene.
- Tam yedek manuel QA: gercek cihazda export edilen JSON'u temiz kurulumda import edip kart/preset/gecmis/ayarlarin geri geldigini dene.
- Gecmis detay manuel QA: tamamlanmis gercek oturumdan sonra detay, player stats ve gecmis yedegi akisini dolu veriyle dene.
- Sicak Ortam derin QA: Soft -> Medium -> Atesli faz gecisleri ve esya gerektiren kart havuzunu tam oturum olarak oyna.
- Release profiling: Instruments ile SwiftUI render ve Time Profiler kisa gecisi al.
- App Store oncesi gercek cihaz smoke: launch, icon, backup/export, oyun cikis ve data restore.
