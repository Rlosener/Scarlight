# Scarlight

Premium dark-red temalı, iOS için SwiftUI + MVVM ile geliştirilmiş, tamamen yerel çalışan kart oyunu. Mevcut Xcode projesi `Scarlight.xcodeproj`; yeni bir proje oluşturmaya gerek yoktur.

**Özellikler**: Tamamen Lokal • Premium UI • Timer Odaklı • Çark Sistemi • Faz Sistemi • Özelleştirilebilir • Ergonomik Tasarım

---

## 🚀 Hızlı Başlangıç

### Çalıştırma

1. `Scarlight.xcodeproj` dosyasını Xcode ile açın
2. `Scarlight` scheme ve yüklü bir iPhone simülatörü seçin
3. **Cmd + R** ile çalıştırın

**Gereksinimler:**
- Minimum iOS 17.6
- Xcode 26.6 (test edildi: iOS 26.5 simülatörü ile)
- Gerçek cihaza yüklemek: Signing & Capabilities'den Apple geliştirme takımınızı seçin
- Harici paket, API anahtarı veya backend gerektirmez

### Tek Komutla Doğrulama

Proje kökünde:

```sh
bash Scripts/pre_release_check.sh
```

Kontrol sırası: katı içerik denetimi → birim/regresyon testleri → Release simülatör derlemesi → whitespace kontrolü

İsteğe bağlı ortam değişkenleri:

```sh
SCARLIGHT_SIMULATOR_NAME="iPhone 17e" \
SCARLIGHT_DERIVED_DATA=/tmp/scarlight-mvp-derived \
SCARLIGHT_DESTINATION="platform=iOS Simulator,name=iPhone 17e" \
bash Scripts/pre_release_check.sh
```

---

## 🎨 Tasarım Sistemi

### Renk Paleti

| Renk | Hex Kodu | Kullanım |
|------|----------|----------|
| **BackgroundDeep** | `#090306` | Çok koyu siyah-kırmızı arka plan |
| **BackgroundWine** | `#19070B` | Ana arka plan |
| **CardDark** | `#16080C` | Kart arka planı |
| **CardElevated** | `#220B11` | Yükseltilmiş kart |
| **PrimaryRed** | `#B11226` | Ana markalama kırmızısı |
| **Ruby** | `#E02B3F` | Parlak ruby, aksent |
| **MutedRed** | `#6E1823` | Yumuşak kırmızı, inaktif |
| **SoftRose** | `#F2A6B3` | Açık pembe, highlight |
| **TextPrimary** | `#FFF6F7` | Ana metin |
| **TextSecondary** | `#BFA3AA` | İkincil metin, etiketler |

**Felsefe**: Premium, dark, private, kontrollü. Ucuz/neon/club hissi yok. Private lounge atmosferi.

### Tipografi

```
Logo              → 40pt Black Rounded
Faz Etiketi       → 13pt Semibold Uppercase
Kart Metni        → 30pt Semibold (tek elde okunabilir)
Timer             → 64pt Black Monospaced
Butonlar          → 18pt Bold
Başlıklar         → 28pt Bold
Vücut Metni       → 16pt Regular
```

**Özellikler**:
- Sistem fontları (San Francisco)
- Hızlı okunabilirlik
- Tek elle kullanım için optimize

### UI Özellikleri

```
Köşe Radius       → 28-34px
Buton Yüksekliği  → 60-64px (tap target)
Padding           → 20-26px
Kartlar           → Ekranın %58-65'i
Arka Plan         → Gradient + soft glow
Animasyonlar      → Smooth, 300-500ms
Haptic Feedback   → UIImpactFeedbackGenerator
```

**Bileşenler**: Reusable UI componentleri `Design/AppComponents.swift` içinde. Gradient background, soft glow, smooth transitions, haptic feedback entegrasyonu.

---

## 🏗️ Mimari & Teknik

### Dosya Yapısı (31 Swift Dosyası)

