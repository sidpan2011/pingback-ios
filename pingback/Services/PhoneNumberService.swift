import Foundation
import Contacts
import CoreLocation

/// Service for handling phone number normalization to E.164 format with region-aware formatting
@MainActor
class PhoneNumberService: ObservableObject {
    static let shared = PhoneNumberService()
    
    private init() {}
    
    // MARK: - E.164 Normalization
    
    /// Normalize phone number to E.164 format using region-aware logic
    /// - Parameters:
    ///   - phoneNumber: Raw phone number string
    ///   - contact: Optional CNContact for additional context
    ///   - userRegion: Optional user-specified default region
    /// - Returns: E.164 formatted phone number or nil if invalid
    func normalizeToE164(
        _ phoneNumber: String,
        contact: CNContact? = nil,
        userRegion: String? = nil
    ) -> String? {
        
        let digitsOnly = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Already has country code (starts with +)
        if phoneNumber.hasPrefix("+") && digitsOnly.count >= 10 {
            return "+\(digitsOnly)"
        }
        
        // Determine the appropriate region for formatting
        let region = determineRegion(for: phoneNumber, contact: contact, userRegion: userRegion)
        let countryCode = getCountryCode(for: region)
        
        // Apply region-specific formatting rules
        let formatted = formatWithCountryCode(digitsOnly, countryCode: countryCode, region: region)
        
        print("📞 PhoneNumberService: Normalized '\(phoneNumber)' -> '\(formatted ?? "nil")' (region: \(region))")
        return formatted
    }
    
    /// Store E.164 phone number for a person with WhatsApp verification
    /// - Parameters:
    ///   - person: Person to update
    ///   - phoneNumber: Raw phone number
    ///   - contact: Optional contact for context
    /// - Returns: Updated person with normalized phone number
    func storeWhatsAppNumber(
        for person: Person,
        phoneNumber: String,
        contact: CNContact? = nil
    ) -> Person {
        
        guard let e164Number = normalizeToE164(phoneNumber, contact: contact) else {
            print("❌ PhoneNumberService: Failed to normalize phone number for \(person.displayName)")
            return person
        }
        
        var updatedPerson = person
        
        // Store the E.164 number, avoiding duplicates
        if !updatedPerson.phoneNumbers.contains(e164Number) {
            updatedPerson.phoneNumbers.append(e164Number)
        }
        
        // Store in persistent storage (App Group for share extension access)
        storePersonPhoneMapping(person: updatedPerson)
        
        print("✅ PhoneNumberService: Stored WhatsApp number for \(person.displayName): \(e164Number)")
        return updatedPerson
    }
    
    // MARK: - Region Detection
    
    private func determineRegion(
        for phoneNumber: String,
        contact: CNContact?,
        userRegion: String?
    ) -> String {
        
        // 1. Check if phone number already has country code
        if phoneNumber.hasPrefix("+") {
            if let countryCode = extractCountryCodeFromE164(phoneNumber),
               let region = getRegion(for: countryCode) {
                return region
            }
        }
        
        // 2. Use contact's postal address country
        if let contact = contact {
            if let region = getRegionFromContact(contact) {
                return region
            }
        }
        
        // 3. Use device region (current locale)
        if let deviceRegion = getDeviceRegion() {
            return deviceRegion
        }
        
        // 4. Use user-specified default region from settings
        if let userRegion = userRegion {
            return userRegion
        }
        
        // 5. Final fallback - don't assume US, use device locale or international
        return Locale.current.region?.identifier ?? "US"
    }
    
    private func extractCountryCodeFromE164(_ phoneNumber: String) -> String? {
        let digitsOnly = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Common country codes (ordered by length, longest first to avoid conflicts)
        let countryCodes = [
            "1": ["US", "CA"], // US/Canada
            "44": ["GB"], // UK
            "91": ["IN"], // India
            "49": ["DE"], // Germany
            "33": ["FR"], // France
            "81": ["JP"], // Japan
            "86": ["CN"], // China
            "61": ["AU"], // Australia
            "55": ["BR"], // Brazil
            "7": ["RU"], // Russia
        ]
        
        // Try to match country codes (check longer codes first)
        for (code, regions) in countryCodes.sorted(by: { $0.key.count > $1.key.count }) {
            if digitsOnly.hasPrefix(code) {
                return regions.first
            }
        }
        
        return nil
    }
    
