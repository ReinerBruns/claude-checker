import SwiftUI

struct DropdownView: View {
    @ObservedObject var viewModel: DropdownViewModel

    @State private var isRefreshing = false

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        f.locale = Locale.current
        return f
    }()

    private let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "E HH:mm"
        f.locale = Locale.current
        return f
    }()

    private let fullFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .medium
        f.locale = Locale.current
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Claude Nutzungslimits")
                .font(.headline)
                .padding(.bottom, 2)

            if let error = viewModel.errorMessage {
                HStack(alignment: .top) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Session (5-hour window)
            usageSection(
                title: "Plan-Nutzungslimits",
                subtitle: "Current session",
                percent: viewModel.usage.sessionPercent,
                resetTime: viewModel.usage.sessionResetTime,
                resetLabel: "Zuruecksetzung"
            )

            Divider()

            // Weekly (7-day)
            usageSection(
                title: "Woechentliche Limits",
                subtitle: "All models",
                percent: viewModel.usage.weeklyPercent,
                resetTime: viewModel.usage.weeklyResetTime,
                resetLabel: "Zuruecksetzung"
            )

            Divider()

            if let updated = viewModel.lastUpdated {
                Text("Aktualisiert: \(fullFormatter.string(from: updated))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            HStack {
                Button {
                    guard !isRefreshing else { return }
                    isRefreshing = true
                    viewModel.onRefresh?()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
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

                Button(action: { viewModel.onSettings?() }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
                .help("Einstellungen")

                Button(action: { viewModel.onQuit?() }) {
                    Image(systemName: "power")
                }
                .buttonStyle(.borderless)
                .help("Beenden")
            }
        }
        .padding(12)
        .frame(width: 280)
    }

    @ViewBuilder
    private func usageSection(title: String, subtitle: String, percent: Double, resetTime: Date?, resetLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)

            HStack {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(percent)) % verwendet")
                    .font(.caption)
                    .foregroundColor(colorForPercent(percent))
                    .fontWeight(.medium)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background gradient matching claude.ai style
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(
                            colors: gradientForPercent(percent),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: max(0, geometry.size.width * CGFloat(percent / 100.0)), height: 10)
                }
            }
            .frame(height: 10)

            if let reset = resetTime {
                let remaining = remainingTimeString(until: reset)
                Text("\(resetLabel) \(remaining)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func remainingTimeString(until date: Date) -> String {
        let now = Date()
        let interval = date.timeIntervalSince(now)
        guard interval > 0 else { return "jetzt" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 24 {
            return dateTimeFormatter.string(from: date)
        } else if hours > 0 {
            return "in \(hours) Std. \(minutes) Min."
        } else {
            return "in \(minutes) Min."
        }
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
            return [Color.blue, Color.green]
        } else if percent < 75 {
            return [Color.blue, Color.orange]
        } else {
            return [Color.orange, Color.red]
        }
    }
}
