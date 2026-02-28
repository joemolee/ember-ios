import Foundation

protocol SpeechServiceProtocol {
    var isListening: Bool { get }
    var isAvailable: Bool { get }
    var transcript: String { get }

    func startListening() throws
    func stopListening()
    func requestAuthorization() async -> Bool
}