    private func getRegionFromContact(_ contact: CNContact) -> String? {
        // Check postal addresses for country
        for address in contact.postalAddresses {
            let country = address.value.country
            if !country.isEmpty {
                // Convert country name to region code
                return convertCountryNameToRegionCode(country)
            }
            let isoCode = address.value.isoCountryCode
            if !isoCode.isEmpty {
                return isoCode.uppercased()
            }
        }
        return nil
    }
    
    private func getDeviceRegion() -> String? {
        return Locale.current.region?.identifier
    }
    
    private func convertCountryNameToRegionCode(_ countryName: String) -> String? {
        let locale = Locale(identifier: "en_US")
        for regionCode in Locale.Region.isoRegions {
            if let localizedName = locale.localizedString(forRegionCode: regionCode.identifier),
               localizedName.lowercased() == countryName.lowercased() {
                return regionCode.identifier
            }
        }
        return nil
    }
    
    // MARK: - Country Code Mapping
    
    private func getCountryCode(for region: String) -> String {
        switch region.uppercased() {
        case "US", "CA": return "1"
        case "GB": return "44"
        case "IN": return "91"
        case "DE": return "49"
        case "FR": return "33"
        case "JP": return "81"
        case "CN": return "86"
        case "AU": return "61"
        case "BR": return "55"
        case "RU": return "7"
        case "IT": return "39"
        case "ES": return "34"
        case "NL": return "31"
        case "BE": return "32"
        case "CH": return "41"
        case "AT": return "43"
        case "SE": return "46"
        case "NO": return "47"
        case "DK": return "45"
        case "FI": return "358"
        case "PL": return "48"
        case "CZ": return "420"
        case "SK": return "421"
        case "HU": return "36"
        case "GR": return "30"
        case "PT": return "351"
        case "IE": return "353"
        case "IS": return "354"
        case "LU": return "352"
        case "MT": return "356"
        case "CY": return "357"
        case "MX": return "52"
        case "AR": return "54"
        case "CL": return "56"
        case "CO": return "57"
        case "PE": return "51"
        case "VE": return "58"
        case "EC": return "593"
        case "BO": return "591"
        case "PY": return "595"
        case "UY": return "598"
        case "GY": return "592"
        case "SR": return "597"
        case "FK": return "500"
        case "KR": return "82"
        case "TH": return "66"
        case "VN": return "84"
        case "MY": return "60"
        case "SG": return "65"
        case "ID": return "62"
        case "PH": return "63"
        case "TW": return "886"
        case "HK": return "852"
        case "MO": return "853"
        case "NZ": return "64"
        case "FJ": return "679"
        case "ZA": return "27"
        case "EG": return "20"
        case "MA": return "212"
        case "DZ": return "213"
        case "TN": return "216"
        case "LY": return "218"
        case "GM": return "220"
        case "SN": return "221"
        case "MR": return "222"
        case "ML": return "223"
        case "GN": return "224"
        case "CI": return "225"
        case "BF": return "226"
        case "NE": return "227"
        case "TG": return "228"
        case "BJ": return "229"
        case "MU": return "230"
        case "LR": return "231"
        case "SL": return "232"
        case "GH": return "233"
        case "NG": return "234"
        case "TD": return "235"
        case "CF": return "236"
        case "CM": return "237"
        case "CV": return "238"
        case "ST": return "239"
        case "GQ": return "240"
        case "GA": return "241"
        case "CG": return "242"
        case "CD": return "243"
        case "AO": return "244"
        case "GW": return "245"
        case "IO": return "246"
        case "AC": return "247"
        case "SC": return "248"
        case "SD": return "249"
        case "RW": return "250"
        case "ET": return "251"
        case "SO": return "252"
        case "DJ": return "253"
        case "KE": return "254"
        case "TZ": return "255"
        case "UG": return "256"
        case "BI": return "257"
        case "MZ": return "258"
        case "ZM": return "260"
        case "MG": return "261"
        case "RE", "YT": return "262"
        case "ZW": return "263"
        case "NA": return "264"
        case "MW": return "265"
        case "LS": return "266"
        case "BW": return "267"
        case "SZ": return "268"
        case "KM": return "269"
        default: return "1" // Default fallback
        }
    }
    
