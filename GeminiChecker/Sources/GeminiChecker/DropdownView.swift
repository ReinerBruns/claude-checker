import SwiftUI

struct DropdownView: View {
    let usage: GeminiUsageData
    let lastUpdated: Date?
    let errorMessage: String?
    let onSettings: () -> Void
    let onQuit: () -> Void
    let onRefresh: () -> Void

    @State private var isRefreshing = false

    private let fullFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .medium
        f.locale = Locale.current
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gemini Nutzungslimits")
                        .font(.headline)
                    if let email = usage.accountEmail {
                        Text("\(email) • \(usage.accountPlan ?? "Google AI Pro")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.bottom, 2)

            // Error display
            if let error = errorMessage {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .imageScale(.small)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }

            if usage.groups.isEmpty && errorMessage == nil {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Kontingente werden geladen...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                // Section 1: Gemini Models (Flash, Pro)
                if let gemini = usage.geminiGroup {
                    groupView(
                        group: gemini,
                        fallbackTitle: "Gemini Modelle",
                        subtitleInfo: "Flash & Pro Modelle"
                    )
                }

                // Section 2: Gemini 4 Argon
                if let argon = usage.argonGroup {
                    Divider()
                    groupView(
                        group: argon,
                        fallbackTitle: "Gemini 4 Argon",
                        subtitleInfo: "Frontier Modell • nur Wochenlimit"
                    )
                }

                // Section 3: Third Party (Claude & GPT)
                if let thirdParty = usage.thirdPartyGroup {
                    Divider()
                    groupView(
                        group: thirdParty,
                        fallbackTitle: "Claude & GPT Modelle",
                        subtitleInfo: "Drittanbieter Kontingent"
                    )
                }
            }

            Divider()

            // Footer
            if let updated = lastUpdated {
                Text("Aktualisiert: \(fullFormatter.string(from: updated))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            HStack {
                Button {
                    guard !isRefreshing else { return }
                    isRefreshing = true
                    onRefresh()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isRefreshing = false
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(.easeInOut(duration: 0.6), value: isRefreshing)
                }
                .buttonStyle(.borderless)
                .help("Aktualisieren")

                Spacer()

                Button(action: onSettings) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
                .help("Einstellungen")

                Button(action: onQuit) {
                    Image(systemName: "power")
                }
                .buttonStyle(.borderless)
                .help("Beenden")
            }
        }
        .padding(13)
        .frame(width: 300)
    }

    @ViewBuilder
    private func groupView(group: QuotaGroup, fallbackTitle: String, subtitleInfo: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(group.name.isEmpty ? fallbackTitle : group.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Text(subtitleInfo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            ForEach(group.buckets) { bucket in
                bucketRow(bucket: bucket)
            }
        }
    }

    @ViewBuilder
    private func bucketRow(bucket: QuotaBucket) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(bucketTitle(bucket))
                    .font(.caption)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(bucket.usedPercent) % verwendet")
                    .font(.caption)
                    .foregroundColor(colorForPercent(Double(bucket.usedPercent)))
                    .fontWeight(.semibold)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3.5)
                        .fill(Color.gray.opacity(0.18))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 3.5)
                        .fill(LinearGradient(
                            colors: gradientForPercent(Double(bucket.usedPercent)),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: max(0, geometry.size.width * CGFloat(bucket.usedFraction)), height: 8)
                }
            }
            .frame(height: 8)

            if let reset = bucket.resetTimeString {
                Text(reset)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func bucketTitle(_ bucket: QuotaBucket) -> String {
        if bucket.isSession {
            return "5-Stunden-Sitzung"
        } else if bucket.isWeekly {
            return "Wöchentliches Kontingent"
        }
        return bucket.name
    }

    private func colorForPercent(_ percent: Double) -> Color {
        if percent < 50 {
            return .green
        } else if percent < 75 {
            return .orange
        } else {
            return .red
        }
    }

    private func gradientForPercent(_ percent: Double) -> [Color] {
        if percent < 50 {
            return [Color.blue.opacity(0.8), Color.green]
        } else if percent < 75 {
            return [Color.blue.opacity(0.8), Color.orange]
        } else {
            return [Color.orange, Color.red]
        }
    }
}
