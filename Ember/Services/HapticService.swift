import UIKit

@Observable
final class HapticService {
    var isEnabled: Bool = true

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    func selection() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    // MARK: - Semantic Helpers

    func onSend() {
        impact(.light)
    }

    func onResponseComplete() {
        notification(.success)
    }

    func onVoiceStart() {
        impact(.medium)
    }

    func onError() {
        notification(.error)
    }
}