    private func getRegion(for countryCode: String) -> String? {
        switch countryCode {
        case "1": return "US" // Could be CA, but default to US
        case "44": return "GB"
        case "91": return "IN"
        case "49": return "DE"
        case "33": return "FR"
        case "81": return "JP"
        case "86": return "CN"
        case "61": return "AU"
        case "55": return "BR"
        case "7": return "RU"
        default: return nil
        }
    }
    
    // MARK: - Formatting
    
    private func formatWithCountryCode(
        _ digitsOnly: String,
        countryCode: String,
        region: String
    ) -> String? {
        
        // Validate digit count for region
        let expectedLength = getExpectedLength(for: region, countryCode: countryCode)
        
        if digitsOnly.count == expectedLength {
            return "+\(countryCode)\(digitsOnly)"
        } else if digitsOnly.count == expectedLength + countryCode.count {
            // Already includes country code digits
            return "+\(digitsOnly)"
        }
        
        return nil
    }
    
    private func getExpectedLength(for region: String, countryCode: String) -> Int {
        switch region.uppercased() {
        case "US", "CA": return 10 // 10 digits after +1
        case "GB": return 10 // 10 digits after +44
        case "IN": return 10 // 10 digits after +91
        case "DE": return 11 // 11 digits after +49
        case "FR": return 9 // 9 digits after +33
        case "JP": return 10 // 10 digits after +81
        case "CN": return 11 // 11 digits after +86
        case "AU": return 9 // 9 digits after +61
        case "BR": return 11 // 11 digits after +55
        default: return 10 // Default assumption
        }
    }
    
    // MARK: - Persistence
    
    private func storePersonPhoneMapping(person: Person) {
        guard let appGroupDefaults = UserDefaults(suiteName: "group.app.pingback.shared") else {
            print("❌ PhoneNumberService: Could not access app group UserDefaults")
            return
        }
        
        // Store person-to-phone mapping for share extension access
        let key = "person_phone_\(person.id.uuidString)"
        if let encoded = try? JSONEncoder().encode(person) {
            appGroupDefaults.set(encoded, forKey: key)
            appGroupDefaults.synchronize()
        }
    }
    
    /// Retrieve stored person with phone numbers
    func getStoredPerson(id: UUID) -> Person? {
        guard let appGroupDefaults = UserDefaults(suiteName: "group.app.pingback.shared") else {
            return nil
        }
        
        let key = "person_phone_\(id.uuidString)"
        guard let data = appGroupDefaults.data(forKey: key),
              let person = try? JSONDecoder().decode(Person.self, from: data) else {
            return nil
        }
        
        return person
    }
    
    // MARK: - Validation
    
    /// Validate that a phone number is suitable for WhatsApp
    func validateForWhatsApp(_ phoneNumber: String) -> Bool {
        guard let e164 = normalizeToE164(phoneNumber) else { return false }
        
        // WhatsApp requires E.164 format with country code
        let digitsOnly = e164.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return digitsOnly.count >= 10 && e164.hasPrefix("+")
    }
    
    /// Get user-friendly display format for phone number
    func displayFormat(_ e164Number: String) -> String {
        // Simple display formatting - could be enhanced with region-specific formatting
        let digitsOnly = e164Number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if digitsOnly.hasPrefix("1") && digitsOnly.count == 11 {
            // US/Canada format: +1 (555) 123-4567
            let area = String(digitsOnly.dropFirst().prefix(3))
            let exchange = String(digitsOnly.dropFirst(4).prefix(3))
            let number = String(digitsOnly.dropFirst(7))
            return "+1 (\(area)) \(exchange)-\(number)"
        } else if digitsOnly.hasPrefix("44") && digitsOnly.count >= 12 {
            // UK format: +44 20 1234 5678
            let rest = String(digitsOnly.dropFirst(2))
            return "+44 \(rest)"
        } else if digitsOnly.hasPrefix("91") && digitsOnly.count >= 12 {
            // India format: +91 98765 43210
            let rest = String(digitsOnly.dropFirst(2))
            return "+91 \(rest)"
        }
        
        // Default format: +XX XXXXXXXXXX
        return e164Number
    }
}

// MARK: - Extensions

extension PhoneNumberService {
    /// Migrate existing phone numbers to proper E.164 format
    func migrateExistingNumbers() {
        // This would be called during app updates to fix existing data
        print("📞 PhoneNumberService: Starting phone number migration...")
        
        // Implementation would iterate through existing persons and re-normalize their numbers
        // This is a placeholder for the migration logic
    }
}
