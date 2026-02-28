import Foundation
import Speech
import AVFoundation

enum SpeechServiceError: LocalizedError {
    case notAvailable
    case notAuthorized
    case audioEngineError(underlying: Error)
    case recognitionFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Speech recognition is not available on this device."
        case .notAuthorized:
            return "Speech recognition is not authorized. Please enable it in Settings."
        case .audioEngineError(let error):
            return "Audio engine error: \(error.localizedDescription)"
        case .recognitionFailed(let error):
            return "Recognition failed: \(error.localizedDescription)"
        }
    }
}

@Observable
final class AppleSpeechService: SpeechServiceProtocol {

    var isListening: Bool = false
    var isAvailable: Bool = false
    var transcript: String = ""

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    init(locale: Locale = .current) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
        self.isAvailable = speechRecognizer?.isAvailable ?? false
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                let authorized = status == .authorized
                continuation.resume(returning: authorized)
            }
        }
    }

    func startListening() throws {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechServiceError.notAvailable
        }

        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            throw SpeechServiceError.notAuthorized
        }

        // Cancel any in-progress recognition
        stopListening()

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw SpeechServiceError.audioEngineError(underlying: error)
        }

        // Create recognition request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = speechRecognizer.supportsOnDeviceRecognition
        self.recognitionRequest = request

        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                self.transcript = result.bestTranscription.formattedString
            }

            if error != nil || (result?.isFinal ?? false) {
                self.tearDownAudioSession()
            }
        }

        // Configure audio engine input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            tearDownAudioSession()
            throw SpeechServiceError.audioEngineError(underlying: error)
        }

        isListening = true
    }

    func stopListening() {
        tearDownAudioSession()
    }

    // MARK: - Private

    private func tearDownAudioSession() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        isListening = false

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
