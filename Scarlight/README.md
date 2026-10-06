# Scarlight

SwiftUI ve MVVM ile geliştirilmiş, iOS üzerinde tamamen yerel çalışan kart oyunu. Mevcut Xcode projesi `Scarlight.xcodeproj`; yeni bir proje oluşturmaya gerek yoktur.

## Çalıştırma

1. `Scarlight.xcodeproj` dosyasını Xcode ile açın.
2. `Scarlight` scheme ve yüklü bir iPhone simülatörü seçin.
3. **Cmd + R** ile çalıştırın.

Minimum hedef iOS 17.6. Bu sürüm Xcode 26.6 / iOS 26.5 simülatörü ile kontrol edildi. Gerçek cihaza yüklemek için Signing & Capabilities bölümünde kendi Apple geliştirme takımınızı seçin. Proje harici paket, API anahtarı veya backend gerektirmez.

## MVP kapsamı

- Üç oyun modu ve mevcut tasarım sistemi.
- Oyuncu ekleme, düzenleme, silme onayı ve en az iki aktif oyuncu kontrolü.
- Oturum kurulumu, deste/seviye/eşya/sınır filtreleri, uygun kart sayacı ve boş havuz kontrolü.
- Kart, çark, zar, zamanlayıcı, pas ve oyun geçmişi akışları.
- Kullanıcı kartı oluşturma ve düzenleme; arama, kalite filtreleri, favori ve toplu görünürlük işlemleri.
- Arka plana geçince güvenli duraklatma; kayıtlı oturuma devam etme.
- Kart/ceza JSON aktarımı ve sürümlü yerel yedekleme.

## Veri ve hata yönetimi

JSON dosyaları uygulamanın Documents dizininde tutulur. Dosya yazımları atomiktir. Toplu kayıtlar önce kodlanır; dosya yazımı başarısız olduğunda daha önce değiştirilen dosyalar geri alınır. Bu mekanizma çalışan süreçteki yazma hatalarını kapsar; birden fazla dosyanın işletim sistemi tarafından aynı anda atomik olarak değiştirilmesi anlamına gelmez.

Kullanıcı kartları pasifleştirildiğinde dosyadan silinmez. Editör bunları gizli filtresinde gösterir ve tekrar etkinleştirebilir. Kart listesinde aynı kimliğe sahip kullanıcı düzenlemesi, paket kartının yerine geçer; yinelenen liste kimliği üretilmez. İçe aktarılan yinelenen kimlikler ve geçersiz alanlar kayıt öncesinde reddedilir.

Yerel yedek sürümü **3**: kullanıcı kartları, kart tercihleri, cezalar, geçmiş, şablonlar, özel eşyalar, oturum kurulumu, süre ayarları, oyuncular, partner eşleştirmesi, düzenlenmiş deste dosyaları ve çekilmiş kart kimlikleri. Aktif oyun oturumu ayrıca `active_game_session.json` dosyasında saklanır. Cihaza özel ses, titreşim, ilk kullanım ve performans tercihleri bu yedeğin kapsamında değildir.

Sürüm 1–2 yedekleri okunabilir. Eski yedekte bulunmayan oyuncu/deste alanları mevcut cihazda korunur. İleri sürümler reddedilir. Tam yedek geri yüklemede önce içerik özeti ve değiştirme onayı gösterilir. JSON dosya sınırı 50 MB'tır.

## Performans

- Liste filtreleme ve seçim sırasında kart tercihleri bir kez okunur.
- Toplu gizleme/gösterme bir dosya grubu ve bir değişiklik bildirimi üretir.
- Görünürlük değişiminde metin kalite analizi yeniden çalıştırılmaz.
- Kurulum sayacı ve eşya analizi aynı yüklenmiş kart kümesini kullanır.
- Arama için 200 ms, kurulum sayacı için 250 ms debounce vardır.
- Zamanlayıcı monoton saate göre kalan süreyi hesaplar. Her saniye JSON yazmaz; durum değişimlerinde ve uygulama arka plana giderken kayıt alır.
- Performans modu ilk kurulumda açıktır; sonraki kullanıcı tercihi korunur.

## Tek komutla doğrulama

Proje kökünde:

```sh
bash Scripts/pre_release_check.sh
```

Kontrol sırası: katı içerik denetimi, birim/regresyon testleri, Release simülatör derlemesi ve whitespace kontrolü. Betik yüklü Xcode'u ve kullanılabilir iPhone simülatörünü otomatik seçer; sistemin global `xcode-select` ayarını değiştirmez.

İsteğe bağlı:

```sh
SCARLIGHT_SIMULATOR_NAME="iPhone 17e" \
SCARLIGHT_DERIVED_DATA=/tmp/scarlight-mvp-derived \
bash Scripts/pre_release_check.sh
```

`SCARLIGHT_DESTINATION` ile doğrudan bir xcodebuild destination verilebilir.

Testler `ScarlightTests` altında kart seçimi, oturum geri yükleme, veri doğrulama, yedek round-trip, kayıt hatasında geri alma, toplu işlemler ve zamanlayıcı davranışını kapsar. Güncel doğrulama kapsamı ve gerçek cihazda kalan kontroller `MVP_URUN_KONTROL.md` dosyasındadır.
