import UIKit

class HapticManager {
    static let shared = HapticManager()

    private var isEnabled: Bool = true
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    private init() {
        prepareGenerators()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if enabled {
            prepareGenerators()
        }
    }

    func light() {
        guard isEnabled else { return }
        lightGenerator.prepare()
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    func medium() {
        guard isEnabled else { return }
        mediumGenerator.prepare()
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    func success() {
        guard isEnabled else { return }
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    func warning() {
        guard isEnabled else { return }
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    func error() {
        guard isEnabled else { return }
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }

    func selection() {
        guard isEnabled else { return }
        selectionGenerator.prepare()
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    private func prepareGenerators() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
}