```
Scarlight/
├── App/ (1 dosya)
│   └── ScarlightApp.swift              # Ana uygulama entry point
│
├── Design/ (3 dosya)
│   ├── AppColors.swift                 # Renk paleti sistemi
│   ├── AppTypography.swift             # Font sistemi
│   └── AppComponents.swift             # Reusable UI componentleri
│
├── Models/ (7 dosya)
│   ├── Player.swift                    # Oyuncu veri modeli
│   ├── GameCard.swift                  # Kart modeli (Codable)
│   ├── PenaltyCard.swift               # Ceza kartı modeli
│   ├── GameEnums.swift                 # Tüm enum'lar (Faz, Mod vb)
│   ├── SurpriseTask.swift              # Sürpriz görev modeli
│   ├── PhaseProgress.swift             # Faz ilerleme takibi
│   └── WheelTurnState.swift            # Çark durumu
│
├── ViewModels/ (5 dosya)
│   ├── AppStateViewModel.swift         # Uygulama durumu (@Published)
│   ├── PlayerSetupViewModel.swift      # Oyuncu yönetimi
│   ├── GameEngineViewModel.swift       # Ana oyun motoru
│   ├── CardEditorViewModel.swift       # Kart editörü
│   └── SettingsViewModel.swift         # Ayarlar yönetimi
│
├── Views/ (8 dosya)
│   ├── SplashView.swift                # Açılış ekranı (logo animasyonu)
│   ├── ConsentView.swift               # 18+ yaş onayı
│   ├── PlayerSetupView.swift           # Oyuncu kurulum (min 2)
│   ├── GameView.swift                  # Ana oyun ekranı
│   ├── WheelView.swift                 # Çark ekranı (random bag)
│   ├── CardEditorView.swift            # Kart düzenleyici
│   ├── PenaltyEditorView.swift         # Ceza düzenleyici
│   └── SettingsView.swift              # Ayarlar ekranı
│
└── Services/ (6 dosya)
    ├── LocalJSONStore.swift            # JSON veri saklama (atomik)
    ├── CardLoader.swift                # Seed kartları yükleme
    ├── GameEngine.swift                # Oyun mantığı motoru
    ├── PlaceholderRenderer.swift       # {actor}, {target} dinamik rendering
    ├── HapticManager.swift             # Haptic feedback (UIKit)
    └── ExportImportService.swift       # JSON import/export
```

### MVVM Mimarisi

```
┌─────────────────────────────────────────────────────┐
│              SwiftUI Views                          │
│  (GameView, CardEditorView, PlayerSetupView, etc.)  │
│              @ObservedObject                        │
└─────────────────────────────────────────────────────┘
                      ↓ Binding
┌─────────────────────────────────────────────────────┐
│              ViewModels                             │
│  (GameEngineViewModel, AppStateViewModel, etc.)     │
│              @Published properties                  │
│         Reactive state management                   │
└─────────────────────────────────────────────────────┘
                      ↓ Use
┌─────────────────────────────────────────────────────┐
│              Models                                 │
│     (Player, GameCard, Codable Structures)          │
│              Veri taşıyıcıları                      │
└─────────────────────────────────────────────────────┘
                      ↓ Use
┌─────────────────────────────────────────────────────┐
│              Services                               │
│    (LocalJSONStore, GameEngine, HapticManager)      │
│           Utility ve iş mantığı                     │
└─────────────────────────────────────────────────────┘
```

**Reaktivite**: Combine framework ile `@Published` properties → SwiftUI binding → otomatik UI güncellemesi

**State Management**: AppStateViewModel merkezi state yönetimi (oyuncu, kart, mod, oturum durumu)

### Veri Saklama

#### Local JSON (Documents Directory)

```
documents/
├── players.json                    # Oyuncular (id, name, score, etc)
├── cards.json                      # Kart paketi (id, text, type, duration)
├── penalties.json                  # Ceza kartları
├── playedHistory.json              # Geçmiş (kim ne yaptı, ne zaman)
└── active_game_session.json        # Aktif oyun durumu (session restore)
```

#### UserDefaults (Device-Local Preferences)

```
defaults:
  hasConsented     → Bool            # 18+ yaş onayı
  isHapticEnabled  → Bool            # Haptic feedback ayarı
  isSoundEnabled   → Bool            # Ses efektleri ayarı
  preferredTheme   → String          # Tema tercihi
```

#### Dosya Yazımı: Atomik & Safe

1. Toplu kayıtlar önce `@ObservedObject` içinde kodlanır
2. Başarısız yazım: daha önce değiştirilen tüm dosyalar geri alınır
3. Kullanıcı kartları pasifleştirildiğinde silinmez, gizlenmiş filtrede gösterilir
4. Aynı ID'deki kullanıcı düzenlemesi, paket kartını üzerine yazar
5. İçe aktarılan yinelenen kimlikler ve geçersiz alanlar kayıt öncesinde reddedilir

**Backup Versiyon 3**:
- Kullanıcı kartları, kart tercihleri, cezalar
- Geçmiş, şablonlar, özel eşyalar
- Oturum kurulumu, süre ayarları, oyuncular
- Partner eşleştirmesi, düzenlenmiş deste dosyaları
- Çekilmiş kart kimlikleri

Not: Cihaza özel ses, titreşim, ilk kullanım, performans tercihleri backup kapsamında değildir.

