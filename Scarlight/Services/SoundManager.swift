import AVFoundation

/// Oyun ses efektleri — bundle içindeki `Resources/Sounds/` dosyalarını çalar.
enum GameSound: String, CaseIterable {
    case cardReveal
    case clickPop
    case diceRoll
    case wheelSpin
    case countdown
    case success
    case error

    var resourceName: String {
        switch self {
        case .cardReveal: return "card_reveal"
        case .clickPop: return "click_pop"
        case .diceRoll: return "dice_roll"
        case .wheelSpin: return "wheel_spin"
        case .countdown: return "countdown"
        case .success: return "success"
        case .error: return "error"
        }
    }

    var fileExtension: String {
        switch self {
        case .cardReveal, .diceRoll, .wheelSpin: return "mp3"
        case .clickPop, .countdown, .success, .error: return "wav"
        }
    }

    /// 0…1 arası önerilen ses seviyesi
    var defaultVolume: Float {
        switch self {
        case .cardReveal: return 0.55
        case .clickPop: return 0.42
        case .diceRoll: return 0.7
        case .wheelSpin: return 0.65
        case .countdown: return 0.5
        case .success: return 0.75
        case .error: return 0.7
        }
    }
}

final class SoundManager {
    static let shared = SoundManager()

    private var players: [GameSound: AVAudioPlayer] = [:]
    private var isEnabled = true

    private let enabledKey = "isSoundEnabled"

    private init() {
        if UserDefaults.standard.object(forKey: enabledKey) == nil {
            isEnabled = true
        } else {
            isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        }
        configureAudioSession()
        preloadSounds()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            stopAll()
        }
    }

    func play(_ sound: GameSound, volume: Float? = nil) {
        guard isEnabled else { return }

        guard let player = players[sound] else { return }
        player.volume = volume ?? sound.defaultVolume
        player.currentTime = 0
        player.play()
    }

    /// Çark dönüşü gibi uzun animasyonlar için döngülü çalma.
    func playLooping(_ sound: GameSound, volume: Float? = nil) {
        guard isEnabled else { return }
        guard let player = players[sound] else { return }
        player.numberOfLoops = -1
        player.volume = volume ?? sound.defaultVolume
        player.currentTime = 0
        player.play()
    }

    func stop(_ sound: GameSound) {
        players[sound]?.stop()
        players[sound]?.currentTime = 0
        players[sound]?.numberOfLoops = 0
    }

    func stopAll() {
        GameSound.allCases.forEach { stop($0) }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func preloadSounds() {
        for sound in GameSound.allCases {
            guard let url = soundURL(for: sound) else { continue }
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[sound] = player
            }
        }
    }

    private func soundURL(for sound: GameSound) -> URL? {
        for subdirectory in ["Sounds", "Resources/Sounds", nil] {
            if let subdirectory,
               let url = Bundle.main.url(
                   forResource: sound.resourceName,
                   withExtension: sound.fileExtension,
                   subdirectory: subdirectory
               ) {
                return url
            }
            if subdirectory == nil,
               let url = Bundle.main.url(
                   forResource: sound.resourceName,
                   withExtension: sound.fileExtension
               ) {
                return url
            }
        }
        return nil
    }
}

/// Haptic + ses birlikte — oyun akışı için tek giriş noktası.
enum FeedbackManager {
    static func cardReveal() {
        HapticManager.shared.light()
        SoundManager.shared.play(.cardReveal)
    }

    static func diceRollStart() {
        HapticManager.shared.light()
        SoundManager.shared.play(.diceRoll)
    }

    static func wheelSpinStart() {
        HapticManager.shared.light()
        SoundManager.shared.playLooping(.wheelSpin)
    }

    static func wheelSpinEnd() {
        SoundManager.shared.stop(.wheelSpin)
        HapticManager.shared.success()
        SoundManager.shared.play(.success, volume: 0.5)
    }

    static func timerWarning() {
        HapticManager.shared.selection()
        SoundManager.shared.play(.countdown)
    }

    static func timerEnded() {
        HapticManager.shared.medium()
    }

    static func success() {
        HapticManager.shared.success()
        SoundManager.shared.play(.success)
    }

    static func warning() {
        HapticManager.shared.warning()
        SoundManager.shared.play(.error, volume: 0.55)
    }

    static func error() {
        HapticManager.shared.error()
        SoundManager.shared.play(.error)
    }

    static func lightTap() {
        HapticManager.shared.light()
        SoundManager.shared.play(.clickPop)
    }

    static func selection() {
        HapticManager.shared.selection()
    }
}
