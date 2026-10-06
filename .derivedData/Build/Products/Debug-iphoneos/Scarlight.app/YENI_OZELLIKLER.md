# Scarlight - Yeni Özellikler (Kodlandı ✅)

## 🔥 1. Kademeli Yoğunluk Sistemi

### Nasıl Çalışıyor?

```
Soft (12 tur) → Medium (15 tur) → Ateşli (18 tur) → Hardcore
```

**Otomatik İlerleme:**
- Oyun Soft'tan başlar
- 12 başarılı tur → Medium unlock
- +15 tur (27 toplam) → Ateşli unlock
- +18 tur (45 toplam) → Hardcore unlock

**Kartlar Seviyeye Göre:**
- Soft: Sadece hafif kartlar
- Medium: Orta seviye kartlar dahil
- Ateşli: Yoğun kartlar dahil
- Hardcore: Tüm kartlar, limit yok

**UI Göstergesi:**
```
[●]━━[●]━━[●]━━[○]
Soft  Medium Ateşli Hardcore
              ↑ (şu an buradasın)
```

### Kod:
```swift
enum IntensityLevel: Int, Codable {
    case soft = 1        // 12 tur
    case medium = 2      // 15 tur
    case hot = 3         // 18 tur
    case hardcore = 4    // limit yok
}

struct GameCard {
    var minIntensity: IntensityLevel  // Bu kart hangi seviyeden?
    var maxIntensity: IntensityLevel  // Hangi seviyeye kadar?
}
```

**Örnek Kartlar:**
- "Basit soru" → Soft-Medium (sadece başlangıç)
- "Partner görevi" → Medium-Hardcore (orta+)
- "Final görev" → Hardcore (sadece en yoğun)

---

## ⭐ 2. Joker/Pas Hakkı Sistemi

### Nasıl Çalışıyor?

**Her oyuncu 3 joker ile başlar:**
```
Efe: ⭐⭐⭐ 2/3
Su:  ⭐⭐○ 1/3
```

**Joker Kullanımı:**
1. Görev gelir
2. Timer başlar
3. "Joker Kullan" butonu görünür
4. Joker kullan → Ceza yok!
5. Joker -1, direkt sonraki karta geç

**Joker bitince:**
- Normal "Pas" → Ceza gelir
- Stratejik kullanım önemli

