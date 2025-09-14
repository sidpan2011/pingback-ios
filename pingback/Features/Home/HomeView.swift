import SwiftUI

struct HomeView: View {
    @StateObject private var store = NewFollowUpStore()
    @StateObject private var userProfileStore = UserProfileStore()
    @State private var query: String = ""
    @State private var selectedFilter: Filter = .all
    @State private var showAddSheet: Bool = false
    @State private var selectedItem: FollowUp?
    @State private var showSettingsSheet: Bool = false
    @State private var isCompletedSectionExpanded = false
    @EnvironmentObject private var themeManager: ThemeManager

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
                            .background(.tint)
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
            .sheet(isPresented: $showSettingsSheet) {
                SettingsSheet()
            }
            .onAppear {
                print("🏠 HomeView: View appeared")
                print("   - Store has \(store.followUps.count) follow-ups")
                print("   - Store isLoading: \(store.isLoading)")
                if let error = store.error {
                    print("   - Store error: \(error)")
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Pingback")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)
            Spacer()
            Button {
                showSettingsSheet = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.primary)
                    
                    // Pending badge for incomplete profile
                    if userProfileStore.profile?.isProfileIncomplete ?? true {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Text("1")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 6, y: -6)
                    }
                }
            }
            .buttonStyle(.plain)
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
        Group {
            if store.isLoading {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading follow-ups...")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else if store.items.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "tray")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 8) {
                        Text("No follow-ups yet")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        
                        Text("Tap the + button to create your first follow-up")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else if filteredItems.isEmpty {
                // Filtered empty state
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 8) {
                        Text("No results found")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        
                        Text("Try adjusting your search or filter")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            } else {
                // Content with follow-ups
                List {
                    // Active follow-ups grouped by date
                    ForEach(sortedDateKeys, id: \.self) { date in
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
                                    onDone: { markDone(item) },
                                    onDelete: { deleteItem(item) }
                                )
                                .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                            }
                        }
                    }
                    
                    // Completed section (only show in "All" filter and if there are completed items)
                    if selectedFilter == .all && !completedItems.isEmpty {
                        Section {
                            if isCompletedSectionExpanded {
                                ForEach(completedItems) { item in
                                    FollowUpRow(
                                        item: item,
                                        onBump: { bumpItem(item) },
                                        onSnooze: { snoozeItem(item) },
                                        onDetails: { selectedItem = item },
                                        onDone: { markDone(item) },
                                        onDelete: { deleteItem(item) }
                                    )
                                    .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                                }
                            }
                        } header: {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isCompletedSectionExpanded.toggle()
                                }
                            }) {
                                HStack {
                                    Text("Completed")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                        .textCase(nil)
                                    
                                    Spacer()
                                    
                                    Text("\(completedItems.count)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.secondary.opacity(0.2))
                                        .clipShape(Capsule())
                                    
                                    Image(systemName: isCompletedSectionExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)
                                        .animation(.easeInOut(duration: 0.2), value: isCompletedSectionExpanded)
                                }
                                .padding(.top, 8)
                                .padding(.bottom, 4)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .alert("Error", isPresented: .constant(store.error != nil)) {
            Button("OK") {
                store.error = nil
            }
        } message: {
            if let error = store.error {
                Text(error.localizedDescription)
            }
        }
    }

    private var filteredItems: [FollowUp] {
        let base: [FollowUp] = {
            switch selectedFilter {
            case .all: return store.items.filter { $0.status != .done } // Exclude completed from main list
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
    
    private var completedItems: [FollowUp] {
        let base = store.items.filter { $0.status == .done }
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            return base.sorted(by: { first, second in
                // Sort by creation date (most recent first)
                first.createdAt > second.createdAt
            })
        }
        let q = query.lowercased()
        return base.filter { 
            $0.contactLabel.lowercased().contains(q) || 
            $0.snippet.lowercased().contains(q) || 
            $0.verb.lowercased().contains(q) 
        }.sorted(by: { first, second in
            first.createdAt > second.createdAt
        })
    }
    
    private var groupedItems: [Date: [FollowUp]] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredItems) { item in
            calendar.startOfDay(for: item.dueAt)
        }
        return grouped
    }
    
    private var sortedDateKeys: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return groupedItems.keys.sorted { date1, date2 in
            // Today always comes first
            if calendar.isDate(date1, inSameDayAs: today) {
                return true
            }
            if calendar.isDate(date2, inSameDayAs: today) {
                return false
            }
            
            // For non-today dates, sort in descending order (most recent first)
            // This puts Yesterday before older dates
            return date1 > date2
        }
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
        Task {
            do {
                let snoozeDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
                try await store.snooze(item, until: snoozeDate)
                // Add haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            } catch {
                print("Failed to snooze item: \(error)")
            }
        }
    }
    
    private func markDone(_ item: FollowUp) {
        Task {
            do {
                try await store.markCompleted(item, completed: true)
                // Add haptic feedback for double-tap
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            } catch {
                print("Failed to mark item as done: \(error)")
            }
        }
    }
    
    private func deleteItem(_ item: FollowUp) {
        Task {
            do {
                try await store.delete(item)
                // Add haptic feedback for delete
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            } catch {
                print("Failed to delete item: \(error)")
            }
        }
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

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        SettingsSheetView()
    }
}
