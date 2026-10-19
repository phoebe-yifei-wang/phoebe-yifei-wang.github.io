import SwiftUI

struct DiaryView: View {
    @StateObject private var speech = SpeechManager()
    @State private var entry: String = ""
    @State private var rewritten: String = ""
    @State private var isLoading = false
    @State private var message = ""

    private let ai = AIRewriteService()

    var body: some View {
        ZStack {
            AppTheme.darkBlue.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Daily Diary")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Write or speak your thoughts.")
                        .foregroundStyle(AppTheme.textSecondary)

                    textCard(title: "Today’s Entry", text: $entry)

                    HStack(spacing: 12) {
                        Button(speech.isRecording ? "Stop Recording" : "Start Voice Input") {
                            if speech.isRecording {
                                speech.toggleRecording()
                            } else {
                                Task {
                                    let granted = await speech.requestPermissions()
                                    if granted { speech.toggleRecording() }
                                    else { message = "Microphone/Speech permission was not granted." }
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button("Use Transcript") {
                            if !speech.transcript.isEmpty {
                                if !entry.isEmpty { entry += "\n" }
                                entry += speech.transcript
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }

                    if !speech.transcript.isEmpty {
                        Text("Transcript: \(speech.transcript)")
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Button(isLoading ? "Improving..." : "Improve Language with AI") {
                        Task { await rewriteEntry() }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isLoading || entry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    textCard(title: "Improved Version", text: $rewritten, editable: false)

                    if !message.isEmpty {
                        Text(message)
                            .foregroundStyle(.orange)
                            .font(.footnote)
                    }
                }
                .padding(20)
            }
        }
    }

    @ViewBuilder
    private func textCard(title: String, text: Binding<String>, editable: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundStyle(AppTheme.textSecondary)
                .font(.headline)

            if editable {
                TextEditor(text: text)
                    .frame(minHeight: 180)
                    .padding(8)
                    .foregroundStyle(AppTheme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Text(text.wrappedValue.isEmpty ? "Your improved version appears here." : text.wrappedValue)
                    .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
                    .padding(12)
                    .foregroundStyle(AppTheme.textPrimary)
                    .background(AppTheme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func rewriteEntry() async {
        isLoading = true
        message = ""
        do {
            rewritten = try await ai.rewrite(entry)
        } catch {
            message = "Failed to rewrite entry: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AppTheme.darkBlue)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(configuration.isPressed ? 0.7 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(AppTheme.panel.opacity(configuration.isPressed ? 0.7 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
    }
}
