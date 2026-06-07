import Foundation
import AVFoundation
import Speech
import UIKit

/// On-device continuous transcription for a full sermon. Recording ends ONLY on stop(): pauses and
/// per-utterance finalization roll a fresh segment under a continuously-running engine, accumulating
/// into `committed`, and call/Siri interruptions pause & resume rather than ending. (Ported from Noctera.)
@MainActor
final class SpeechCapture: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var authorized = false
    @Published var available = true

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var committed = ""
    private var segmentPartial = ""
    private var segmentSeq = 0
    private var consecutiveErrors = 0
    private static let maxConsecutiveErrors = 3
    private var interrupted = false
    private var interruptionObserver: NSObjectProtocol?

    func requestAuth() async {
        let speech = await withCheckedContinuation { (c: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0 == .authorized) }
        }
        let mic = await AVAudioApplication.requestRecordPermissionAsync()
        authorized = speech && mic
        available = recognizer?.isAvailable ?? false
    }

    func start() {
        guard authorized, let recognizer, recognizer.isAvailable else { return }
        stop()
        transcript = ""; committed = ""; segmentPartial = ""; consecutiveErrors = 0; interrupted = false
        do {
            try startEngine(); isRecording = true; observeInterruptions(); beginSegment()
            UIApplication.shared.isIdleTimerDisabled = true   // 整篇讲道屏幕不锁(配合后台音频模式)
        } catch { isRecording = false }
    }

    func stop() {
        isRecording = false
        UIApplication.shared.isIdleTimerDisabled = false
        removeInterruptionObserver()
        teardownSegment()
        if engine.isRunning { engine.stop(); engine.inputNode.removeTap(onBus: 0) }
        foldPartial()
        if !committed.isEmpty { transcript = committed }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startEngine() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        let input = engine.inputNode
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { [weak self] buf, _ in
            self?.request?.append(buf)
        }
        engine.prepare(); try engine.start()
    }

    private func beginSegment() {
        guard isRecording, !interrupted, request == nil, let recognizer else { return }
        segmentSeq += 1; let seq = segmentSeq; segmentPartial = ""
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = true
        request = req
        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            let text = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let failed = error != nil
            Task { @MainActor [weak self] in
                guard let self, self.isRecording, seq == self.segmentSeq else { return }
                if let text {
                    if text.count >= self.segmentPartial.count { self.segmentPartial = text; self.refreshTranscript() }
                    if isFinal { self.endSegment(final: true) }
                } else if failed { self.endSegment(final: false) }
            }
        }
    }

    private func endSegment(final: Bool) {
        guard isRecording, !interrupted else { return }
        let text = segmentPartial
        if !text.isEmpty { committed = committed.isEmpty ? text : committed + " " + text }
        if final || !text.isEmpty { consecutiveErrors = 0 } else { consecutiveErrors += 1 }
        segmentPartial = ""; refreshTranscript(); task = nil; request = nil
        if consecutiveErrors >= Self.maxConsecutiveErrors { available = false; stop(); return }
        beginSegment()
    }

    private func teardownSegment() { request?.endAudio(); task?.cancel(); request = nil; task = nil; segmentSeq += 1 }
    private func foldPartial() { guard !segmentPartial.isEmpty else { return }; committed = committed.isEmpty ? segmentPartial : committed + " " + segmentPartial; segmentPartial = "" }
    private func refreshTranscript() {
        if committed.isEmpty { transcript = segmentPartial }
        else if segmentPartial.isEmpty { transcript = committed }
        else { transcript = committed + " " + segmentPartial }
    }

    private func observeInterruptions() {
        removeInterruptionObserver()
        interruptionObserver = NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            MainActor.assumeIsolated { self?.handleInterruption(note) }
        }
    }
    private func removeInterruptionObserver() { if let o = interruptionObserver { NotificationCenter.default.removeObserver(o) }; interruptionObserver = nil }
    private func handleInterruption(_ note: Notification) {
        guard isRecording, let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        switch type {
        case .began:
            interrupted = true; teardownSegment()
            if engine.isRunning { engine.stop(); engine.inputNode.removeTap(onBus: 0) }
            foldPartial(); refreshTranscript()
        case .ended:
            let opts = (note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt).map { AVAudioSession.InterruptionOptions(rawValue: $0) } ?? []
            guard opts.contains(.shouldResume) else { return }
            interrupted = false
            do { try startEngine(); beginSegment() } catch { stop() }
        @unknown default: break
        }
    }
}

extension AVAudioApplication {
    static func requestRecordPermissionAsync() async -> Bool {
        await withCheckedContinuation { c in AVAudioApplication.requestRecordPermission { c.resume(returning: $0) } }
    }
}