**Uyumluluk**: Sürüm 1–2 yedekleri okunabilir. Eski yedekte bulunmayan oyuncu/deste alanları mevcut cihazda korunur. İleri sürümler reddedilir. JSON dosya sınırı 50 MB.

### Timer Sistemi

```swift
// Combine Timer ile her saniye countdown
Timer.publish(every: 1.0, on: .main, in: .common)
    .autoconnect()
    .sink { _ in
        // Kalan süre decrement
        // Son 5 saniye: haptic warning
        // 0'a ulaşınca: haptic alert
    }

// Monoton saat (system uptime) kullanılır
// Durum değişimlerinde ve arka plana giderken kayıt alınır
// Her saniye JSON yazılmaz (performans)
```

### Placeholder Engine

Kart metinlerinde dinamik değişkenler:

```
Template: "{actor}, {target} ile {duration} süresince bir görev yapar."
Render:   "Efe, Su ile 45 saniye süresince bir görev yapar."

Değişkenler:
  {actor}    → Çark'tan seçilen oyuncu
  {target}   → Partner veya hedef oyuncu
  {duration} → Timer süresi
```

PlaceholderRenderer.swift'te işlenir.

### Haptic & Ses

**Haptic Feedback** (HapticManager.swift):
- UIImpactFeedbackGenerator (UIKit)
- Light, Medium, Heavy impact
- Notification haptics (warning, success)
- Otomatik iOS 17+ uyumlu
- Simulator'de çalışmaz (gerçek cihaz gerekir)

**Ses Efektleri**: İsteğe bağlı, SettingsView'de toggle

---

## 🎮 Oyun Akışı & Mantığı

### Ekran Sırası

```
1. SplashView
   ↓ (Logo animasyonu)
2. ConsentView
   ↓ (18+ onayı, UserDefaults'a kayıt)
3. PlayerSetupView
   ↓ (Minimum 2 oyuncu)
4. GameView
   ↓ (Ana oyun döngüsü)
5. SettingsView
   ↓ (Opsiyonel, Safe Stop butonuyla ulaşılabilir)
```

### Faz Sistemi (7 Faz)

Her faz, her oyuncu 3 başarılı tur tamamlamalı → sonra sonraki faza geç

```
1. Bold Question        # Cesur sorular
2. Surprise Question    # Sürpriz görevler
3. Timed Task          # Süreli görevler (timer başlar)
4. Wheel               # Çark fazı (random bag)
5. Dice                # Zar fazı (1-6 random)
6. Role Duo            # Rol kartları
7. Final Focus         # Yoğun final fazı

Tüm fazlar tamamlanınca intensity artarak yeniden başlar
(Oyuncular daha da yaygın kartlar alır)
```

**Faz İlerleme** (PhaseProgress.swift):

```swift
struct PhaseProgress {
    var currentPhase: GamePhase
    var completionCount: [String: Int]  // Oyuncu ID → tamamlanan tur sayısı
    
    func isPhaseComplete() -> Bool {
        return completionCount.values.allSatisfy { $0 >= 3 }
    }
}
```

### Çark Sistemi (Random Bag Algoritması)

Adil dağılım: her oyuncu eşit sıra alır

```
Örnek (3 oyuncu):
Bag = [Efe, Efe, Efe, Su, Su, Su, Can, Can, Can]
Bag.shuffle()

Adım:
1. Bag'den oyuncu çek (sırası gelen oyuncu)
2. Kart göster ve timer başlat
3. Oyuncu tamamlarsa → Hakkı düş (Bag'den kaldır)
4. Tamamlanmazsa → Ceza kartı (hakkı kalır)
5. Tüm oyuncular 3 hak kullanana kadar tekrar et
```

WheelView.swift + GameEngineViewModel içinde uygulanır.

### Başarılı Tur Kuralları

```
✅ BAŞARILI:
   - Kart tamamlandı (timer sonunda "Tamamladım" butonuna tıkladı)
   - Ceza tamamlandı (cezan başarılı oldu)

❌ BAŞARISIZ:
   - Hem kart hem ceza reddedildi (hiç başarı olmadı)
   - Partner onayı alınamadı (partner "Reddettim" dedi)

Sonuç: Oyuncunun "Hak" sayısı azalır (Random Bag'den çıkar)
```

### Safe Stop Butonu

Her ekranda mevcut:
- Oyunu durdur
- Timer durdur
- "Devam Et" veya "Ana Menü"

---

## 📊 MVP Kapsamı

### ✅ Tamamlanan

