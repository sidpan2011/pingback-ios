import SwiftUI

struct FollowUpRow: View {
    let item: FollowUp
    var onDone: () -> Void
    var onSnooze: () -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.app.icon)
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.contactLabel).font(.headline)
                    Spacer()
                    DueBadge(date: item.dueAt)
                }
                Text(item.snippet)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Button {
                        let text = bumpTemplate(for: item)
                        if let url = DeepLinkBuilder.url(for: item.app, text: text) {
                            openURL(url)
                        }
                    } label: {
                        Label("Bump", systemImage: "arrow.uturn.right.circle")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        onSnooze()
                    } label: {
                        Label("Snooze 2h", systemImage: "zzz")
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive, action: onDone) {
                        Label("Done", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(.borderless)
                }
                .font(.subheadline)
            }
        }
        .padding(.vertical, 6)
    }

    private func bumpTemplate(for item: FollowUp) -> String {
        switch item.type {
        case .doIt:
            return "On it — sending \(item.verb) now."
        case .waitingOn:
            let t = item.dueAt.formatted(date: .omitted, time: .shortened)
            return "Quick nudge on \(item.verb) — could you share it by \(t)?"
        }
    }
}


