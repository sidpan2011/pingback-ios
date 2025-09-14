
import SwiftUI
import Foundation

struct FollowUpRow: View {
    let item: FollowUp
    var onBump: () -> Void
    var onSnooze: () -> Void
    var onDetails: () -> Void
    var onDone: () -> Void
    var onDelete: () -> Void
    @Environment(\.openURL) private var openURL
    
    // Check if item is completed
    private var isCompleted: Bool {
        item.status == .done
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left: App icon
            AppLogoView(item.app, size: 32)
                .padding(.top, 2)

            // Middle: Stacked content
            VStack(alignment: .leading, spacing: 4) {
                // Top line: Contact · verb
                HStack(alignment: .firstTextBaseline) {
                    Text("\(item.contactLabel) · \(item.verb)")
                        .font(.body)
                        .foregroundStyle(isCompleted ? .secondary : .primary)
                        .lineLimit(1)
                    Spacer()

                    // Due badge or Done badge
                    if isCompleted {
                        Text("Done")
                            .font(.system(size: 14))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .foregroundStyle(.secondary)
                    } else {
                        DueBadge(date: item.dueAt)
                    }
                }

                // Second line: message/snippet (if any)
                if !item.snippet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(item.snippet)
                        .font(.subheadline)
                        .foregroundStyle(isCompleted ? .secondary : .secondary)
                        .lineLimit(2)
                }

                // Third line: optional URL button
                if let url = item.url.flatMap(URL.init(string:)) ?? firstURL(in: item.snippet) {
                    let _ = print("URL found: \(url) from item.url: \(item.url ?? "nil")")
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "link")
                                .foregroundStyle(.tint)
                                .font(.system(size: 14, weight: .medium))
                            
                            Text(urlDisplay(url))
                                .lineLimit(1)
                                .font(.caption)
                                .foregroundStyle(.tint)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            print("URL tapped: \(url)")
                            openURL(url)
                        }
                        .accessibilityLabel("Open link \(urlDisplay(url))")
                        .accessibilityAddTraits(.isButton)

                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            if !isCompleted {
                onDone()
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // Delete action available for ALL follow-ups
            Button("Delete") {
                onDelete()
            }
            .tint(.red)
            
            if isCompleted {
                // For completed items: Details only (Delete already added above)
                Button("Details") {
                    onDetails()
                }
                .tint(.secondary)
            } else {
                // For active items: Bump, Snooze, Details (Delete already added above)
                Button("Bump") {
                    onBump()
                }
                .tint(.blue)

                Button("Snooze") {
                    onSnooze()
                }
                .tint(.orange)

                Button("Details") {
                    onDetails()
                }
                .tint(.secondary)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !isCompleted {
                // Mark Done action on left swipe (only for active items)
                Button("Done") {
                    onDone()
                }
                .tint(.green)
            }
        }
    }


    // Detect first URL in the snippet text (so we can render even if the model doesn't store a dedicated URL field yet)
    private func firstURL(in text: String) -> URL? {
        guard !text.isEmpty else { return nil }
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = detector.matches(in: text, options: [], range: NSRange(text.startIndex..<text.endIndex, in: text))
            if let match = matches.first, let range = Range(match.range, in: text) {
                let urlString = String(text[range])
                return URL(string: urlString)
            }
        } catch {
            return nil
        }
        return nil
    }

    // Short display for a URL (host or trimmed)
    private func urlDisplay(_ url: URL) -> String {
        if let host = url.host {
            return host.replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
        }
        let s = url.absoluteString
        return s
            .replacingOccurrences(of: "^https?://", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
}


