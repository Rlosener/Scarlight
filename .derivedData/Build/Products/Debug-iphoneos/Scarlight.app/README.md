# Scarlight - iOS Uygulaması

Premium, dark-red temalı, yetişkinler için özel timer bazlı kart oyunu uygulaması.

## Özellikler

- ✅ Native iOS SwiftUI uygulaması
- ✅ 100% lokal çalışır (backend yok, internet yok)
- ✅ MVVM mimarisi
- ✅ Premium dark-red/wine UI tasarımı
- ✅ Timer bazlı oyun akışı
- ✅ Çark sistemi (Random Bag algoritması)
- ✅ Ceza sistemi
- ✅ Faz bazlı ilerleme
- ✅ Özel kart editörü
- ✅ JSON import/export
- ✅ Haptic feedback
- ✅ Tek elle kullanım için optimize

## Sistem Gereksinimleri

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Kurulum

### 1. Yeni Xcode Projesi Oluştur

1. Xcode'u aç
2. File → New → Project
3. iOS → App seç
4. Proje ayarları:
   - Product Name: `Scarlight`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Minimum Deployment: `iOS 17.0`

### 2. Dosyaları Projeye Ekle

Bu klasördeki tüm `.swift` dosyalarını Xcode projesine ekle:

```
Scarlight/
├── App/
│   └── ScarlightApp.swift (ContentView.swift yerine kullan)
├── Models/
│   ├── Player.swift
│   ├── GameCard.swift
│   ├── PenaltyCard.swift
│   ├── GameEnums.swift
│   ├── SurpriseTask.swift
│   ├── PhaseProgress.swift
│   └── WheelTurnState.swift
├── ViewModels/
│   ├── AppStateViewModel.swift
│   ├── PlayerSetupViewModel.swift
│   ├── GameEngineViewModel.swift
│   ├── CardEditorViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── SplashView.swift
│   ├── ConsentView.swift
│   ├── PlayerSetupView.swift
│   ├── GameView.swift
│   ├── WheelView.swift
│   ├── CardEditorView.swift
│   ├── PenaltyEditorView.swift
│   └── SettingsView.swift
├── Services/
│   ├── LocalJSONStore.swift
│   ├── CardLoader.swift
│   ├── GameEngine.swift
│   ├── PlaceholderRenderer.swift
│   ├── HapticManager.swift
│   └── ExportImportService.swift
└── Design/
    ├── AppColors.swift
    ├── AppTypography.swift
    └── AppComponents.swift
```

### 3. Xcode'da Dosyaları Organize Et

1. Xcode Navigator'da (sol panel) sağ tıkla
2. "New Group" ile klasörler oluştur: App, Models, ViewModels, Views, Services, Design
3. Her `.swift` dosyasını ilgili gruba sürükle

### 4. Info.plist Ayarları (Opsiyonel)

Eğer Dark Mode'u zorlamak isterseniz:
- Info.plist → `UIUserInterfaceStyle` → `Dark`

## Kullanım

### İlk Çalıştırma

1. Xcode'da Cmd+R ile uygulamayı çalıştır
2. Splash ekranı açılır
3. 18+ onay ekranı gelir
4. "Kabul Ediyorum" butonuna bas
5. Oyuncu ekleme ekranı açılır

### Oyuncu Ekleme

1. "Oyuncu Ekle" butonuna bas
2. İsim, cinsiyet ve rol seç
3. En az 2 oyuncu ekle
4. "Scarlight Başlat" butonuna bas

### Oyun Akışı

1. Kart ekrana gelir
2. "Başlat" butonuna basarak timer'ı başlat
3. Süre bitince "Tamamladım" veya "Pas" seç
4. Pas seçersen ceza kartı gelir
5. Her oyuncu fazda 3 başarılı tur tamamlamalı
6. Tüm fazlar tamamlanınca yeni döngü başlar

### Çark Fazı

1. Çark otomatik açılır
2. "Çevir" butonuna bas
3. Rastgele oyuncu seçilir
4. "Kartı Aç" ile devam et
5. Herkes 3/3 olana kadar çark devam eder

### Kart Editörü

1. Ayarlar → Kartları Düzenle
2. Yeni kart ekle veya mevcut kartları düzenle
3. Placeholder kullan: `{actor}`, `{target}`, `{duration}`, `{phase}`
4. Kaydet

### JSON Import/Export

1. Ayarlar → Kartları Dışa Aktar
2. JSON dosyası cihaza kaydedilir
3. Başka cihazda: Ayarlar → Kartları İçe Aktar

## Veri Yapısı

### Lokal Depolama

Tüm veriler Documents klasöründe JSON olarak saklanır:

- `players.json` - Oyuncu listesi
- `cards.json` - Oyun kartları
- `penalties.json` - Ceza kartları
- `playedHistory.json` - Oyun geçmişi (opsiyonel)

### UserDefaults

- `hasConsented` - 18+ onayı
- `isHapticEnabled` - Haptic ayarı
- `isSoundEnabled` - Ses ayarı

## Özelleştirme

### Renkleri Değiştirme

`Design/AppColors.swift` dosyasında hex kodlarını değiştir:

```swift
static let primaryRed = Color(hex: "#B11226")
static let ruby = Color(hex: "#E02B3F")
```

### Tipografi Değiştirme

`Design/AppTypography.swift` dosyasında font boyutlarını ayarla:

```swift
static let cardText = Font.system(size: 30, weight: .semibold)
```

### Varsayılan Kartları Değiştirme

`Services/CardLoader.swift` dosyasındaki `loadSeedCards()` fonksiyonunu düzenle.

## Sorun Giderme

### Derleme Hataları

- Tüm dosyaların Target Membership'i doğru mu?
- Minimum iOS version 17.0 olarak ayarlı mı?
- SwiftUI lifecycle seçilmiş mi?

### Runtime Hataları

- Simulator'de test et (iPhone 15 Pro önerilir)
- Console'da error loglarını kontrol et
- UserDefaults'u temizle: Settings → Reset All Content

### Haptic Çalışmıyor

- Gerçek cihazda test et (Simulator haptic'i desteklemez)
- Ayarlar → Haptic Feedback açık mı kontrol et

## Geliştirme Notları

### Eksik/Geliştirilecek Özellikler

1. **Zar Sistemi** - Dice phase henüz implementasyon bekliyor
2. **Sürpriz Görevler** - Tetikleyici cevap sistemi eklenebilir
3. **Ses Efektleri** - Timer, completion, wheel için sesler
4. **Animasyonlar** - Card transitions için matchedGeometryEffect
5. **Wheel Rendering** - Şu an basit circle, segment drawing eklenebilir
6. **Ceza Editörü** - Penalty editor şu an placeholder
7. **Progress Göstergesi** - Daha detaylı progress UI
8. **İstatistikler** - Oyun geçmişi analytics

### Kod İyileştirmeleri

- [ ] Combine kullanımı genişletilebilir
- [ ] Error handling daha kapsamlı olabilir
- [ ] Unit testler eklenebilir
- [ ] SwiftUI Preview'lar zenginleştirilebilir
- [ ] Accessibility (VoiceOver) desteği
- [ ] Localization (çok dil desteği)

## Lisans

Bu proje kişisel kullanım içindir. Ticari kullanım için izin gereklidir.

## Destek

Sorular için:
- GitHub Issues
- Email: [email@example.com]

---

**Uyarı:** Bu uygulama yalnızca 18 yaş üzeri kullanıcılar içindir. Tüm içerik karşılıklı rızaya dayanmalıdır.
