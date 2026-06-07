import SwiftUI

struct RecordFlowView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speech = SpeechCapture()
    enum Phase: Equatable { case recording, analyzing, result(SermonNote), failed(String) }
    @State private var phase: Phase = .recording
    @State private var seconds = 0
    @State private var step = 0
    @State private var pulse = false
    private let steps = ["Transcribing the message", "Finding the scriptures", "Organizing your notes"]
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()
            switch phase {
            case .recording: recording
            case .analyzing: analyzing
            case .result(let n): NoteEditorView(note: n, isNew: true, onSave: { store.add($0); dismiss() }, onClose: { dismiss() })
            case .failed(let m): failed(m)
            }
        }
        .task {
            await speech.requestAuth()
            if speech.authorized { speech.start() }
        }
        .onDisappear { speech.stop() }
    }

    private var recording: some View {
        VStack(spacing: 0) {
            HStack {
                Button { speech.stop(); dismiss() } label: { Image(systemName: "xmark").font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.textHi).padding(10).background(Theme.surface, in: Circle()) }
                Spacer()
            }.padding(.horizontal, 16).padding(.top, 8)
            Spacer()
            ZStack {
                Circle().fill(Theme.accentSoft).frame(width: 180, height: 180).scaleEffect(pulse ? 1.08 : 0.96)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                Circle().fill(Theme.accent).frame(width: 96, height: 96)
                Image(systemName: "mic.fill").font(.system(size: 38)).foregroundStyle(.white)
            }.onAppear { pulse = true }
            Text(timeString).font(.system(size: 34, weight: .semibold, design: .rounded)).foregroundStyle(Theme.textHi).monospacedDigit().padding(.top, 28)
            Text(speech.authorized ? "Listening to the sermon…" : "Allow microphone & speech to record").font(.subheadline).foregroundStyle(Theme.textMid).padding(.top, 4)
            // live transcript tail
            if !speech.transcript.isEmpty {
                Text(speech.transcript.suffix(120)).font(.system(size: 13)).foregroundStyle(Theme.textLow)
                    .lineLimit(3).multilineTextAlignment(.center).padding(.horizontal, 28).padding(.top, 14)
            }
            Spacer()
            Button { stopAndOrganize() } label: { Label("Stop & organize", systemImage: "stop.fill") }
                .buttonStyle(PrimaryButtonStyle()).padding(.horizontal, 24).padding(.bottom, 36)
        }
        .onReceive(timer) { _ in if case .recording = phase { seconds += 1 } }
    }

    private var analyzing: some View {
        VStack(spacing: 26) {
            Spacer()
            ZStack {
                Circle().stroke(Theme.accentSoft, lineWidth: 4).frame(width: 88, height: 88)
                Circle().trim(from: 0, to: 0.28).stroke(Theme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 88, height: 88).rotationEffect(.degrees(Double(step) * 120 - 90)).animation(.easeInOut(duration: 0.5), value: step)
                Image(systemName: "text.book.closed").font(.system(size: 28)).foregroundStyle(Theme.accent)
            }
            VStack(spacing: 12) {
                ForEach(steps.indices, id: \.self) { i in
                    HStack(spacing: 10) {
                        Image(systemName: i < step ? "checkmark.circle.fill" : (i == step ? "circle.dotted" : "circle")).foregroundStyle(i <= step ? Theme.accent : Theme.textLow)
                        Text(steps[i]).foregroundStyle(i <= step ? Theme.textHi : Theme.textLow)
                        Spacer()
                    }.font(.system(size: 15, weight: .medium))
                }
            }.padding(.horizontal, 48)
            Spacer(); Spacer()
        }
        .task { await organize() }
    }

    private func failed(_ msg: String) -> some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "exclamationmark.triangle").font(.system(size: 42)).foregroundStyle(Theme.warning)
            Text("Couldn't organize that").font(Theme.serif(20, .semibold)).foregroundStyle(Theme.textHi)
            Text(msg).font(.subheadline).foregroundStyle(Theme.textMid).multilineTextAlignment(.center).padding(.horizontal, 36)
            Spacer()
            Button("Close") { dismiss() }.buttonStyle(PrimaryButtonStyle()).padding(.horizontal, 24).padding(.bottom, 28)
        }
    }

    private func stopAndOrganize() { speech.stop(); withAnimation { phase = .analyzing }; step = 0 }

    private func organize() async {
        let stepper = Task { for i in 0..<steps.count { if Task.isCancelled { break }; await MainActor.run { withAnimation { step = i } }; try? await Task.sleep(nanoseconds: 600_000_000) } }
        do {
            let note = try await PewlyAPI.structure(transcript: speech.transcript, durationMin: max(1, seconds / 60))
            stepper.cancel()
            withAnimation { phase = .result(note) }
        } catch {
            stepper.cancel()
            withAnimation { phase = .failed((error as? APIError)?.errorDescription ?? error.localizedDescription) }
        }
    }

    private var timeString: String { String(format: "%02d:%02d", seconds / 60, seconds % 60) }
}
