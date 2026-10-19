import Foundation
import Speech
import AVFoundation

final class SpeechManager: NSObject, ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func requestPermissions() async -> Bool {
        let speechAuth = await withCheckedContinuation { (continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        let audioAuth = await AVCaptureDevice.requestAccess(for: .audio)
        return speechAuth == .authorized && audioAuth
    }

    func toggleRecording() {
        isRecording ? stop() : start()
    }

    private func start() {
        guard !audioEngine.isRunning else { return }

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }

        let input = audioEngine.inputNode
        request.shouldReportPartialResults = true

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            if let result {
                DispatchQueue.main.async {
                    self?.transcript = result.bestTranscription.formattedString
                }
            }
            if error != nil {
                self?.stop()
            }
        }

        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async { self.isRecording = true }
        } catch {
            stop()
        }
    }

    private func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        DispatchQueue.main.async { self.isRecording = false }
    }
}