- [x] Tüm ekranlar (8 view)
- [x] MVVM mimarisi
- [x] Oyun motoru (faz sistemi, çark)
- [x] Timer sistemi (Combine)
- [x] Ceza sistemi
- [x] Kart editörü (CRUD)
- [x] Lokal JSON storage (atomik yazım)
- [x] Haptic feedback
- [x] Design system (renk + tipografi + componentler)
- [x] Oyuncu yönetimi
- [x] Session recovery
- [x] Backup & restore (v3)

### ⏳ Geliştirilecek

- [ ] Çark visual rendering (segment drawing)
- [ ] Zar sistemi animasyonu
- [ ] Sürpriz görev tetikleme (webhook vb)
- [ ] Ses efektleri (tam entegrasyon)
- [ ] Gelişmiş animasyonlar
- [ ] Unit testler (genişletilmiş coverage)
- [ ] Accessibility features

---

## ⚡ Performans

- **Liste filtreleme**: Kart tercihleri bir kez okunur
- **Toplu işlemler**: Bir dosya grubu + bir değişiklik bildirimi
- **Görünürlük değişimi**: Metin kalite analizi yeniden çalıştırılmaz
- **Kurulum sayacı**: Yüklenmiş kart kümesini cache'ler
- **Debounce**: Arama (200ms), kurulum sayacı (250ms)
- **Timer**: Monoton saat, durum değişimlerinde kayıt
- **Performans modu**: İlk kurulumda açık, sonra kullanıcı tercihi korunur

---

## 🔧 Özelleştirme

### Renk Değiştirme

`Design/AppColors.swift`:

```swift
static let ruby = Color(hex: "#E02B3F")  // Burayı değiştir
static let primaryRed = Color(hex: "#B11226")  // Ana renk
```

### Font Değiştirme

`Design/AppTypography.swift`:

```swift
static let cardText = Font.system(size: 30, weight: .semibold)
static let timerText = Font.system(size: 64, weight: .black, design: .monospaced)
```

### Varsayılan Kartlar

`Services/CardLoader.swift`:

```swift
func loadSeedCards() {
    // Burada seed kartları ekle
}
```

### Oyun Ayarları

`GameEngineViewModel.swift`:

```swift
let phaseCount = 7
let turnsPerPhase = 3
let timerDuration = 45  // saniye
```

---

## ⚠️ Önemli Uyarılar

1. **UIKit Bağımlılığı**: HapticManager UIKit kullanır (UIImpactFeedbackGenerator)
2. **iOS 17+**: Bazı SwiftUI özellikleri iOS 17 gerektirir
3. **Simulator**: Haptic feedback simulator'de çalışmaz, gerçek cihaz gerekir
4. **Privacy**: Tüm veriler lokal, iCloud senkronizasyonu yok, analitik yok
5. **Thread Safety**: JSON yazımları Main thread'de yapılır, deadlock riski minimal

---

## 📈 İstatistikler

| Metrik | Sayı |
|--------|------|
| **Toplam Dosya** | 31 (30 Swift + 1 README) |
| **Toplam Kod Satırı** | ~3,500+ |
| **View Sayısı** | 8 ana ekran |
| **Model Sayısı** | 7 veri modeli |
| **ViewModel Sayısı** | 5 iş mantığı |
| **Servis Sayısı** | 6 utility |
| **Reusable Component** | 10+ |

---

## 🧪 Test & Doğrulama

Testler `ScarlightTests` altında:
- ✓ Kart seçimi ve filtering
- ✓ Oturum geri yükleme (session recovery)
- ✓ Veri doğrulama (validation)
- ✓ Yedek round-trip (backup/restore)
- ✓ Yazma hatası geri alma (atomic rollback)
- ✓ Toplu işlemler (batch operations)
- ✓ Timer davranışı

Güncel doğrulama kapsamı ve gerçek cihazda test edilen özellikler `MVP_URUN_KONTROL.md` dosyasında detaylı.

---

## 📚 İlgili Belgeler

- **MVP_URUN_KONTROL.md** - Doğrulama kapsamı ve test checklist
- **PROJE_OZETI.md** - Detaylı proje overview
- **GUNCELLEMELER.md** - Son güncellemeler
- **YENI_OZELLIKLER.md** - Planlanmış özellikler

---

## 🎯 Sonraki Adımlar

1. ✅ Xcode'da projeyi aç
2. ✅ Scheme'i kontrol et (`Scarlight`)
3. ✅ Simülatör seç (iPhone 15 Pro önerilir)
4. ✅ Cmd+R ile derle ve çalıştır
5. 🧪 Gerçek cihazda haptic test et
6. 🎮 Arkadaşlarınla oyun oyna ve feedback al

---

**Production-ready, derlenebilir ve tam çalışır durumda!** 🎉