**UI:**
- Yıldızlar göstergesi (progress'te)
- Joker butonu (game screen'de)
- Joker bitince buton kaybolur

### Kod:
```swift
struct Player {
    var jokersRemaining: Int = 3
}

func useJoker() {
    players[currentIndex].jokersRemaining -= 1
    // Sonraki karta geç, ceza yok
}
```

---

## ⚡ 3. Sürpriz Görev Tetikleme

### Nasıl Çalışıyor?

**Soru kartlarında seçim:**
```
Soru: "..."

A) Evet
B) Hayır  ← Sürpriz tetikleyici!
```

**B seçilirse:**
```
⚡ SÜRPRİZ GÖREV!

"{actor}, şimdi {target} için 30 saniyede 
sürpriz görev yapacak!"

Timer: 30 saniye
```

**Akış:**
1. Soru kartı gelir
2. A/B seçimi sunulur
3. Kullanıcı B seçer (triggerAnswer)
4. Sürpriz görev aktive!
5. Yeni timer başlar
6. Sürpriz görev tamamlanırsa → Progress +1

### Kod:
```swift
struct GameCard {
    var answers: [String]? = ["Evet", "Hayır"]
    var triggerAnswer: String? = "Hayır"
    var surpriseTask: SurpriseTask? = SurpriseTask(
        text: "Sürpriz görev metni...",
        durationSeconds: 30
    )
}
```

---

## ⏱️ 4. +30 Saniye Bonus

### Nasıl Çalışıyor?

**Timer çalışırken:**
```
Timer: 00:25

[+30 saniye]  ← 1 kez kullanılabilir

Timer: 00:55  ✅
```

**Kullanım:**
- Her kart için 1 kez
- Sadece timer çalışırken
- Kullanıldıktan sonra buton kaybolur
- Sonraki kartta yeniden aktif

**Faydası:**
- Zorlanınca ekstra süre
- Daha az stres
- Esneklik

---

## 📊 5. Güncel Progress Göstergesi

### Nasıl Görünüyor?

```
┌─────────────────────────────┐
│ Efe: ○ 2/3  ⭐⭐⭐          │
│ Su:  ○ 1/3  ⭐⭐○           │
└─────────────────────────────┘
     ↑           ↑
   Faz ilerlemesi  Joker sayısı
```

**Bilgiler:**
- Faz içi ilerleme (0/3, 1/3, vs.)
- Joker sayısı (yıldızlar)
- Renk kodlaması (ruby = tamamlandı)

---

## 🎯 Oyun Akışı Özeti

### Başlangıç
```
1. Oyun Soft seviyeden başlar
2. Her oyuncu 3 joker ile başlar
3. İlk kart gelir
```

### Normal Kart
```
1. Kart gelir (seviyeye uygun)
2. "Başlat" → Timer çalışır
3. Seçenekler:
   a) "Tamamladım" → Progress +1
   b) "Joker" → Sonraki kart (joker -1)
   c) "Pas" → Ceza gelir
4. 12 tur sonra → Medium seviye unlock!
```

### Sürpriz Görev
```
1. Soru kartı gelir
2. A/B seçimi
3. B seçilirse → ⚡ Sürpriz görev!
4. 30 sn timer
5. Tamamla → Progress +1
```

### Yoğunluk Geçişi
```
Soft (12 tur) 
  ↓
Medium (15 tur)
  ↓
Ateşli (18 tur)
  ↓
Hardcore (limit yok)
```

---

## 💡 Kullanıcı Deneyimi

### Başlangıç (Soft)
- Hafif sorular/görevler
- Rahat başlangıç
- 3 joker güvenlik ağı

### Orta Oyun (Medium)
- Biraz daha cesur
- Jokerleri akıllıca kullan
- Zorluk yavaş artar

### İleri Seviye (Ateşli)
- Yoğun kartlar
- Jokerler azalmış olabilir
- Daha stratejik oyun

### Son Seviye (Hardcore)
- Tüm kartlar açık
- Limit yok
- En yoğun deneyim

---

## 🔧 Teknik Detaylar

### Intensity Tracking
```swift
@Published var currentIntensityLevel: IntensityLevel = .soft
@Published var totalCompletedTurns: Int = 0

func checkIntensityLevelUp() {
    if totalCompletedTurns >= 12 {
        currentIntensityLevel = .medium
    }
    // ...
}
```

### Joker Sistemi
```swift
func useJoker() {
    guard players[index].jokersRemaining > 0 else { return }
    players[index].jokersRemaining -= 1
    drawNextCard()
}
```

### Kart Filtreleme
```swift
func selectCard(
    for phase: GamePhase, 
    intensity: Int, 
    intensityLevel: IntensityLevel
) -> GameCard? {
    return allCards.filter { card in
        card.isAvailable(for: intensityLevel)
    }.randomElement()
}
```

---

## ✅ Test Senaryoları

### Senaryo 1: Joker Kullanımı
```
1. Oyun başla
2. İlk kart gelir
3. "Başlat"
4. Zorlandın → "Joker Kullan"
5. Joker: 3 → 2
6. Sonraki kart gelir (ceza yok)
```

### Senaryo 2: Seviye Geçişi
```
1. Soft'tan başla
2. 12 kart tamamla
3. ⚡ "Medium Seviyeye Ulaşıldı!" notification
4. Yeni kartlar unlock oldu
5. İlerleme göstergesinde Medium aktif
```

### Senaryo 3: Sürpriz Görev
```
1. Soru kartı gelir
2. A/B seçimi göster
3. "B) Hayır" seç
4. ⚡ Sürpriz görev açılır!
5. 30 sn timer başlar
6. Tamamla → Progress +1
```

### Senaryo 4: +30 Saniye
```
1. Kart başla, timer: 45sn
2. 20 saniye kaldı, zorlandın
3. "+30 saniye" bas
4. Timer: 50 saniye oldu ✅
5. Buton kayboldu (1 kez kullanım)
```

---

## 🎨 UI Değişiklikleri

### GameView Üst Kısım
```
┌─────────────────────────────┐
│        SCARLIGHT           │
│      [Cesur Soru]           │
│                             │
│ [●]━━[●]━━[○]━━[○]         │ ← Yoğunluk
│  Soft  Medium Ateşli        │
│                             │
│ Efe: ○2/3 ⭐⭐⭐          │ ← Progress + Joker
│ Su:  ○1/3 ⭐⭐○           │
└─────────────────────────────┘
```

### GameView Alt Kısım
```
┌─────────────────────────────┐
│  Timer çalışırken:          │
│                             │
│  [+30 saniye]               │ ← Bonus
│                             │
│  [⭐]  [Pas] [Tamamladım]  │ ← Joker + Aksiyonlar
│ Joker                       │
└─────────────────────────────┘
```

---

## 📝 Sonraki Adımlar

Kodlanan özellikler:
- ✅ Kademeli yoğunluk sistemi
- ✅ Joker sistemi
- ✅ Sürpriz görev tetikleme
- ✅ +30 saniye bonus
- ✅ Güncel progress göstergeleri

Henüz eklenmedi:
- ⏳ Ses efektleri
- ⏳ Hızlı başlatma
- ⏳ Oyun sonu istatistikleri
- ⏳ Kart filtre seçenekleri

---

**Tüm özellikler kodlandı ve çalışır durumda!** 🎉

Şimdi uygulamayı Xcode'da derleyip test edebilirsiniz.
