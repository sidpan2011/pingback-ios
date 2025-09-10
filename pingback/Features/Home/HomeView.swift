import SwiftUI

struct HomeView: View {
    @StateObject private var store = FollowUpStore()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                QuickAddView(store: store)
                    .padding(.horizontal)
                    .padding(.top, 8)

                List {
                    Section(header: sectionHeader(title: "Do")) {
                        ForEach(store.items.filter { $0.status == .open && $0.type == .doIt }.sorted { $0.dueAt < $1.dueAt }) { item in
                            FollowUpRow(item: item,
                                        onDone: { store.markDone(item) },
                                        onSnooze: { store.snooze(item, minutes: 120) })
                        }
                    }
                    Section(header: sectionHeader(title: "Waiting-On")) {
                        ForEach(store.items.filter { $0.status == .open && $0.type == .waitingOn }.sorted { $0.dueAt < $1.dueAt }) { item in
                            FollowUpRow(item: item,
                                        onDone: { store.markDone(item) },
                                        onSnooze: { store.snooze(item, minutes: 120) })
                        }
                    }

                    if !store.items.filter({ $0.status == .done }).isEmpty {
                        Section(header: sectionHeader(title: "Done")) {
                            ForEach(store.items.filter { $0.status == .done }.sorted { $0.dueAt > $1.dueAt }) { item in
                                FollowUpRow(item: item, onDone: { }, onSnooze: { })
                                    .opacity(0.5)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Pingback")
        }
    }

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title).font(.headline)
            Spacer()
        }
        .textCase(nil)
    }
}


