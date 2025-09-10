import SwiftUI

struct QuickAddView: View {
    @ObservedObject var store: FollowUpStore

    @State private var text: String = ""
    @State private var contact: String = ""
    @State private var type: FollowType = .doIt
    @State private var app: AppKind = .whatsapp
    @State private var overrideDue: Date? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Picker("", selection: $type) {
                    ForEach(FollowType.allCases) { t in
                        Text(t.title).tag(t)
                    }
                }
                .pickerStyle(.segmented)

                Picker("", selection: $app) {
                    ForEach(AppKind.allCases) { a in
                        Image(systemName: a.icon).tag(a)
                    }
                }
                .pickerStyle(.menu)
            }

            TextField("Contact (optional)", text: $contact)
                .textFieldStyle(.roundedBorder)

            TextField("Paste a message… (e.g., “Can you share the deck tomorrow 10?”)", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)

            HStack(spacing: 8) {
                QuickChip(" +15m ") { overrideDue = Date().addingTimeInterval(15 * 60) }
                QuickChip(" +2h ") { overrideDue = Date().addingTimeInterval(2 * 3600) }
                QuickChip(" Tonight ") {
                    overrideDue = Parser.shared.parse(text: "tonight", now: .now, eodHour: store.settings.eodHour, morningHour: store.settings.morningHour)?.dueAt
                }
                QuickChip(" Tomorrow AM ") {
                    overrideDue = Parser.shared.parse(text: "tomorrow", now: .now, eodHour: store.settings.eodHour, morningHour: store.settings.morningHour)?.dueAt
                }
                if let due = overrideDue {
                    Text("Due: \(due.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
        }
            Button {
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                store.add(from: text, type: type, contact: contact, app: app, overrideDue: overrideDue)
                text = ""
                contact = ""
                overrideDue = nil
            } label: {
                Label("Save", systemImage: "plus.circle.fill")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}


