import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: NewFollowUpStore
    @StateObject private var userProfileStore = UserProfileStore()
    @State private var query: String = ""
    @State private var selectedFilter: Filter = .all
    @State private var showAddSheet: Bool = false
    @State private var selectedItem: FollowUp?
    @State private var showSettingsSheet: Bool = false
    @State private var showNotificationsSheet: Bool = false
    @State private var isCompletedSectionExpanded = false
    @State private var isOverdueSectionExpanded = false
    @State private var notificationCount = 0
    @State private var unreadNotificationIds: Set<String> = []
    @State private var notificationRefreshTimer: Timer?
    @FocusState private var isSearchFocused: Bool
    @State private var isRefreshing = false
    // Removed themeManager dependency for instant theme switching
    private let sharedDataManager = SharedDataManager.shared

    enum Filter: String, CaseIterable { 
        case all, doIt, waitingOn, overdue, completed 
        
        var title: String {
            switch self {
            case .all: return "All"
            case .doIt: return "Do"
            case .waitingOn: return "Waiting-On"
            case .overdue: return "Overdue"
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
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                titleRow
                    .padding(.horizontal)
                    .padding(.top, 12)

                listContent
            }
            .toolbar(.hidden, for: .navigationBar)
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
                    .environmentObject(userProfileStore)
            }
            .sheet(isPresented: $showNotificationsSheet) {
                NotificationsActivityView()
                    .onDisappear {
                        // Mark all notifications as read when sheet is dismissed
                        markAllNotificationsAsRead()
                    }
            }
            .onAppear {
                print("🏠 HomeView: onAppear called - this should show every time you open the app")
                print("🏠 HomeView: View appeared")
                print("   - Store has \(store.followUps.count) follow-ups")
                print("   - Store isLoading: \(store.isLoading)")
                if let error = store.error {
                    print("   - Store error: \(error)")
                }
                loadReadNotificationIds()
                loadNotificationCount()
                
                // Start periodic notification count refresh
                startNotificationRefreshTimer()
                
                // Process any pending shared follow-ups from share extension
                Task {
                    print("🏠 HomeView: App appeared, checking for shared data...")
                    print("🏠 HomeView: Store has \(await store.followUps.count) follow-ups before processing")
                    
                    // Debug: Check UserDefaults data directly
                    debugUserDefaultsData()
                    
                    // Clean up existing duplicate follow-ups first
                    await sharedDataManager.cleanupDuplicateFollowUps(using: store)
                    
                    print("🏠 HomeView: About to call sharedDataManager.processPendingSharedFollowUps()")
                    await sharedDataManager.processPendingSharedFollowUps(using: store)
                    print("🏠 HomeView: Store has \(await store.followUps.count) follow-ups after processing")
                    print("🏠 HomeView: SharedDataManager processing completed")
                }
            }
            .onChange(of: store.items) { _ in
                // Update notification count when items change
                loadNotificationCount()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                loadNotificationCount()
                // Note: Removed duplicate processing to prevent multiple calls
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Note: Removed duplicate processing to prevent multiple calls
            }
            .onDisappear {
                // Stop timer when view disappears
                notificationRefreshTimer?.invalidate()
                notificationRefreshTimer = nil
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Spacer()
            
            HStack(spacing: 24) {
                // Notifications button
                Button {
                    showNotificationsSheet = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.primary)
                        
                        // Notification count badge
                        if notificationCount > 0 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Text("\(notificationCount)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 8, y: -8)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                // Settings button
                Button {
                    showSettingsSheet = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.primary)
                        
                        // Pending badge for incomplete profile
                        if userProfileStore.profile?.isProfileIncomplete ?? true {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Text("1")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 6, y: -6)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    private var searchField: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search", text: $query)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($isSearchFocused)
                
                // Clear button (X) when there's text
                if !query.isEmpty {
                    Button(action: {
                        query = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture {
                isSearchFocused = true
            }
            
            // Cancel button (appears when search is focused)
            if isSearchFocused {
                Button("Cancel") {
                    isSearchFocused = false
                    query = ""
                }
                .foregroundColor(.primary)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSearchFocused)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All", isSelected: selectedFilter == .all) { selectedFilter = .all }
                chip(title: "Do", isSelected: selectedFilter == .doIt) { selectedFilter = .doIt }
                chip(title: "Waiting-On", isSelected: selectedFilter == .waitingOn) { selectedFilter = .waitingOn }
                chip(title: "Overdue", isSelected: selectedFilter == .overdue) { selectedFilter = .overdue }
                chip(title: "Completed", isSelected: selectedFilter == .completed) { selectedFilter = .completed }
            }
            .padding(.horizontal)
        }
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.primary.opacity(0.1) : Color(.secondarySystemBackground))
                .foregroundStyle(.primary)
                .clipShape(Capsule())
                .overlay(
                    // Add border only for selected chips
                    Group {
                        if isSelected {
                            Capsule()
                                .stroke(Color.primary, lineWidth: 1)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
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
        case .overdue: return "Overdue"
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
                    
                    // Overdue section (only show in "All" filter and if there are overdue items)
                    if selectedFilter == .all && !overdueItems.isEmpty {
                        Section {
                            if isOverdueSectionExpanded {
                                ForEach(overdueItems) { item in
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
                                    isOverdueSectionExpanded.toggle()
                                }
                            }) {
                                HStack {
                                    Text("Overdue")
                                        .font(.headline)
                                        .foregroundStyle(.red)
                                        .textCase(nil)
                                    
                                    Spacer()
                                    
                                    Text("\(overdueItems.count)")
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.red)
                                        .clipShape(Capsule())
                                    
                                    Image(systemName: isOverdueSectionExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.red)
                                        .animation(.easeInOut(duration: 0.2), value: isOverdueSectionExpanded)
                                }
                                .padding(.top, 8)
                                .padding(.bottom, 4)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
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
                .refreshable {
                    await refreshData()
                }
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
        let now = Date()
        let base: [FollowUp] = {
            switch selectedFilter {
            case .all: 
                // Exclude completed AND overdue items from main list - overdue items show in their own section
                return store.items.filter { $0.status != .done && $0.dueAt >= now }
            case .doIt: 
                return store.items.filter { 
                    $0.type == .doIt && ($0.status == .open || $0.status == .snoozed) && $0.dueAt >= now 
                }
            case .waitingOn: 
                return store.items.filter { 
                    $0.type == .waitingOn && ($0.status == .open || $0.status == .snoozed) && $0.dueAt >= now 
                }
            case .overdue: return overdueItems
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
    
    private var overdueItems: [FollowUp] {
        let now = Date()
        return store.items.filter { item in
            item.status != .done && item.dueAt < now
        }.sorted(by: { first, second in
            // Sort by due date (most overdue first)
            first.dueAt < second.dueAt
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
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
    
    private func loadNotificationCount() {
        Task {
            // Get delivered notifications that haven't been marked as read
            let deliveredNotifications = await UNUserNotificationCenter.current().deliveredNotifications()
            let unreadDeliveredCount = deliveredNotifications.filter { notification in
                !unreadNotificationIds.contains(notification.request.identifier)
            }.count
            
            await MainActor.run {
                self.notificationCount = unreadDeliveredCount
                print("📱 Notification count updated: \(self.notificationCount) unread notifications")
                
                // Update app badge to match in-app count
                Task {
                    try? await UNUserNotificationCenter.current().setBadgeCount(unreadDeliveredCount)
                }
            }
        }
    }
    
    private func markAllNotificationsAsRead() {
        Task {
            let deliveredNotifications = await UNUserNotificationCenter.current().deliveredNotifications()
            await MainActor.run {
                // Mark all delivered notifications as read
                for notification in deliveredNotifications {
                    unreadNotificationIds.insert(notification.request.identifier)
                }
                
                // Update counts
                self.notificationCount = 0
                
                // Clear app badge
                Task {
                    try? await UNUserNotificationCenter.current().setBadgeCount(0)
                }
                
                // Store read status in UserDefaults
                UserDefaults.standard.set(Array(unreadNotificationIds), forKey: "readNotificationIds")
                
                print("📱 All notifications marked as read")
            }
        }
    }
    
    private func loadReadNotificationIds() {
        if let readIds = UserDefaults.standard.array(forKey: "readNotificationIds") as? [String] {
            unreadNotificationIds = Set(readIds)
        }
    }
    
    private func startNotificationRefreshTimer() {
        // Stop any existing timer
        notificationRefreshTimer?.invalidate()
        
        // Start a timer that checks for new notifications every 10 seconds
        notificationRefreshTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            Task {
                await MainActor.run {
                    loadNotificationCount()
                }
            }
        }
    }
    
    private func refreshData() async {
        print("🔄 HomeView: Pull-to-refresh triggered")
        print("🔄 HomeView: Store has \(await store.followUps.count) follow-ups before refresh")
        isRefreshing = true
        
        // Reload follow-ups from Core Data
        print("🔄 HomeView: Reloading follow-ups from Core Data...")
        await store.loadFollowUps()
        print("🔄 HomeView: Store has \(await store.followUps.count) follow-ups after Core Data reload")
        
        // Only process shared data if there's actually pending data
        if sharedDataManager.hasPendingSharedFollowUps() {
            print("🔄 HomeView: Found pending shared data during refresh...")
            await sharedDataManager.processPendingSharedFollowUps(using: store)
            print("🔄 HomeView: Store has \(await store.followUps.count) follow-ups after shared data processing")
        } else {
            print("🔄 HomeView: No pending shared data found during refresh")
        }
        
        // Update notification count
        loadNotificationCount()
        
        await MainActor.run {
            isRefreshing = false
        }
        
        print("✅ HomeView: Pull-to-refresh completed")
        print("✅ HomeView: Final follow-ups count: \(await store.followUps.count)")
    }
    
    private func debugUserDefaultsData() {
        print("🔍 HomeView: Debugging UserDefaults data...")
        
        // Check app group UserDefaults
        if let appGroupUserDefaults = UserDefaults(suiteName: "group.app.pingback.shared") {
            print("🔍 HomeView: App Group UserDefaults accessible")
            if let data = appGroupUserDefaults.data(forKey: "shared_followups") {
                print("🔍 HomeView: Found data in app group UserDefaults")
                if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    print("🔍 HomeView: App group data contains \(json.count) items")
                    for (index, item) in json.enumerated() {
                        print("   - App Group Item \(index + 1): \(item)")
                    }
                } else {
                    print("🔍 HomeView: Failed to parse app group data as JSON")
                }
            } else {
                print("🔍 HomeView: No data found in app group UserDefaults")
            }
        } else {
            print("🔍 HomeView: App Group UserDefaults not accessible")
        }
        
        // Check standard UserDefaults
        if let data = UserDefaults.standard.data(forKey: "pingback_shared_followups") {
            print("🔍 HomeView: Found data in standard UserDefaults")
            if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                print("🔍 HomeView: Standard UserDefaults data contains \(json.count) items")
                for (index, item) in json.enumerated() {
                    print("   - Standard Item \(index + 1): \(item)")
                }
            } else {
                print("🔍 HomeView: Failed to parse standard UserDefaults data as JSON")
            }
        } else {
            print("🔍 HomeView: No data found in standard UserDefaults")
        }
        
        // Check app group file
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.app.pingback.shared") {
            let sharedDataURL = appGroupURL.appendingPathComponent("shared_followups.json")
            if FileManager.default.fileExists(atPath: sharedDataURL.path) {
                print("🔍 HomeView: Found app group file at \(sharedDataURL)")
                do {
                    let data = try Data(contentsOf: sharedDataURL)
                    if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        print("🔍 HomeView: App group file contains \(json.count) items")
                        for (index, item) in json.enumerated() {
                            print("   - File Item \(index + 1): \(item)")
                        }
                    } else {
                        print("🔍 HomeView: Failed to parse app group file as JSON")
                    }
                } catch {
                    print("🔍 HomeView: Error reading app group file: \(error)")
                }
            } else {
                print("🔍 HomeView: No app group file found")
            }
        } else {
            print("🔍 HomeView: App group container not accessible")
        }
    }
}

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var userProfileStore: UserProfileStore
    
    var body: some View {
        SettingsSheetView()
            .environmentObject(themeManager)
            .environmentObject(userProfileStore)
    }
}
