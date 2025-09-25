import Foundation
import SwiftUI

/// Service layer gating for Pro features
@MainActor
class ProServiceGate: ObservableObject {
    static let shared = ProServiceGate()
    
    @Published private(set) var isPro: Bool = false
    private var subscriptionManager: SubscriptionManager?
    
    private init() {
        // Will be set by the app
    }
    
    func configure(with subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        self.isPro = subscriptionManager.isPro
        
        // Listen to subscription changes
        subscriptionManager.$isPro
            .assign(to: &$isPro)
    }
    
    /// Throws ProError.subscriptionRequired if user is not Pro
    func requirePro() throws {
        guard isPro else {
            throw ProError.subscriptionRequired
        }
    }
    
    /// Returns true if user is Pro, false otherwise
    func checkProStatus() -> Bool {
        return isPro
    }
    
    /// Executes the closure only if user is Pro, otherwise throws ProError.subscriptionRequired
    func executeIfPro<T>(_ closure: () throws -> T) throws -> T {
        try requirePro()
        return try closure()
    }
    
    /// Executes the closure only if user is Pro, returns nil otherwise
    func executeIfPro<T>(_ closure: () -> T) -> T? {
        guard isPro else { return nil }
        return closure()
    }
}

// ProError is defined in ProGateView.swift

/// Protocol for services that need Pro gating
protocol ProGatedService {
    var proGate: ProServiceGate { get }
}

/// Default implementation for ProGatedService
extension ProGatedService {
    var proGate: ProServiceGate {
        ProServiceGate.shared
    }
}

/// Free tier usage limits
@MainActor
class FreeTierLimits: ObservableObject {
    static let shared = FreeTierLimits()
    
    @Published private(set) var monthlyExports: Int = 0
    @Published private(set) var monthlyFollowUps: Int = 0
    
    private let maxMonthlyExports = 5
    private let maxMonthlyFollowUps = 10
    
    private let userDefaults = UserDefaults.standard
    private let exportsKey = "monthly_exports"
    private let followUpsKey = "monthly_followups"
    private let lastResetKey = "last_reset_date"
    
    private init() {
        loadUsage()
        resetIfNewMonth()
    }
    
    /// Check if user can perform an export
    func canExport() -> Bool {
        return monthlyExports < maxMonthlyExports
    }
    
    /// Record an export
    func recordExport() {
        monthlyExports += 1
        saveUsage()
    }
    
    /// Check if user can create a follow-up
    func canCreateFollowUp() -> Bool {
        return monthlyFollowUps < maxMonthlyFollowUps
    }
    
    /// Record a follow-up creation
    func recordFollowUp() {
        monthlyFollowUps += 1
        saveUsage()
    }
    
    /// Get remaining exports for the month
    var remainingExports: Int {
        return max(0, maxMonthlyExports - monthlyExports)
    }
    
    /// Get remaining follow-ups for the month
    var remainingFollowUps: Int {
        return max(0, maxMonthlyFollowUps - monthlyFollowUps)
    }
    
    /// Check if user has hit any limits
    var hasHitLimits: Bool {
        return !canExport() || !canCreateFollowUp()
    }
    
    private func loadUsage() {
        monthlyExports = userDefaults.integer(forKey: exportsKey)
        monthlyFollowUps = userDefaults.integer(forKey: followUpsKey)
    }
    
    private func saveUsage() {
        userDefaults.set(monthlyExports, forKey: exportsKey)
        userDefaults.set(monthlyFollowUps, forKey: followUpsKey)
    }
    
    private func resetIfNewMonth() {
        let calendar = Calendar.current
        let now = Date()
        
        if let lastReset = userDefaults.object(forKey: lastResetKey) as? Date {
            if !calendar.isDate(lastReset, equalTo: now, toGranularity: .month) {
                resetUsage()
            }
        } else {
            resetUsage()
        }
    }
    
    private func resetUsage() {
        monthlyExports = 0
        monthlyFollowUps = 0
        saveUsage()
        userDefaults.set(Date(), forKey: lastResetKey)
    }
}

/// Service that combines Pro gating with free tier limits
@MainActor
class ProFeatureService: ProGatedService {
    static let shared = ProFeatureService()
    
    internal let proGate = ProServiceGate.shared
    private let freeLimits = FreeTierLimits.shared
    
    private init() {}
    
    /// Check if a feature is available (Pro or within free limits)
    func isFeatureAvailable(for feature: ProFeature) -> Bool {
        if proGate.checkProStatus() {
            return true
        }
        
        switch feature {
        case .export:
            return freeLimits.canExport()
        case .createFollowUp:
            return freeLimits.canCreateFollowUp()
        case .unlimitedProjects:
            return false // Always requires Pro
        case .advancedAnalytics:
            return false // Always requires Pro
        case .prioritySupport:
            return false // Always requires Pro
        }
    }
    
    /// Execute a feature with proper gating
    func executeFeature<T>(_ feature: ProFeature, _ closure: () throws -> T) throws -> T {
        guard isFeatureAvailable(for: feature) else {
            throw ProError.subscriptionRequired
        }
        
        // Record usage for free tier
        if !proGate.checkProStatus() {
            switch feature {
            case .export:
                freeLimits.recordExport()
            case .createFollowUp:
                freeLimits.recordFollowUp()
            default:
                break
            }
        }
        
        return try closure()
    }
    
    /// Get usage information for free tier users
    func getUsageInfo() -> UsageInfo? {
        guard !proGate.checkProStatus() else { return nil }
        
        return UsageInfo(
            monthlyExports: freeLimits.monthlyExports,
            maxMonthlyExports: freeLimits.remainingExports + freeLimits.monthlyExports,
            remainingExports: freeLimits.remainingExports,
            monthlyFollowUps: freeLimits.monthlyFollowUps,
            maxMonthlyFollowUps: freeLimits.remainingFollowUps + freeLimits.monthlyFollowUps,
            remainingFollowUps: freeLimits.remainingFollowUps
        )
    }
}

/// Pro features that can be gated
enum ProFeature {
    case export
    case createFollowUp
    case unlimitedProjects
    case advancedAnalytics
    case prioritySupport
}

/// Usage information for free tier users
struct UsageInfo {
    let monthlyExports: Int
    let maxMonthlyExports: Int
    let remainingExports: Int
    let monthlyFollowUps: Int
    let maxMonthlyFollowUps: Int
    let remainingFollowUps: Int
}
