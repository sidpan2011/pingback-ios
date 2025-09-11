import SwiftUI

struct HomeView: View {
    @StateObject private var store = FollowUpStore()
    @State private var query: String = ""
    @State private var selectedFilter: Filter = .all
    @State private var showAddSheet: Bool = false
    @State private var selectedItem: FollowUp?

    enum Filter: String, CaseIterable { 
        case all, doIt, waitingOn, completed 
        
        var title: String {
            switch self {
            case .all: return "All"
            case .doIt: return "Do"
            case .waitingOn: return "Waiting-On"
            case .completed: return "Completed"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal)
                    .padding(.top, 12)

                searchField
                    .padding(.horizontal)
                    .padding(.top, 8)

                filterChips
                    .padding(.horizontal)
                    .padding(.top, 8)

                titleRow
                    .padding(.horizontal)
                    .padding(.top, 12)

                listContent
            }
            .toolbar(.hidden, for: .navigationBar)
            .searchable(text: $query, prompt: "Search follow-ups")
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            .accessibilityLabel("Add follow-up")
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 16)
                    .padding(.bottom, 12)
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddFollowUpView(store: store)
            }
            .sheet(item: $selectedItem) { item in
                AddFollowUpView(store: store, existingItem: item)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 55, height: 55)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting()).font(.body).foregroundStyle(.secondary)
                Text("Sidhanth").font(.largeTitle.bold())
            }
            Spacer()
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search", text: $query)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var filterChips: some View {
        HStack(spacing: 8) {
            chip(title: "All", isSelected: selectedFilter == .all) { selectedFilter = .all }
            chip(title: "Do", isSelected: selectedFilter == .doIt) { selectedFilter = .doIt }
            chip(title: "Waiting-On", isSelected: selectedFilter == .waitingOn) { selectedFilter = .waitingOn }
            chip(title: "Completed", isSelected: selectedFilter == .completed) { selectedFilter = .completed }
            Spacer()
        }
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var titleRow: some View {
        HStack {
            Text(currentTitle)
                .font(.title).bold()
            Spacer()
        }
    }

    private var currentTitle: String {
        switch selectedFilter {
        case .all: return "All"
        case .doIt: return "Do"
        case .waitingOn: return "Waiting-On"
        case .completed: return "Completed"
        }
    }

    private var listContent: some View {
        List {
            ForEach(groupedItems.keys.sorted(), id: \.self) { date in
                Section(header: Text(dateSectionTitle(for: date))
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .textCase(nil)
                    .padding(.top, 4)) {
                    ForEach(groupedItems[date] ?? []) { item in
                        FollowUpRow(
                            item: item,
                            onBump: { bumpItem(item) },
                            onSnooze: { snoozeItem(item) },
                            onDetails: { selectedItem = item },
                            onDone: { markDone(item) }
                        )
                        .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var filteredItems: [FollowUp] {
        let base: [FollowUp] = {
            switch selectedFilter {
            case .all: return store.items
            case .doIt: return store.items.filter { $0.type == .doIt && $0.status == .open }
            case .waitingOn: return store.items.filter { $0.type == .waitingOn && $0.status == .open }
            case .completed: return store.items.filter { $0.status == .done }
            }
        }()
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return base }
        let q = query.lowercased()
        return base.filter { 
            $0.contactLabel.lowercased().contains(q) || 
            $0.snippet.lowercased().contains(q) || 
            $0.verb.lowercased().contains(q) 
        }
    }
    
    private var groupedItems: [Date: [FollowUp]] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredItems) { item in
            calendar.startOfDay(for: item.dueAt)
        }
        return grouped
    }
    
    private func dateSectionTitle(for date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        if calendar.isDate(date, inSameDayAs: today) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Tomorrow"
        } else if calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Actions
    
    private func bumpItem(_ item: FollowUp) {
        guard let url = DeepLinkBuilder.url(for: item.app, text: item.snippet) else { return }
        UIApplication.shared.open(url)
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func snoozeItem(_ item: FollowUp) {
        store.snooze(item, minutes: 60) // Snooze for 1 hour
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func markDone(_ item: FollowUp) {
        store.markDone(item)
        // Add haptic feedback for double-tap
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        case 17..<22: return "Good evening,"
        default: return "Hello,"
        }
    }
}
